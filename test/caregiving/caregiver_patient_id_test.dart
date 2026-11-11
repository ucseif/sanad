import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/caregiver_link.dart';

Map<String, dynamic> relationship({String status = 'active'}) => {
  'id': '79e6b581-b223-4c55-b180-878f6dbc159a',
  'status': status,
  'counterpart': {'name': 'Patient display', 'username': 'Patient1'},
  'invited_at': '2026-11-08T12:00:00+00:00',
  'accepted_at': '2026-11-08T12:01:00+00:00',
  'ended_at': null,
  'allowed_actions': ['revoke'],
};

void main() {
  test(
    'parses real patient_id while preserving existing relationship fields',
    () {
      final link = CaregiverLink.fromJson({
        ...relationship(),
        'patient_id': '42',
      });
      expect(link.patientId, '42');
      expect(link.id, '79e6b581-b223-4c55-b180-878f6dbc159a');
      expect(link.status, CaregiverLinkStatus.active);
      expect(link.counterpart.username, 'Patient1');
      expect(link.actions, ['revoke']);
      expect(link.acceptedAt, DateTime.utc(2026, 11, 8, 12, 1));
    },
  );

  test(
    'old responses without patient_id remain compatible and never infer an ID',
    () {
      final old = CaregiverLink.fromJson(relationship());
      expect(old.patientId, isNull);
      expect(
        CaregiverLink.fromJson({
          ...relationship(),
          'patient_id': null,
        }).patientId,
        isNull,
      );
    },
  );

  test('normalizes integer IDs and preserves exact large string IDs', () {
    expect(
      CaregiverLink.fromJson({...relationship(), 'patient_id': 42}).patientId,
      '42',
    );
    expect(
      CaregiverLink.fromJson({
        ...relationship(),
        'patient_id': '9007199254740993',
      }).patientId,
      '9007199254740993',
    );
  });

  test(
    'rejects malformed patient IDs rather than substituting another identity',
    () {
      for (final value in [
        0,
        -1,
        1.5,
        true,
        '',
        '0',
        '-1',
        'Patient1',
        <String, dynamic>{},
      ]) {
        expect(
          () =>
              CaregiverLink.fromJson({...relationship(), 'patient_id': value}),
          throwsFormatException,
        );
      }
    },
  );

  test('multi-patient caregiver list retains each relationship patient ID', () {
    final result = CaregiverLinksPage.fromJson({
      'links': [
        {...relationship(), 'patient_id': '42'},
        {...relationship(status: 'pending'), 'patient_id': '87'},
      ],
      'pagination': {'page': 1, 'last_page': 1},
    });
    expect(result.links.map((link) => link.patientId), ['42', '87']);
    expect(result.links.last.status, CaregiverLinkStatus.pending);
  });
}
