import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/medication/medications_controller.dart';
import 'package:sanad/application/medication/medication_repository.dart';
import 'package:sanad/data/mappers/medication_form_mapper.dart';
import 'package:sanad/domain/models/medication.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:http/http.dart' as http;
import '../support/laravel_auth_fixture.dart';
import 'medication_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LaravelAuthFixture f;
  late MedicationsController controller;
  Future<void> setup({String role = 'patient', String? selected}) async {
    f = LaravelAuthFixture()..role = role;
    await f.tokens.save(
      SanctumToken(
        value: 'med-session',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    controller = MedicationsController(
      f.auth,
      selectedPatientId: selected,
      deviceTimezone: () async => 'Asia/Tokyo',
      now: () => DateTime.utc(2026, 11, 10, 23, 10),
    );
    f.override = (r) async {
      if (r.url.path == '/api/user') {
        return f.response('user-retrieved', {'user': f.user});
      }
      if (r.url.path.endsWith('/medication-settings')) {
        return f.response(
          'medication-settings-completed',
          contractData({
            'settings': {
              'confirmed_timezone': 'Asia/Tokyo',
              'version': 2,
              'requires_confirmation': false,
            },
          }),
        );
      }
      if (r.url.path.endsWith('/medication-dashboard')) {
        return f.response(
          'medication-dashboard-retrieved',
          contractData(dashboardJson()),
        );
      }
      if (r.url.path.endsWith('/medications')) {
        return f.response(
          'medication-index-completed',
          contractData({
            'medications': [medicationJson()],
            'pagination': paginationJson(),
          }),
        );
      }
      if (r.method == 'GET' && r.url.path.contains('/medication-doses/')) {
        return f.response(
          'medication-dose-completed',
          contractData({'dose': doseJson(), 'events': []}),
        );
      }
      if (r.method == 'GET' && r.url.path.contains('/medications/')) {
        return f.response(
          'medication-show-completed',
          contractData({'medication': medicationJson()}),
        );
      }
      return f.response(
        'medication-taken-completed',
        contractData({'dose': doseJson(status: 'taken')}),
      );
    };
    addTearDown(() {
      controller.dispose();
      f.close();
    });
    await controller.initialize();
  }

  test(
    'actual patient server ID, confirmed settings and server summary are loaded',
    () async {
      await setup();
      expect(controller.patientId, '7');
      expect(controller.dashboard!.summary.scheduled, 3);
      expect(controller.dashboard!.summary.remaining, 1);
      expect(controller.medications.single.version, 9);
      expect(
        f.requests.any(
          (r) => r.url.path == '/api/v1/patients/7/medication-dashboard',
        ),
        isTrue,
      );
      expect(f.requests.last.url.queryParameters['date'], '2026-11-11');
    },
  );
  test(
    'caregiver never uses own ID when selected patient is missing',
    () async {
      await setup(role: 'caregiver');
      expect(controller.errorCode, 'patient-selection-required');
      expect(
        f.requests.where((r) => r.url.path.contains('/patients/')),
        isEmpty,
      );
      expect(controller.dashboard, isNull);
    },
  );
  test(
    'caregiver uses explicit selected ID but cannot record intake or consent',
    () async {
      await setup(role: 'caregiver', selected: '42');
      expect(controller.patientId, '42');
      final count = f.requests.length;
      expect(
        await controller.recordDose(controller.dashboard!.nextDose!, 'taken'),
        isFalse,
      );
      expect(f.requests.length, count);
    },
  );
  test(
    'repeated taps submit once and only refresh after server confirms',
    () async {
      await setup();
      final gate = Completer<void>();
      final original = f.override!;
      var writes = 0;
      f.override = (r) async {
        if (r.method == 'POST') {
          writes++;
          await gate.future;
          expect(jsonDecode(r.body)['expected_version'], 6);
          return f.response(
            'medication-taken-completed',
            contractData({'dose': doseJson(status: 'taken')}),
          );
        }
        return original(r);
      };
      final dose = controller.dashboard!.nextDose!;
      final first = controller.recordDose(dose, 'taken');
      expect(await controller.recordDose(dose, 'taken'), isFalse);
      expect(controller.dashboard!.summary.taken, 1);
      gate.complete();
      expect(await first, isTrue);
      expect(writes, 1);
    },
  );
  test(
    '409 refreshes authoritative state and reports conflict without overwriting',
    () async {
      await setup();
      final original = f.override!;
      f.override = (r) async => r.method == 'POST'
          ? f.response('version-conflict', {}, 409)
          : original(r);
      expect(
        await controller.recordDose(controller.dashboard!.nextDose!, 'taken'),
        isFalse,
      );
      expect(controller.errorCode, 'version-conflict');
      expect(controller.dashboard!.summary.taken, 1);
      expect(controller.needsReconciliation, isFalse);
    },
  );
  test(
    'revocation/permission failure clears private medication data',
    () async {
      await setup(role: 'caregiver', selected: '42');
      f.override = (r) async => f.response('patient-not-found', {}, 404);
      await controller.refresh();
      expect(controller.dashboard, isNull);
      expect(controller.medications, isEmpty);
    },
  );
  test(
    'repository fresh UUID intentions, exact retries, explicit caregiver-safe fields',
    () async {
      await setup();
      final repo = MedicationRepository(
        f.api,
        patientId: '7',
        expectedToken: 'med-session',
      );
      final keys = <String>[];
      f.override = (r) async {
        keys.add(r.headers['Idempotency-Key']!);
        expect(jsonDecode(r.body)['reminder_preferences'], {
          'enable_medication_reminders': true,
        });
        return f.response(
          'medication-created',
          contractData({'medication': medicationJson()}),
          201,
        );
      };
      final draft = MedicationDraft.fromRecord(
        MedicationRecord.fromJson(medicationJson()),
      );
      await repo.create(draft, patientConsent: false);
      await repo.create(draft, patientConsent: false);
      expect(keys[0], isNot(keys[1]));
      const same = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
      await repo.create(draft, patientConsent: false, key: same);
      await repo.create(draft, patientConsent: false, key: same);
      expect(keys.sublist(2), [same, same]);
    },
  );
  test(
    'session replacement during read discards previous user response',
    () async {
      await setup();
      final original = f.override!;
      f.override = (r) async {
        final response = await original(r);
        await f.tokens.save(
          SanctumToken(
            value: 'replacement',
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        );
        return response;
      };
      await controller.refresh();
      expect(controller.dashboard, isNull);
      expect(controller.errorCode, 'session-changed');
    },
  );
  test(
    'medication detail read cannot reopen previous-session private data',
    () async {
      await setup();
      final original = f.override!;
      f.override = (r) async {
        final result = await original(r);
        await f.tokens.save(
          SanctumToken(
            value: 'replacement',
            expiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        );
        return result;
      };
      expect(await controller.readMedication(medicationId), isNull);
      expect(controller.dashboard, isNull);
    },
  );
  test(
    'today query follows server clock rather than a wrong phone calendar',
    () async {
      await setup();
      final c = MedicationsController(
        f.auth,
        deviceTimezone: () async => 'Asia/Tokyo',
        now: () => DateTime.utc(2035, 1, 1),
      );
      addTearDown(c.dispose);
      await c.initialize();
      expect(f.requests.last.url.queryParameters['date'], '2026-11-11');
    },
  );
  test(
    'late previous-session failure cannot clear a newly loaded account',
    () async {
      await setup();
      final entered = Completer<void>();
      final oldResponse = Completer<http.Response>();
      final original = f.override!;
      var newSession = false;
      var first = true;
      f.override = (r) async {
        if (r.url.path == '/api/user' && newSession) {
          return f.response('user-retrieved', {
            'user': {...f.user, 'id': '42'},
          });
        }
        if (r.url.path.endsWith('/medication-settings') && first) {
          first = false;
          entered.complete();
          return oldResponse.future;
        }
        return original(r);
      };
      final oldRefresh = controller.refresh();
      await entered.future;
      newSession = true;
      await f.tokens.save(
        SanctumToken(
          value: 'new-session',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      await f.auth.restoreCurrentUser();
      await controller.initialize();
      expect(controller.patientId, '42');
      expect(controller.dashboard, isNotNull);
      oldResponse.completeError(ApiException(code: 'network-request-failed'));
      await oldRefresh;
      expect(controller.patientId, '42');
      expect(controller.dashboard, isNotNull);
      expect(controller.errorCode, isNull);
    },
  );
}
