import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/application/medication/medication_timezone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sanad/device');
  test(
    'device suggestions use IANA channel result; abbreviations never default to Cairo',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getTimezone');
        return 'Asia/Tokyo';
      });
      expect(await MedicationTimezone.deviceSuggestion(), 'Asia/Tokyo');
      messenger.setMockMethodCallHandler(channel, (_) async => 'EET');
      expect(await MedicationTimezone.deviceSuggestion(), isNull);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      expect(await MedicationTimezone.deviceSuggestion(), isNull);
    },
  );
}
