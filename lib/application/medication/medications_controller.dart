import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../auth/auth_service.dart';
import '../../data/network/api_exception.dart';
import '../../data/mappers/medication_form_mapper.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/models/medication.dart';
import 'medication_repository.dart';
import 'medication_timezone.dart';

final class MedicationsController extends ChangeNotifier {
  MedicationsController(
    this.auth, {
    this.selectedPatientId,
    Future<String?> Function()? deviceTimezone,
    DateTime Function()? now,
  }) : _deviceTimezone = deviceTimezone ?? MedicationTimezone.deviceSuggestion,
       _now = now ?? DateTime.now {
    auth.addListener(_authChanged);
  }
  final AuthService auth;
  final String? selectedPatientId;
  final Future<String?> Function() _deviceTimezone;
  final DateTime Function() _now;
  AppUser? profile;
  MedicationRepository? repository;
  MedicationSettings? settings;
  MedicationDashboard? dashboard;
  List<MedicationRecord> dailyMedications = const [];
  List<MedicationRecord> medications = const [];
  List<MedicationDose> missedDoses = const [];
  Map<String, dynamic>? lastDoseDetails;
  String? patientId, errorCode, deviceSuggestion, _token;
  String viewerTimezone = 'UTC';
  bool loading = false,
      busy = false,
      needsReconciliation = false,
      _disposed = false;
  int _generation = 0;
  bool get isPatient => profile?.role == UserRole.patient;
  bool get canMutate =>
      !loading &&
      !busy &&
      !needsReconciliation &&
      repository != null &&
      dashboard != null;

  Future<void> initialize() async {
    if (loading || _disposed) return;
    loading = true;
    _notify();
    final generation = _generation;
    try {
      _token = (await auth.tokens.read())?.value;
      if (_token == null) {
        _invalidate('unauthenticated');
        return;
      }
      final user = await auth.getCurrentUserProfile();
      if (!await _current(generation)) return;
      if (user == null) {
        _invalidate('unauthenticated');
        return;
      }
      profile = user;
      patientId = isPatient ? user.uid : selectedPatientId;
      if (patientId == null || !RegExp(r'^[1-9][0-9]*$').hasMatch(patientId!)) {
        errorCode = 'patient-selection-required';
        return;
      }
      repository = MedicationRepository(
        auth.api,
        patientId: patientId!,
        expectedToken: _token!,
      );
      deviceSuggestion = await _deviceTimezone();
      if (!await _current(generation)) return;
      if (deviceSuggestion != null &&
          !MedicationTimezone.isValid(deviceSuggestion!)) {
        deviceSuggestion = null;
      }
      await _load(generation);
    } on ApiException catch (e) {
      if (!_disposed && generation == _generation) _failure(e);
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> refresh() async {
    if (loading || busy || _disposed) return;
    if (repository == null) {
      await initialize();
      return;
    }
    loading = true;
    _notify();
    final generation = _generation;
    try {
      await _load(generation);
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  Future<bool> _load(int generation) async {
    try {
      if (!await _current(generation)) return false;
      final repo = repository!;
      final fetchedSettings = await repo.settings();
      if (!await _current(generation)) return false;
      final zone = deviceSuggestion ?? fetchedSettings.timezone ?? 'UTC';
      if (!MedicationTimezone.isValid(zone)) {
        throw ApiException(code: 'invalid-response');
      }
      final date = MedicationTimezone.dateAt(repo.serverNow ?? _now(), zone);
      final listed = <MedicationRecord>[];
      var page = 1;
      while (true) {
        final result = await repo.list(page: page);
        if (!await _current(generation)) return false;
        listed.addAll(result.items);
        if (page >= result.lastPage) break;
        if (++page > 100) throw ApiException(code: 'invalid-response');
      }
      final first = await repo.dashboard(date, zone);
      if (!await _current(generation)) return false;
      final cards = [...first.medications], missed = [...first.missed];
      for (var p = 2; p <= first.lastPage; p++) {
        if (p > 100) throw ApiException(code: 'invalid-response');
        cards.addAll((await repo.dashboard(date, zone, page: p)).medications);
        if (!await _current(generation)) return false;
      }
      for (var p = 2; p <= first.missedLastPage; p++) {
        if (p > 100) throw ApiException(code: 'invalid-response');
        missed.addAll((await repo.dashboard(date, zone, missedPage: p)).missed);
        if (!await _current(generation)) return false;
      }
      final byId = {for (final m in cards) m.id: m};
      settings = fetchedSettings;
      viewerTimezone = zone;
      dashboard = first;
      dailyMedications = List.unmodifiable(cards);
      medications = List.unmodifiable(listed.map((m) => byId[m.id] ?? m));
      missedDoses = List.unmodifiable({for (final d in missed) d.id: d}.values);
      needsReconciliation = false;
      errorCode = null;
      return true;
    } on ApiException catch (e) {
      if (!_disposed && generation == _generation) _failure(e);
      return false;
    }
  }

  Future<bool> confirmTimezone(String zone) {
    if (!isPatient || !MedicationTimezone.isValid(zone)) {
      return Future.value(false);
    }
    return _mutate(() async {
      await repository!.confirmTimezone(zone, settings!.version);
    });
  }

  Future<bool> save(
    MedicationDraft draft, {
    MedicationRecord? previous,
    String? createKey,
  }) => _mutate(() async {
    final repo = repository!;
    if (previous == null) {
      await repo.create(draft, patientConsent: isPatient, key: createKey);
      return;
    }
    if (!previous.can('update')) throw ApiException(code: 'forbidden');
    final existing = MedicationDraft.fromRecord(previous);
    if (jsonEncode(existing.toBody()) != jsonEncode(draft.toBody())) {
      await repo.update(previous, draft);
    }
    var prefs = previous.preferences;
    if (prefs.reminders != draft.reminders) {
      if (!previous.can('change_reminders')) {
        throw ApiException(code: 'forbidden');
      }
      prefs = await repo.reminders(previous.id, prefs, draft.reminders);
    }
    if (prefs.caregiverConsent != draft.consent || prefs.delay != draft.delay) {
      if (!isPatient || !previous.can('change_escalation_consent')) {
        throw ApiException(code: 'forbidden');
      }
      await repo.consent(previous.id, prefs, draft.consent, draft.delay);
    }
  });
  Future<bool> archive(MedicationRecord med) {
    if (!med.can('archive')) return Future.value(false);
    return _mutate(() => repository!.archive(med));
  }

  Future<bool> recordDose(
    MedicationDose dose,
    String action, {
    String? reason,
  }) {
    final permission = action == 'corrections'
        ? 'correct'
        : action == 'late-intake'
        ? 'report_late_intake'
        : action;
    if (!isPatient || !dose.can(permission)) return Future.value(false);
    return _mutate(() async {
      await repository!.record(
        dose,
        action,
        reason: reason,
        target: action == 'corrections' ? 'unresolved' : null,
      );
      await repository!.medication(dose.medicationId);
      await repository!.dose(dose.id);
    });
  }

  Future<void> readDose(MedicationDose dose) async {
    if (repository == null || loading || busy) return;
    final generation = _generation;
    try {
      final data = await repository!.dose(dose.id);
      if (await _current(generation)) lastDoseDetails = Map.unmodifiable(data);
    } on ApiException catch (e) {
      if (!_disposed && generation == _generation) {
        _failure(e);
        _notify();
      }
      rethrow;
    }
  }

  Future<MedicationRecord?> readMedication(String id) async {
    if (!canMutate) return null;
    final generation = _generation;
    try {
      final result = await repository!.medication(id);
      return await _current(generation) ? result : null;
    } on ApiException catch (e) {
      if (!_disposed && generation == _generation) {
        _failure(e);
        _notify();
      }
      rethrow;
    }
  }

  Future<bool> _mutate(Future<void> Function() operation) async {
    if (!canMutate) return false;
    busy = true;
    errorCode = null;
    _notify();
    final generation = _generation;
    var confirmed = false;
    String? operationError;
    try {
      if (!await _current(generation)) return false;
      await operation();
      if (!await _current(generation)) return false;
      confirmed = true;
      needsReconciliation = true;
    } on ApiException catch (e) {
      if (!_disposed && generation == _generation) {
        operationError = e.code;
        needsReconciliation = true;
        _failure(e);
      }
    } finally {
      if (!_disposed && generation == _generation && repository != null) {
        if (needsReconciliation) await _load(generation);
        if (!_disposed && generation == _generation) {
          errorCode = operationError ?? errorCode;
          busy = false;
          _notify();
        }
      }
    }
    return confirmed;
  }

  Future<bool> _current(int generation) async {
    if (_disposed || generation != _generation) return false;
    final token = (await auth.tokens.read())?.value;
    if (_disposed || generation != _generation) return false;
    if (token == null || token != _token) {
      _invalidate(token == null ? 'unauthenticated' : 'session-changed');
      return false;
    }
    return true;
  }

  void _failure(ApiException error) {
    if (_disposed) return;
    errorCode = error.code;
    dashboard = null;
    medications = const [];
    missedDoses = const [];
    lastDoseDetails = null;
    dailyMedications = const [];
    if ([401, 403, 404].contains(error.statusCode) ||
        [
          'unauthenticated',
          'token-expired',
          'session-changed',
        ].contains(error.code)) {
      if ([
            'unauthenticated',
            'token-expired',
            'session-changed',
          ].contains(error.code) ||
          error.statusCode == 401) {
        _invalidate(error.code);
      } else {
        needsReconciliation = true;
      }
    }
  }

  void _authChanged() {
    if (profile != null && auth.currentUser?.uid != profile!.uid) {
      _invalidate('session-changed');
    }
  }

  void _invalidate(String code) {
    _generation++;
    repository = null;
    profile = null;
    settings = null;
    dashboard = null;
    medications = const [];
    missedDoses = const [];
    lastDoseDetails = null;
    dailyMedications = const [];
    patientId = null;
    errorCode = code;
    busy = false;
    loading = false;
    needsReconciliation = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    auth.removeListener(_authChanged);
    super.dispose();
  }
}
