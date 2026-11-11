import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

abstract final class MedicationTimezone {
  static bool _initialized = false;
  static void _initialize() {
    if (!_initialized) {
      data.initializeTimeZones();
      _initialized = true;
    }
  }

  static bool isValid(String value) {
    if (value != 'UTC' && !value.contains('/')) return false;
    _initialize();
    try {
      tz.getLocation(value);
      return true;
    } on tz.LocationNotFoundException {
      return false;
    }
  }

  static String dateAt(DateTime instant, String timezone) {
    if (!isValid(timezone)) {
      throw const FormatException('An IANA timezone is required.');
    }
    final local = tz.TZDateTime.from(instant, tz.getLocation(timezone));
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  static Future<String?> deviceSuggestion() async {
    try {
      final value = await const MethodChannel(
        'sanad/device',
      ).invokeMethod<String>('getTimezone');
      return value != null && isValid(value) ? value : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
