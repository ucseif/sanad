import '../../domain/models/medication.dart';

/// Form values only. No local medication storage, recurrence or intake state.
final class MedicationDraft {
  const MedicationDraft({
    required this.name,
    required this.doseAmount,
    required this.unit,
    required this.form,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    this.timezone,
    this.weekdays = const [],
    this.intervalHours = 0,
    this.meal = 'noPreference',
    this.instructions = '',
    this.notes = '',
    this.reminders = true,
    this.consent = false,
    this.delay = 30,
  });
  final String name,
      doseAmount,
      unit,
      form,
      frequency,
      startDate,
      meal,
      instructions,
      notes;
  final String? endDate, timezone;
  final List<String> times;
  final List<int> weekdays;
  final int intervalHours, delay;
  final bool reminders, consent;
  static const frequencies = {
    'onceDaily': 'once_daily',
    'twiceDaily': 'twice_daily',
    'threeDaily': 'three_times_daily',
    'specificDays': 'specific_days',
    'everyHours': 'every_hours',
    'asNeeded': 'as_needed',
  };
  static const meals = {
    'beforeFood': 'before_food',
    'afterFood': 'after_food',
    'withFood': 'with_food',
    'noPreference': 'no_preference',
  };

  factory MedicationDraft.fromRecord(
    MedicationRecord record, {
    bool preferPending = true,
  }) {
    final r = preferPending
        ? (record.pending ?? record.current)
        : record.current;
    final p = r.prescription, s = r.schedule;
    String reverse(Map<String, String> map, Object? value) => map.entries
        .firstWhere(
          (entry) => entry.value == value,
          orElse: () =>
              throw const FormatException('Unsupported medication option.'),
        )
        .key;
    return MedicationDraft(
      name: p['name'] as String,
      doseAmount: p['dose_amount'] as String,
      unit: p['dose_unit'] as String,
      form: p['form'] as String,
      frequency: reverse(frequencies, s['frequency']),
      times: s['frequency'] == 'every_hours'
          ? [s['anchor_time'] as String]
          : medicationStrings(s['times']),
      startDate: s['start_date'] as String,
      endDate: s['end_date'] as String?,
      timezone: s['timezone'] as String,
      weekdays: List<int>.from(s['weekdays'] as List),
      intervalHours: (s['interval_hours'] as int?) ?? 0,
      meal: reverse(meals, p['relation_to_meals']),
      instructions: p['instructions'] as String,
      notes: p['special_notes'] as String,
      reminders: record.preferences.reminders,
      consent: record.preferences.caregiverConsent,
      delay: record.preferences.delay,
    );
  }

  Map<String, dynamic> toBody({bool includeTimezone = true}) {
    final wire = frequencies[frequency];
    final relation = meals[meal];
    if (wire == null || relation == null) {
      throw const FormatException('Unsupported medication option.');
    }
    return {
      'prescription': {
        'name': name,
        'dose_amount': doseAmount,
        'dose_unit': unit,
        'form': form,
        'relation_to_meals': relation,
        'instructions': instructions,
        'special_notes': notes,
      },
      'schedule': {
        'frequency': wire,
        if (includeTimezone && timezone != null) 'timezone': timezone,
        'start_date': startDate,
        'end_date': endDate,
        'times': ['asNeeded', 'everyHours'].contains(frequency)
            ? <String>[]
            : times,
        'weekdays': frequency == 'specificDays' ? weekdays : <int>[],
        'interval_hours': frequency == 'everyHours' ? intervalHours : null,
        'anchor_time': frequency == 'everyHours' ? times.first : null,
      },
    };
  }
}
