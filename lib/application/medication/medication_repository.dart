import 'dart:math';
import 'dart:convert';
import '../../data/network/api_client.dart';
import '../../data/network/api_exception.dart';
import '../../data/mappers/medication_form_mapper.dart';
import '../../domain/models/auth_json.dart';
import '../../domain/models/medication.dart';

/// Kept by one form: unchanged retries reuse the key; changed intentions get a new one.
final class MedicationMutationIntent {
  String? _fingerprint, _key;
  String keyFor(Map<String, dynamic> body) {
    final fingerprint = jsonEncode(body);
    if (_fingerprint != fingerprint) {
      _fingerprint = fingerprint;
      _key = MedicationRepository.newKey();
    }
    return _key!;
  }
}

final class MedicationRepository {
  MedicationRepository(
    this.api, {
    required String patientId,
    required this.expectedToken,
  }) : root = '/api/v1/patients/$patientId' {
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(patientId) ||
        expectedToken.isEmpty) {
      throw ArgumentError('An authenticated target patient is required.');
    }
  }
  final ApiClient api;
  final String root, expectedToken;
  DateTime? serverNow;
  static String newKey() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<T> _parse<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FormatException {
      throw ApiException(code: 'invalid-response');
    } on TypeError {
      throw ApiException(code: 'invalid-response');
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? json, String code) {
    if (json?['code'] != code) {
      throw const FormatException('Invalid medication response.');
    }
    final data = medicationMap(json?['data']);
    if (data['contract_version'] != 1) {
      throw const FormatException('Unsupported medication contract.');
    }
    serverNow = authTimestamp(data['server_now']);
    return data;
  }

  Future<Map<String, dynamic>> _get(
    String suffix,
    String op, {
    Map<String, String>? query,
  }) async => _data(
    await api.get(
      '$root/$suffix',
      authenticated: true,
      expectedToken: expectedToken,
      query: query,
    ),
    'medication-$op-completed',
  );
  Future<Map<String, dynamic>> _write(
    String method,
    String suffix,
    String op,
    Map<String, dynamic> body, {
    String? key,
    String? code,
  }) async {
    final json = method == 'PATCH'
        ? await api.patch(
            '$root/$suffix',
            body: body,
            authenticated: true,
            expectedToken: expectedToken,
            idempotencyKey: key ?? newKey(),
          )
        : await api.post(
            '$root/$suffix',
            body: body,
            authenticated: true,
            expectedToken: expectedToken,
            idempotencyKey: key ?? newKey(),
          );
    return _data(json, code ?? 'medication-$op-completed');
  }

  Future<MedicationSettings> settings() => _parse(
    () async => MedicationSettings.fromJson(
      medicationMap(
        (await _get('medication-settings', 'settings'))['settings'],
      ),
    ),
  );
  Future<MedicationSettings> confirmTimezone(String timezone, int version) =>
      _parse(
        () async => MedicationSettings.fromJson(
          medicationMap(
            (await _write('PATCH', 'medication-settings', 'settings-update', {
              'timezone': timezone,
              'expected_version': version,
            }))['settings'],
          ),
        ),
      );
  Future<({List<MedicationRecord> items, int lastPage})> list({int page = 1}) =>
      _parse(() async {
        final data = await _get(
          'medications',
          'index',
          query: {'page': '$page', 'per_page': '100', 'status': 'active'},
        );
        return (
          items: List<MedicationRecord>.unmodifiable(
            (data['medications'] as List).map(
              (v) => MedicationRecord.fromJson(medicationMap(v)),
            ),
          ),
          lastPage: medicationInt(
            medicationMap(data['pagination'])['last_page'],
            minimum: 1,
          ),
        );
      });
  Future<MedicationDashboard> dashboard(
    String date,
    String timezone, {
    int page = 1,
    int missedPage = 1,
  }) => _parse(
    () async => MedicationDashboard.fromJson(
      _data(
        await api.get(
          '$root/medication-dashboard',
          authenticated: true,
          expectedToken: expectedToken,
          query: {
            'date': date,
            'timezone': timezone,
            'page': '$page',
            'missed_page': '$missedPage',
            'per_page': '100',
          },
        ),
        'medication-dashboard-retrieved',
      ),
    ),
  );
  Future<MedicationRecord> medication(String id) => _parse(
    () async => MedicationRecord.fromJson(
      medicationMap(
        (await _get('medications/${medicationUuid(id)}', 'show'))['medication'],
      ),
    ),
  );
  Future<Map<String, dynamic>> dose(String id) =>
      _parse(() => _get('medication-doses/${medicationUuid(id)}', 'dose'));
  Future<Map<String, dynamic>> doses(
    String from,
    String to,
    String timezone, {
    String? medicationId,
    int page = 1,
  }) => _parse(
    () => _get(
      medicationId == null
          ? 'medication-doses'
          : 'medications/${medicationUuid(medicationId)}/adherence',
      medicationId == null ? 'doses' : 'adherence',
      query: {
        'from': from,
        'to': to,
        'timezone': timezone,
        'page': '$page',
        'per_page': '100',
      },
    ),
  );
  Future<MedicationRecord> create(
    MedicationDraft draft, {
    required bool patientConsent,
    String? key,
  }) => _parse(() async {
    final body = draft.toBody();
    body['reminder_preferences'] = {
      'enable_medication_reminders': draft.reminders,
      if (patientConsent) ...{
        'notify_caregiver_if_missed': draft.consent,
        'escalation_delay_minutes': draft.delay,
      },
    };
    return MedicationRecord.fromJson(
      medicationMap(
        (await _write(
          'POST',
          'medications',
          'store',
          body,
          key: key,
          code: 'medication-created',
        ))['medication'],
      ),
    );
  });
  Future<MedicationRecord> update(
    MedicationRecord med,
    MedicationDraft draft,
  ) => _parse(
    () async => MedicationRecord.fromJson(
      medicationMap(
        (await _write('PATCH', 'medications/${med.id}', 'update', {
          'expected_version': med.version,
          ...draft.toBody(),
        }))['medication'],
      ),
    ),
  );
  Future<void> archive(MedicationRecord med) => _parse(() async {
    await _write('POST', 'medications/${med.id}/archive', 'archive', {
      'expected_version': med.version,
    });
  });
  Future<MedicationPreferences> reminders(
    String id,
    MedicationPreferences preferences,
    bool enabled,
  ) => _parse(
    () async => MedicationPreferences.fromJson(
      medicationMap(
        (await _write(
          'PATCH',
          'medications/${medicationUuid(id)}/reminder-preferences',
          'reminders',
          {
            'expected_version': preferences.version,
            'enable_medication_reminders': enabled,
          },
        ))['reminder_preferences'],
      ),
    ),
  );
  Future<MedicationPreferences> consent(
    String id,
    MedicationPreferences preferences,
    bool enabled,
    int delay,
  ) => _parse(
    () async => MedicationPreferences.fromJson(
      medicationMap(
        (await _write(
          'PATCH',
          'medications/${medicationUuid(id)}/escalation-consent',
          'consent',
          {
            'expected_version': preferences.version,
            'notify_caregiver_if_missed': enabled,
            'escalation_delay_minutes': delay,
          },
        ))['reminder_preferences'],
      ),
    ),
  );
  Future<void> record(
    MedicationDose dose,
    String action, {
    DateTime? actual,
    String? reason,
    String? target,
  }) => _parse(() async {
    if (!['taken', 'skipped', 'late-intake', 'corrections'].contains(action)) {
      throw ArgumentError('Unsupported dose action.');
    }
    await _write('POST', 'medication-doses/${dose.id}/$action', action, {
      'expected_version': dose.version,
      if (actual != null)
        'actual_intake_at': actual.toUtc().toIso8601String().replaceFirst(
          RegExp(r'\.\d+Z$'),
          '+00:00',
        ),
      'reason': ?reason,
      'target_status': ?target,
    });
  });
}
