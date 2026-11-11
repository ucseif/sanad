import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/medication/medications_controller.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/presentation/widgets/home_widgets/medications_content.dart';
import '../support/laravel_auth_fixture.dart';
import 'medication_fixtures.dart';

void main() {
  Future<(LaravelAuthFixture, MedicationsController)> setup(
    WidgetTester tester, {
    String role = 'patient',
    String language = 'en',
    String? selected,
    bool confirmation = false,
  }) async {
    final f = LaravelAuthFixture()..role = role;
    await f.tokens.save(
      SanctumToken(
        value: 'med-session',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    var confirmed = !confirmation;
    f.override = (r) async {
      if (r.url.path == '/api/user') {
        return f.response('user-retrieved', {'user': f.user});
      }
      if (r.url.path.endsWith('/medication-settings')) {
        if (r.method == 'PATCH') confirmed = true;
        return f.response(
          r.method == 'PATCH'
              ? 'medication-settings-update-completed'
              : 'medication-settings-completed',
          contractData({
            'settings': {
              'confirmed_timezone': confirmed ? 'Asia/Tokyo' : null,
              'version': confirmed ? 2 : 0,
              'requires_confirmation': !confirmed,
            },
          }),
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
      if (r.url.path.endsWith('/medication-dashboard')) {
        return f.response(
          'medication-dashboard-retrieved',
          contractData(dashboardJson()),
        );
      }
      return f.response(
        'medication-dose-completed',
        contractData({'dose': doseJson(), 'events': []}),
      );
    };
    final c = MedicationsController(
      f.auth,
      selectedPatientId: selected,
      deviceTimezone: () async => 'Asia/Tokyo',
      now: () => DateTime.utc(2026, 11, 10, 23, 10),
    );
    await c.initialize();
    addTearDown(() {
      c.dispose();
      f.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: MedicationsContent(userId: '7', controller: c),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (f, c);
  }

  testWidgets('existing cards display server counts and original local time', (
    tester,
  ) async {
    await setup(tester);
    expect(find.text('Example medicine'), findsNWidgets(2));
    expect(find.text('08:00'), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('Old cached medicine'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('caregiver dose button disabled; consent switch not editable', (
    tester,
  ) async {
    final (_, c) = await setup(tester, role: 'caregiver', selected: '42');
    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.check_rounded),
    );
    expect(button.onPressed, isNull);
    expect(c.patientId, '42');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final consent = find.byWidgetPredicate(
      (w) =>
          w is SwitchListTile &&
          w.title is Text &&
          (w.title as Text).data == 'Notify caregiver if missed',
    );
    await tester.ensureVisible(consent);
    expect(tester.widget<SwitchListTile>(consent).onChanged, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('timezone bootstrap requires explicit confirmation before form', (
    tester,
  ) async {
    final (f, _) = await setup(tester, confirmation: true);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm medication timezone'), findsOneWidget);
    expect(f.requests.where((r) => r.method == 'PATCH'), isEmpty);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(f.requests.where((r) => r.method == 'PATCH').length, 1);
    expect(find.text('Add a medicine'), findsOneWidget);
  });
  testWidgets('Arabic remains RTL with existing medication layout', (
    tester,
  ) async {
    await setup(tester, language: 'ar');
    expect(find.text('الأدوية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الأدوية'))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'existing form saves actual wire fields and closes only after create confirms',
    (tester) async {
      final (f, _) = await setup(tester);
      final original = f.override!;
      final completed = Completer<void>();
      var writes = 0;
      f.override = (r) async {
        if (r.method == 'POST') {
          writes++;
          final body = jsonDecode(r.body) as Map;
          expect(body['prescription']['name'], 'New example');
          expect(body['prescription']['dose_amount'], '3');
          expect(body['schedule']['frequency'], 'once_daily');
          expect(body['schedule']['timezone'], 'Asia/Tokyo');
          expect(r.headers['Idempotency-Key'], isNotEmpty);
          await completed.future;
          return f.response(
            'medication-created',
            contractData({'medication': medicationJson()}),
            201,
          );
        }
        return original(r);
      };
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'New example');
      await tester.enterText(find.byType(TextField).at(1), '3');
      await tester.ensureVisible(find.text('Save medicine'));
      await tester.tap(find.text('Save medicine'));
      await tester.pump();
      expect(find.text('Add a medicine'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save medicine'),
            )
            .onPressed,
        isNull,
      );
      expect(writes, 1);
      completed.complete();
      await tester.pumpAndSettle();
      expect(find.text('Add a medicine'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'tapping medicine title fetches details and reuses prefilled form for PATCH',
    (tester) async {
      final (f, _) = await setup(tester);
      final original = f.override!;
      var patches = 0;
      f.override = (r) async {
        if (r.method == 'GET' && r.url.path.endsWith('/$medicationId')) {
          return f.response(
            'medication-show-completed',
            contractData({'medication': medicationJson()}),
          );
        }
        if (r.method == 'PATCH') {
          patches++;
          final body = jsonDecode(r.body) as Map;
          expect(body['expected_version'], 9);
          expect(body['prescription']['name'], 'Changed example');
          return f.response(
            'medication-update-completed',
            contractData({'medication': medicationJson()}),
          );
        }
        return original(r);
      };
      await tester.tap(find.text('Example medicine').last);
      await tester.pumpAndSettle();
      expect(find.text('Edit medicine'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2.5'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'Changed example');
      await tester.ensureVisible(find.text('Save medicine'));
      await tester.tap(find.text('Save medicine'));
      await tester.pumpAndSettle();
      expect(patches, 1);
      expect(find.text('Edit medicine'), findsNothing);
    },
  );
  testWidgets(
    'swipe archive waits for server then removes from refreshed list',
    (tester) async {
      final (f, _) = await setup(tester);
      final original = f.override!;
      final gate = Completer<void>();
      var archived = false;
      f.override = (r) async {
        if (r.method == 'POST' && r.url.path.endsWith('/archive')) {
          await gate.future;
          archived = true;
          return f.response(
            'medication-archive-completed',
            contractData({'medication': medicationJson()}),
          );
        }
        if (archived && r.url.path.endsWith('/medications')) {
          return f.response(
            'medication-index-completed',
            contractData({'medications': [], 'pagination': paginationJson()}),
          );
        }
        if (archived && r.url.path.endsWith('/medication-dashboard')) {
          final empty = dashboardJson(medications: []);
          empty['next_actionable_dose'] = null;
          return f.response(
            'medication-dashboard-retrieved',
            contractData(empty),
          );
        }
        return original(r);
      };
      await tester.drag(find.byType(Dismissible), const Offset(-650, 0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(archived, isFalse);
      expect(find.byType(Dismissible), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(archived, isTrue);
      expect(find.byType(Dismissible), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unchanged create retry retains its UUID after uncertain committed response',
    (tester) async {
      final (f, _) = await setup(tester);
      final original = f.override!;
      final keys = <String>[];
      f.override = (r) async {
        if (r.method == 'POST') {
          keys.add(r.headers['Idempotency-Key']!);
          if (keys.length == 1) throw ApiException(code: 'request-timeout');
          return f.response(
            'medication-created',
            contractData({'medication': medicationJson()}),
            201,
          );
        }
        return original(r);
      };
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Retry example');
      await tester.enterText(find.byType(TextField).at(1), '1');
      await tester.ensureVisible(find.text('Save medicine'));
      await tester.tap(find.text('Save medicine'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save medicine'));
      await tester.tap(find.text('Save medicine'));
      await tester.pumpAndSettle();
      expect(keys.length, 2);
      expect(keys[0], keys[1]);
    },
  );
  testWidgets(
    'conflicted edit closes for explicit review instead of retrying stale versions',
    (tester) async {
      final (f, _) = await setup(tester);
      final original = f.override!;
      f.override = (r) async {
        if (r.method == 'GET' && r.url.path.endsWith('/$medicationId')) {
          return f.response(
            'medication-show-completed',
            contractData({'medication': medicationJson()}),
          );
        }
        if (r.method == 'PATCH') return f.response('version-conflict', {}, 409);
        return original(r);
      };
      await tester.tap(find.text('Example medicine').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Concurrent edit');
      await tester.ensureVisible(find.text('Save medicine'));
      await tester.tap(find.text('Save medicine'));
      await tester.pumpAndSettle();
      expect(find.text('Edit medicine'), findsNothing);
    },
  );
  testWidgets('Arabic timezone prerequisite retains readable Arabic labels', (
    tester,
  ) async {
    await setup(tester, language: 'ar', confirmation: true);
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('تأكيد المنطقة الزمنية للأدوية'), findsOneWidget);
    expect(find.text('تأكيد'), findsOneWidget);
  });
  testWidgets(
    'daily totals remain visible with no active medicines but retained history',
    (tester) async {
      final (f, c) = await setup(tester);
      final original = f.override!;
      f.override = (r) async {
        if (r.url.path.endsWith('/medications')) {
          return f.response(
            'medication-index-completed',
            contractData({'medications': [], 'pagination': paginationJson()}),
          );
        }
        return original(r);
      };
      await c.refresh();
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('existing historical prescription start date remains editable', (
    tester,
  ) async {
    final (f, _) = await setup(tester);
    final original = f.override!;
    f.override = (r) async {
      if (r.url.path.endsWith('/$medicationId')) {
        final med = medicationJson();
        med['current_revision']['schedule']['start_date'] = '2020-01-01';
        return f.response(
          'medication-show-completed',
          contractData({'medication': med}),
        );
      }
      return original(r);
    };
    await tester.tap(find.text('Example medicine').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('01/01/2020'));
    await tester.tap(find.text('01/01/2020'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
