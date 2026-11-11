import 'auth_json.dart';

Map<String, dynamic> medicationMap(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid medication data.');
  }
  return value;
}

int medicationInt(Object? value, {int minimum = 0}) {
  if (value is! int || value < minimum) {
    throw const FormatException('Invalid medication count/version.');
  }
  return value;
}

List<String> medicationStrings(Object? value) {
  if (value is! List || value.any((v) => v is! String)) {
    throw const FormatException('Invalid medication values.');
  }
  return List<String>.unmodifiable(value);
}

String medicationUuid(Object? value) {
  final text = authString(value);
  if (!RegExp(
    r'^[a-fA-F0-9]{8}-(?:[a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}$',
  ).hasMatch(text)) {
    throw const FormatException('Invalid medication identity.');
  }
  return text;
}

final class MedicationPreferences {
  MedicationPreferences.fromJson(Map<String, dynamic> json)
    : version = medicationInt(json['version'], minimum: 1),
      reminders = json['enable_medication_reminders'] as bool,
      caregiverConsent = json['notify_caregiver_if_missed'] as bool,
      delay = medicationInt(json['escalation_delay_minutes'], minimum: 1);
  final int version, delay;
  final bool reminders, caregiverConsent;
}

final class MedicationRevision {
  MedicationRevision.fromJson(Map<String, dynamic> json)
    : id = medicationUuid(json['id']),
      prescription = Map.unmodifiable(medicationMap(json['prescription'])),
      schedule = Map.unmodifiable(medicationMap(json['schedule'])),
      effectiveFrom = authTimestamp(json['effective_from']) {
    final p = prescription, s = schedule;
    final amount = p['dose_amount'];
    final times = s['times'], days = s['weekdays'];
    bool clock(Object? value) =>
        value is String &&
        RegExp(r'^(?:[01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
    if (p['name'] is! String ||
        (p['name'] as String).trim().isEmpty ||
        amount is! String ||
        !RegExp(r'^\d+(?:\.\d{1,6})?$').hasMatch(amount) ||
        (num.tryParse(amount) ?? 0) <= 0 ||
        ![
          'mg',
          'g',
          'ml',
          'mcg',
          'IU',
          'tablet',
          'capsule',
          'drop',
          'puff',
        ].contains(p['dose_unit']) ||
        ![
          'tablet',
          'capsule',
          'syrup',
          'drops',
          'injection',
          'inhaler',
          'cream',
          'other',
        ].contains(p['form']) ||
        ![
          'before_food',
          'after_food',
          'with_food',
          'no_preference',
        ].contains(p['relation_to_meals']) ||
        p['instructions'] is! String ||
        p['special_notes'] is! String ||
        ![
          'once_daily',
          'twice_daily',
          'three_times_daily',
          'specific_days',
          'every_hours',
          'as_needed',
        ].contains(s['frequency']) ||
        s['timezone'] is! String ||
        s['start_date'] is! String ||
        times is! List ||
        times.any((v) => !clock(v)) ||
        times.toSet().length != times.length ||
        days is! List ||
        days.any((v) => v is! int || v < 1 || v > 7) ||
        days.toSet().length != days.length ||
        (s['frequency'] == 'every_hours' &&
            (!clock(s['anchor_time']) || s['interval_hours'] is! int))) {
      throw const FormatException(
        'Invalid medication prescription or schedule.',
      );
    }
  }
  final String id;
  final Map<String, dynamic> prescription, schedule;
  final DateTime effectiveFrom;
}

final class MedicationDose {
  MedicationDose.fromJson(Map<String, dynamic> json)
    : id = medicationUuid(json['id']),
      medicationId = medicationUuid(json['medication_id']),
      version = medicationInt(json['version'], minimum: 1),
      name = authString(json['medicine_name']),
      kind = authString(json['kind']),
      status = authString(json['status']),
      timezone = authString(json['timezone']),
      localDate = authString(json['local_date']),
      localTime = json['local_time'] as String?,
      scheduledAt = json['scheduled_at'] == null
          ? null
          : authTimestamp(json['scheduled_at']),
      actualIntakeAt = json['actual_intake_at'] == null
          ? null
          : authTimestamp(json['actual_intake_at']),
      missedAt = json['missed_at'] == null
          ? null
          : authTimestamp(json['missed_at']),
      actions = medicationStrings(json['allowed_actions']),
      canReportLate = json['can_report_late_intake'] as bool {
    if (![
          'pending',
          'overdue',
          'taken',
          'skipped',
          'missed',
          'cancelled',
          'void',
        ].contains(status) ||
        !['scheduled', 'prn'].contains(kind) ||
        (kind == 'scheduled' &&
            (scheduledAt == null || localTime == null || missedAt == null))) {
      throw const FormatException('Invalid medication occurrence.');
    }
  }
  final String id, medicationId, name, kind, status, timezone, localDate;
  final String? localTime;
  final int version;
  final DateTime? scheduledAt, actualIntakeAt, missedAt;
  final List<String> actions;
  final bool canReportLate;
  bool can(String action) => actions.contains(action);
}

final class MedicationRecord {
  MedicationRecord.fromJson(Map<String, dynamic> json)
    : id = medicationUuid(json['id']),
      version = medicationInt(json['version'], minimum: 1),
      archived = json['archived_at'] != null,
      current = MedicationRevision.fromJson(
        medicationMap(json['current_revision']),
      ),
      pending = json['pending_revision'] == null
          ? null
          : MedicationRevision.fromJson(
              medicationMap(json['pending_revision']),
            ),
      preferences = MedicationPreferences.fromJson(
        medicationMap(json['reminder_preferences']),
      ),
      actions = medicationStrings(json['allowed_actions']),
      doses = List.unmodifiable(
        ((json['doses'] ?? const []) as List).map(
          (v) => MedicationDose.fromJson(medicationMap(v)),
        ),
      ),
      todayTaken = json['taken_doses'] == null
          ? null
          : medicationInt(json['taken_doses']),
      todayScheduled = json['scheduled_doses'] == null
          ? null
          : medicationInt(json['scheduled_doses']);
  final String id;
  final int version;
  final bool archived;
  final MedicationRevision current;
  final MedicationRevision? pending;
  final MedicationPreferences preferences;
  final List<String> actions;
  final List<MedicationDose> doses;
  final int? todayTaken, todayScheduled;
  bool can(String action) => actions.contains(action);
}

final class MedicationSettings {
  MedicationSettings.fromJson(Map<String, dynamic> json)
    : timezone = json['confirmed_timezone'] as String?,
      version = medicationInt(json['version']),
      requiresConfirmation = json['requires_confirmation'] as bool {
    if (requiresConfirmation != (timezone == null)) {
      throw const FormatException('Invalid timezone confirmation.');
    }
  }
  final String? timezone;
  final int version;
  final bool requiresConfirmation;
}

final class MedicationSummary {
  MedicationSummary.fromJson(Map<String, dynamic> json)
    : scheduled = medicationInt(json['scheduled_doses']),
      taken = medicationInt(json['taken_doses']),
      remaining = medicationInt(json['remaining_doses']),
      missed = medicationInt(json['missed_doses']),
      skipped = medicationInt(json['skipped_doses']),
      progress = (json['progress_fraction'] as num).toDouble() {
    if (!progress.isFinite ||
        progress < 0 ||
        progress > 1 ||
        taken > scheduled) {
      throw const FormatException('Invalid medication summary.');
    }
  }
  final int scheduled, taken, remaining, missed, skipped;
  final double progress;
}

final class MedicationDashboard {
  MedicationDashboard.fromJson(Map<String, dynamic> json)
    : date = authString(json['date']),
      timezone = authString(json['timezone']),
      summary = MedicationSummary.fromJson(medicationMap(json['summary'])),
      nextDose = json['next_actionable_dose'] == null
          ? null
          : MedicationDose.fromJson(
              medicationMap(json['next_actionable_dose']),
            ),
      medications = List.unmodifiable(
        (json['medications'] as List).map(
          (v) => MedicationRecord.fromJson(medicationMap(v)),
        ),
      ),
      missed = List.unmodifiable(
        (json['missed_doses'] as List).map(
          (v) => MedicationDose.fromJson(medicationMap(v)),
        ),
      ),
      page = medicationInt(
        medicationMap(json['medications_pagination'])['page'],
        minimum: 1,
      ),
      lastPage = medicationInt(
        medicationMap(json['medications_pagination'])['last_page'],
        minimum: 1,
      ),
      missedPage = medicationInt(
        medicationMap(json['missed_doses_pagination'])['page'],
        minimum: 1,
      ),
      missedLastPage = medicationInt(
        medicationMap(json['missed_doses_pagination'])['last_page'],
        minimum: 1,
      ) {
    if (nextDose != null &&
        !['pending', 'overdue'].contains(nextDose!.status)) {
      throw const FormatException('Invalid next dose.');
    }
    if (missed.any((dose) => dose.status != 'missed')) {
      throw const FormatException('Invalid missed collection.');
    }
  }
  final String date, timezone;
  final MedicationSummary summary;
  final MedicationDose? nextDose;
  final List<MedicationRecord> medications;
  final List<MedicationDose> missed;
  final int page, lastPage, missedPage, missedLastPage;
}
