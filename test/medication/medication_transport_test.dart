import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/data/network/api_exception.dart';
import 'package:sanad/domain/models/sanctum_token.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PATCH uses existing Bearer transport and explicit idempotency UUID',
    () async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await f.tokens.save(
        SanctumToken(
          value: 'test-session',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      f.override = (request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/patients/7/medication-settings');
        expect(request.headers['Authorization'], isNotNull);
        expect(
          request.headers['Idempotency-Key'],
          '11111111-1111-4111-a111-111111111111',
        );
        expect(jsonDecode(request.body), {
          'timezone': 'Asia/Tokyo',
          'expected_version': 0,
        });
        return f.response('medication-settings-update-completed', {});
      };
      await f.api.patch(
        '/api/v1/patients/7/medication-settings',
        body: {'timezone': 'Asia/Tokyo', 'expected_version': 0},
        authenticated: true,
        idempotencyKey: '11111111-1111-4111-a111-111111111111',
      );
    },
  );
  test('preserves medication conflict and permission error codes', () {
    for (final code in [
      'version-conflict',
      'patient-not-found',
      'dose-cancelled',
      'late-intake-required',
      'revision-not-effective',
    ]) {
      expect(ApiException.fromResponse(409, {'code': code}).code, code);
    }
  });
}
