const medicationId = '11111111-1111-4111-a111-111111111111';
const revisionId = '22222222-2222-4222-a222-222222222222';
const doseId = '33333333-3333-4333-a333-333333333333';
Map<String, dynamic> prescriptionJson() => {
  'name': 'Example medicine',
  'dose_amount': '2.5',
  'dose_unit': 'mg',
  'form': 'tablet',
  'relation_to_meals': 'after_food',
  'instructions': 'User prescription',
  'special_notes': '',
};
Map<String, dynamic> scheduleJson() => {
  'frequency': 'once_daily',
  'timezone': 'Asia/Tokyo',
  'start_date': '2026-11-11',
  'end_date': null,
  'times': ['08:00'],
  'weekdays': [],
  'interval_hours': null,
  'anchor_time': null,
};
Map<String, dynamic> revisionJson() => {
  'id': revisionId,
  'revision_number': 1,
  'prescription': prescriptionJson(),
  'schedule': scheduleJson(),
  'effective_from': '2026-11-10T00:00:00+00:00',
  'effective_to': null,
  'superseded_at': null,
  'grace_seconds': 1800,
  'grace_policy_version': 1,
};
Map<String, dynamic> preferencesJson() => {
  'version': 4,
  'enable_medication_reminders': true,
  'notify_caregiver_if_missed': false,
  'escalation_delay_minutes': 30,
};
Map<String, dynamic> doseJson({
  String status = 'overdue',
  List<String> actions = const ['view', 'taken', 'skipped'],
}) => {
  'id': doseId,
  'medication_id': medicationId,
  'revision_id': revisionId,
  'medicine_name': 'Example medicine',
  'prescription': prescriptionJson(),
  'kind': 'scheduled',
  'scheduled_at': '2026-11-10T23:00:00+00:00',
  'local_date': '2026-11-11',
  'local_time': '08:00',
  'timezone': 'Asia/Tokyo',
  'resolved_local_time': '2026-11-11T08:00:00+09:00',
  'requested_local_times': ['2026-11-11 08:00'],
  'status': status,
  'missed_at': '2026-11-10T23:30:00+00:00',
  'actual_intake_at': status == 'taken' ? '2026-11-10T23:01:00+00:00' : null,
  'version': 6,
  'can_report_late_intake': status == 'missed',
  'allowed_actions': actions,
};
Map<String, dynamic> medicationJson({
  List<String> actions = const [
    'view',
    'update',
    'archive',
    'change_reminders',
    'change_escalation_consent',
  ],
  List<Map<String, dynamic>>? doses,
}) => {
  'id': medicationId,
  'version': 9,
  'archived_at': null,
  'current_revision': revisionJson(),
  'pending_revision': null,
  'reminder_preferences': preferencesJson(),
  'allowed_actions': actions,
  'doses': doses ?? [doseJson()],
  'taken_doses': 0,
  'scheduled_doses': 1,
};
Map<String, dynamic> paginationJson({int page = 1, int last = 1}) => {
  'page': page,
  'per_page': 100,
  'total': last,
  'last_page': last,
};
Map<String, dynamic> dashboardJson({
  List<Map<String, dynamic>>? medications,
  List<Map<String, dynamic>> missed = const [],
  Map<String, dynamic>? next,
  int page = 1,
  int last = 1,
}) => {
  'date': '2026-11-11',
  'timezone': 'Asia/Tokyo',
  'summary': {
    'scheduled_doses': 3,
    'taken_doses': 1,
    'remaining_doses': 1,
    'untaken_doses': 2,
    'missed_doses': 1,
    'skipped_doses': 0,
    'progress_fraction': 1 / 3,
  },
  'next_actionable_dose': next ?? doseJson(),
  'medications': medications ?? [medicationJson()],
  'medications_pagination': paginationJson(page: page, last: last),
  'missed_doses': missed,
  'missed_doses_pagination': paginationJson(),
};
Map<String, dynamic> contractData(Map<String, dynamic> data) => {
  'contract_version': 1,
  'server_now': '2026-11-10T23:10:00+00:00',
  ...data,
};
