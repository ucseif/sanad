import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/medication.dart';
import 'package:sanad/data/mappers/medication_form_mapper.dart';
import 'package:sanad/application/medication/medication_timezone.dart';
import 'medication_fixtures.dart';

void main() {
  test(
    'uses server summary and next dose, retains separate missed collection',
    () {
      final missed = doseJson(
        status: 'missed',
        actions: ['view', 'report_late_intake', 'correct'],
      );
      final data = MedicationDashboard.fromJson(
        dashboardJson(missed: [missed]),
      );
      expect(data.summary.scheduled, 3);
      expect(data.summary.remaining, 1);
      expect(data.summary.progress, 1 / 3);
      expect(data.nextDose!.id, doseId);
      expect(data.missed.single.status, 'missed');
      expect(data.medications.single.version, 9);
      expect(data.medications.single.preferences.version, 4);
      expect(data.nextDose!.version, 6);
    },
  );
  test('preserves schedule local times and amount/unit without conversion', () {
    final med = MedicationRecord.fromJson(medicationJson());
    final draft = MedicationDraft.fromRecord(med);
    expect(draft.frequency, 'onceDaily');
    expect(draft.doseAmount, '2.5');
    expect(draft.unit, 'mg');
    expect(draft.times, ['08:00']);
    expect(draft.toBody()['schedule']['timezone'], 'Asia/Tokyo');
    expect(med.doses.single.scheduledAt, DateTime.utc(2026, 11, 10, 23));
  });
  test(
    'all frequency mappings preserve options including interval anchor and PRN',
    () {
      for (final pair in {
        'onceDaily': 'once_daily',
        'twiceDaily': 'twice_daily',
        'threeDaily': 'three_times_daily',
        'specificDays': 'specific_days',
        'everyHours': 'every_hours',
        'asNeeded': 'as_needed',
      }.entries) {
        final draft = MedicationDraft(
          name: 'Example',
          doseAmount: '1',
          unit: 'tablet',
          form: 'tablet',
          frequency: pair.key,
          times: ['08:00'],
          weekdays: [1, 3],
          intervalHours: 4,
          startDate: '2026-11-11',
        );
        final s = draft.toBody()['schedule'];
        expect(s['frequency'], pair.value);
        if (pair.key == 'everyHours') {
          expect(s['times'], isEmpty);
          expect(s['anchor_time'], '08:00');
        }
        if (pair.key == 'asNeeded') {
          expect(s['times'], isEmpty);
          expect(s['anchor_time'], isNull);
        }
        expect(s['weekdays'], pair.key == 'specificDays' ? [1, 3] : isEmpty);
      }
    },
  );
  test(
    'caregiver actions and no-next state come exclusively from response',
    () {
      final json = dashboardJson();
      json['next_actionable_dose'] = null;
      final data = MedicationDashboard.fromJson(json);
      expect(data.nextDose, isNull);
      final dose = MedicationDose.fromJson(doseJson(actions: ['view']));
      expect(dose.can('taken'), isFalse);
    },
  );
  test(
    'rejects invalid or missed Up Next instead of inventing replacement',
    () {
      expect(
        () => MedicationDashboard.fromJson(
          dashboardJson(next: doseJson(status: 'missed')),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'IANA day conversion crosses midnight and DST; abbreviations rejected',
    () {
      expect(
        MedicationTimezone.dateAt(
          DateTime.utc(2026, 11, 10, 23, 30),
          'Asia/Tokyo',
        ),
        '2026-11-11',
      );
      expect(
        MedicationTimezone.dateAt(
          DateTime.utc(2026, 3, 8, 4, 30),
          'America/New_York',
        ),
        '2026-03-07',
      );
      expect(MedicationTimezone.isValid('EET'), isFalse);
      expect(MedicationTimezone.isValid('Africa/Cairo'), isTrue);
    },
  );
  test(
    'malformed prescription and dropdown enum values fail before reaching widgets',
    () {
      final invalidName = medicationJson();
      invalidName['current_revision']['prescription']['name'] = 23;
      expect(
        () => MedicationRecord.fromJson(invalidName),
        throwsFormatException,
      );
      final invalidForm = medicationJson();
      invalidForm['current_revision']['prescription']['form'] = 'invented';
      expect(
        () => MedicationRecord.fromJson(invalidForm),
        throwsFormatException,
      );
      final invalidTimes = medicationJson();
      invalidTimes['current_revision']['schedule']['times'] = ['25:00'];
      expect(
        () => MedicationRecord.fromJson(invalidTimes),
        throwsFormatException,
      );
    },
  );
}
