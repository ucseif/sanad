import 'dart:async';

import 'package:flutter/material.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../application/auth/auth_service.dart';
import '../../../application/medication/medications_controller.dart';
import '../../../application/medication/medication_repository.dart';
import '../../../application/medication/medication_timezone.dart';
import '../../../data/mappers/medication_form_mapper.dart';
import '../../../data/network/api_exception.dart';
import '../../../domain/models/medication.dart';

class MedicationsContent extends StatefulWidget {
  const MedicationsContent({
    super.key,
    required this.userId,
    this.authService,
    this.selectedPatientId,
    this.controller,
  });

  final String userId;
  final AuthService? authService;
  final String? selectedPatientId;
  final MedicationsController? controller;

  @override
  State<MedicationsContent> createState() => _MedicationsContentState();
}

class _MedicationsContentState extends State<MedicationsContent>
    with WidgetsBindingObserver {
  static const _accent = Color(0xFF212529);
  static const _success = Color(0xFF23866A);
  static const _ink = Color(0xFF171719);
  static const _muted = Color(0xFF85858B);

  MedicationsController? _controller;
  Timer? _refreshTimer;
  bool _foreground = true;
  BuildContext? _activeFormContext;
  List<_Medication> _medications = [];
  bool _loading = true;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _tr(String en, String ar) => _isArabic ? ar : en;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    try {
      _controller =
          widget.controller ??
          MedicationsController(
            widget.authService ?? AuthScope.read(context),
            selectedPatientId: widget.selectedPatientId,
          );
    } on StateError {
      _loading = false;
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _controller!.addListener(_changed);
    _changed();
    if (_controller!.profile == null && !_controller!.loading) {
      unawaited(_controller!.initialize());
    }
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_foreground) unawaited(_controller!.refresh());
    });
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      _loading = _controller!.loading;
      _medications = _controller!.medications
          .map(_Medication.fromServer)
          .toList();
    });
    if ([
          'version-conflict',
          'idempotency-conflict',
        ].contains(_controller!.errorCode) ||
        (_controller!.dashboard == null &&
            [
              'unauthenticated',
              'token-expired',
              'session-changed',
              'forbidden',
              'patient-not-found',
              'medication-not-found',
            ].contains(_controller!.errorCode))) {
      final modal = _activeFormContext;
      _activeFormContext = null;
      if (modal != null && modal.mounted) Navigator.of(modal).pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) unawaited(_controller?.refresh());
  }

  @override
  void didUpdateWidget(covariant MedicationsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.selectedPatientId != widget.selectedPatientId ||
        oldWidget.authService != widget.authService ||
        oldWidget.controller != widget.controller) {
      _release(oldWidget.controller != null);
      _controller = null;
      _medications = [];
      _loading = true;
      didChangeDependencies();
    }
  }

  void _release(bool injected) {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_changed);
    if (!injected) _controller?.dispose();
  }

  @override
  void dispose() {
    _release(widget.controller != null);
    super.dispose();
  }

  String _errorMessage(String? code) => switch (code) {
    'patient-selection-required' => _tr(
      'Select a linked patient to view medications. Patient selection is not available in this screen yet.',
      'اختر مريضًا مرتبطًا لعرض أدويته. اختيار المريض غير متاح في هذه الشاشة حاليًا.',
    ),
    'unauthenticated' || 'token-expired' || 'session-changed' => _tr(
      'Your session changed or expired. Sign in again.',
      'تغيرت جلستك أو انتهت. سجّل الدخول مجددًا.',
    ),
    'version-conflict' || 'idempotency-conflict' => _tr(
      'The record changed. Reopen it to review refreshed data before saving again.',
      'تغير السجل. أعد فتحه لمراجعة البيانات المحدثة قبل الحفظ مجددًا.',
    ),
    'forbidden' ||
    'patient-not-found' ||
    'medication-not-found' ||
    'dose-not-found' => _tr(
      'You no longer have access to this record.',
      'لم تعد لديك صلاحية الوصول إلى هذا السجل.',
    ),
    'too-many-requests' => _tr(
      'Too many requests. Please wait and try again.',
      'طلبات كثيرة. انتظر ثم حاول مجددًا.',
    ),
    'validation-failed' => _tr(
      'Check the medication fields, times and dates.',
      'راجع بيانات الدواء والمواعيد والتواريخ.',
    ),
    'late-intake-required' => _tr(
      'Late intake requires an explicit report. That interaction is not available yet.',
      'التناول المتأخر يحتاج تسجيلًا صريحًا. هذه الخطوة غير متاحة حاليًا.',
    ),
    _ => _tr(
      'Could not load or save medication data. Refresh and try again.',
      'تعذر تحميل بيانات الأدوية أو حفظها. حدّث وحاول مجددًا.',
    ),
  };

  void _showError([String? code]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(code ?? _controller?.errorCode))),
      );
    }
  }

  Future<String?> _timezone({required bool confirmation}) => showDialog<String>(
    context: context,
    builder: (_) => _MedicationTimezoneDialog(
      isArabic: _isArabic,
      confirmation: confirmation,
      suggestion: _controller?.deviceSuggestion,
    ),
  );

  Future<void> _addMedication() => _openForm();

  Future<void> _openForm({_Medication? medicine}) async {
    final c = _controller;
    if (c == null || !c.canMutate) return;
    MedicationRecord? previous;
    _Medication? initial;
    if (medicine != null) {
      try {
        previous = await c.readMedication(medicine.id);
        if (!mounted || previous == null || !previous.can('update')) return;
        initial = _Medication.fromServer(previous, editing: true);
      } on ApiException catch (e) {
        _showError(e.code);
        await c.refresh();
        return;
      }
    }
    if (!mounted) return;
    var zone = initial?.timezone ?? c.settings?.timezone;
    if (medicine == null && c.isPatient && c.settings!.requiresConfirmation) {
      zone = await _timezone(confirmation: true);
      if (zone == null || !mounted) return;
      if (!await c.confirmTimezone(zone)) {
        _showError();
        return;
      }
    } else if (zone == null) {
      zone = await _timezone(confirmation: false);
      if (zone == null || !mounted) return;
    }
    if (!mounted) return;
    final createIntent = MedicationMutationIntent();
    await showModalBottomSheet<_Medication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) {
        _activeFormContext = context;
        return DraggableScrollableSheet(
          initialChildSize: .84,
          minChildSize: .48,
          maxChildSize: .94,
          expand: false,
          shouldCloseOnMinExtent: true,
          builder: (context, scrollController) => _MedicationForm(
            isArabic: _isArabic,
            scrollController: scrollController,
            initial: initial,
            today: DateTime.parse(
              MedicationTimezone.dateAt(
                c.repository!.serverNow ?? DateTime.now(),
                zone!,
              ),
            ),
            canConsent:
                c.isPatient &&
                (previous == null || previous.can('change_escalation_consent')),
            onSave: (record) async {
              final draft = record.draft(zone!);
              final key = createIntent.keyFor({
                ...draft.toBody(),
                'reminders': draft.reminders,
                'consent': draft.consent,
                'delay': draft.delay,
              });
              final saved = await c.save(
                draft,
                previous: previous,
                createKey: key,
              );
              if (!saved) _showError();
              return saved;
            },
          ),
        );
      },
    );
    _activeFormContext = null;
  }

  Future<void> _toggleTaken(MedicationDose dose) async {
    if (_controller?.isPatient == true && dose.can('taken')) {
      if (!await _controller!.recordDose(dose, 'taken')) _showError();
    } else {
      try {
        await _controller?.readDose(dose);
        if (dose.status == 'missed') _showError('late-intake-required');
      } on ApiException catch (e) {
        _showError(e.code);
      }
    }
  }

  Future<void> _skipDose(MedicationDose dose) async {
    if (_controller?.isPatient == true &&
        dose.can('skipped') &&
        !await _controller!.recordDose(dose, 'skipped')) {
      _showError();
    }
  }

  Future<void> _delete(_Medication medicine) async {
    if (medicine.record != null &&
        !await _controller!.archive(medicine.record!)) {
      _showError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _controller?.dashboard?.summary;
    final dueToday = summary?.scheduled ?? 0;
    final doneToday = summary?.taken ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _tr('Medications', 'الأدوية'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.4,
                  color: _ink,
                ),
              ),
            ),
            IconButton(
              tooltip: _tr('Refresh', 'تحديث'),
              onPressed:
                  _controller?.loading == true || _controller?.busy == true
                  ? null
                  : () => _controller?.refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 46),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent,
                ),
              ),
            ),
          )
        else if (_controller == null ||
            (_controller!.errorCode != null &&
                _controller!.dashboard == null)) ...[
          Text(_errorMessage(_controller?.errorCode)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _controller?.refresh(),
              child: Text(_tr('Try again', 'إعادة المحاولة')),
            ),
          ),
        ] else if (_medications.isEmpty && dueToday == 0) ...[
          _medicinesHeader(),
          const SizedBox(height: 8),
          _emptyState(),
        ] else ...[
          _summary(dueToday, doneToday),
          const SizedBox(height: 18),
          _nextDoseCard(),
          const SizedBox(height: 24),
          _medicinesHeader(),
          const SizedBox(height: 8),
          ..._sortedMedications().map(_medicineTile),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _medicinesHeader() => Row(
    children: [
      Expanded(
        child: Text(
          _tr('Your medicines', 'أدويتك'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: _controller?.canMutate == true ? _addMedication : null,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(_tr('Add', 'إضافة')),
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _summary(int due, int done) {
    final progress = _controller!.dashboard!.summary.progress;
    final remaining = _controller!.dashboard!.summary.remaining;
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 17),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr('TODAY', 'اليوم'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$due',
                          style: const TextStyle(
                            fontSize: 48,
                            height: .95,
                            letterSpacing: -2,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 8,
                            bottom: 5,
                          ),
                          child: Text(
                            _tr('scheduled doses', 'جرعات مجدولة'),
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  remaining == 0
                      ? Icons.check_rounded
                      : Icons.medication_outlined,
                  size: 20,
                  color: remaining == 0 ? _success : _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFDDE0E3),
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  remaining == 0
                      ? (done == due
                            ? _tr('All doses completed', 'اكتملت جرعات اليوم')
                            : _tr(
                                'No actionable doses remaining',
                                'لا توجد جرعات متاحة متبقية',
                              ))
                      : _tr(
                          '$remaining ${remaining == 1 ? 'dose' : 'doses'} left',
                          'متبقي $remaining جرعة',
                        ),
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              Text(
                '$done / $due',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 218,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 27,
                right: 42,
                child: Container(
                  width: 126,
                  height: 126,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 38,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F3F4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Transform.rotate(
                angle: -.52,
                child: Container(
                  width: 151,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: const Color(0xFFD8D8D6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFFEFB),
                                    Color(0xFFECE4D8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(width: 2, color: const Color(0xFFC9BEB2)),
                          const Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFEAA096),
                                    Color(0xFFC96D63),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        left: 18,
                        right: 18,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .42),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 36,
                left: 48,
                child: _emptyBadge(
                  Icons.schedule_rounded,
                  const Color(0xFF596975),
                ),
              ),
              Positioned(
                bottom: 35,
                right: 49,
                child: _emptyBadge(
                  Icons.check_rounded,
                  const Color(0xFF47816D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _tr('A little more organized', 'خلي مواعيد أدويتك أسهل'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 21,
            height: 1.2,
            letterSpacing: -.3,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _tr(
            'Add your medicines and their prescribed times. Your daily schedule will appear here.',
            'أضف أدويتك ومواعيدها الموصوفة، وهتظهر لك هنا في جدول يومي واضح.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.55, color: _muted),
        ),
      ],
    ),
  );

  Widget _emptyBadge(IconData icon, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, size: 19, color: color),
  );

  List<_Medication> _sortedMedications() => [..._medications]
    ..sort(
      (a, b) => (a.times.isEmpty ? '99:99' : a.times.first).compareTo(
        b.times.isEmpty ? '99:99' : b.times.first,
      ),
    );

  ({_Medication medicine, String time, MedicationDose occurrence})?
  _nextDose() {
    final next = _controller?.dashboard?.nextDose;
    if (next == null) return null;
    final record = _controller!.dailyMedications
        .where((m) => m.id == next.medicationId)
        .firstOrNull;
    if (record == null) return null;
    return (
      medicine: _Medication.fromServer(record),
      time: next.localTime!,
      occurrence: next,
    );
  }

  Widget _nextDoseCard() {
    final dose = _nextDose();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: dose == null
          ? Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: _success,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Text(
                  _tr('No upcoming doses today', 'لا توجد جرعات قادمة اليوم'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    dose.time,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: _ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tr('UP NEXT', 'الجرعة القادمة'),
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dose.medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      Text(
                        '${dose.medicine.dose} · ${dose.medicine.formLabel(_isArabic)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _tr('Mark dose as taken', 'تسجيل تناول الجرعة'),
                  onPressed:
                      _controller?.canMutate == true &&
                          _controller!.isPatient &&
                          dose.occurrence.can('taken')
                      ? () => _toggleTaken(dose.occurrence)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE6F1EB),
                    foregroundColor: _success,
                    fixedSize: const Size(38, 38),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 19),
                ),
              ],
            ),
    );
  }

  Widget _medicineTile(_Medication medicine) {
    final takenCount = medicine.record?.todayTaken ?? 0;
    return Dismissible(
      key: ValueKey(medicine.id),
      direction:
          _controller?.canMutate == true &&
              medicine.record?.can('archive') == true
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsetsDirectional.only(end: 18),
        alignment: AlignmentDirectional.centerEnd,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFD95757),
        ),
      ),
      confirmDismiss: (_) async {
        await _delete(medicine);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F9),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 18,
                color: Color(0xFF52606D),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap:
                        _controller?.canMutate == true &&
                            medicine.record?.can('update') == true
                        ? () => _openForm(medicine: medicine)
                        : null,
                    child: Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${medicine.dose} · ${medicine.formLabel(_isArabic)}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final occurrence in medicine.occurrences.where(
                        (d) => d.kind == 'scheduled',
                      ))
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _controller?.canMutate == true
                              ? () => _toggleTaken(occurrence)
                              : null,
                          onLongPress:
                              _controller?.canMutate == true &&
                                  _controller!.isPatient &&
                                  occurrence.can('skipped')
                              ? () => _skipDose(occurrence)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: occurrence.status == 'taken'
                                  ? const Color(0xFFE7F2EC)
                                  : occurrence.status == 'missed'
                                  ? const Color(0xFFFFEEEE)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  occurrence.status == 'taken'
                                      ? Icons.check_circle_rounded
                                      : occurrence.status == 'missed'
                                      ? Icons.error_outline_rounded
                                      : occurrence.status == 'skipped'
                                      ? Icons.remove_circle_outline_rounded
                                      : Icons.access_time_rounded,
                                  size: 12,
                                  color: occurrence.status == 'taken'
                                      ? _success
                                      : occurrence.status == 'missed'
                                      ? const Color(0xFFD95757)
                                      : _muted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  occurrence.localTime!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: (occurrence.status == 'taken')
                                        ? _success
                                        : _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (takenCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$takenCount/${medicine.record?.todayScheduled ?? 0}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _success,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Medication {
  const _Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.form,
    required this.times,
    this.doseAmount = '',
    this.doseUnit = 'mg',
    this.frequency = 'onceDaily',
    this.days = const [],
    this.intervalHours = 0,
    this.startDate,
    this.endDate,
    this.noEndDate = true,
    this.relationToMeals = 'noPreference',
    this.instructions = '',
    this.specialNotes = '',
    this.remindersEnabled = true,
    this.notifyCaregiver = false,
    this.escalationDelayMinutes = 30,
    this.timezone,
    this.record,
    this.occurrences = const [],
  });
  final String id,
      name,
      dose,
      doseAmount,
      doseUnit,
      form,
      frequency,
      relationToMeals,
      instructions,
      specialNotes;
  final List<String> times;
  final List<int> days;
  final int intervalHours, escalationDelayMinutes;
  final String? startDate, endDate, timezone;
  final bool noEndDate, remindersEnabled, notifyCaregiver;
  final MedicationRecord? record;
  final List<MedicationDose> occurrences;
  factory _Medication.fromServer(MedicationRecord med, {bool editing = false}) {
    final d = MedicationDraft.fromRecord(med, preferPending: editing);
    return _Medication(
      id: med.id,
      name: d.name,
      dose: '${d.doseAmount} ${d.unit}',
      doseAmount: d.doseAmount,
      doseUnit: d.unit,
      form: d.form,
      times: d.times,
      frequency: d.frequency,
      days: d.weekdays,
      intervalHours: d.intervalHours,
      startDate: d.startDate,
      endDate: d.endDate,
      noEndDate: d.endDate == null,
      relationToMeals: d.meal,
      instructions: d.instructions,
      specialNotes: d.notes,
      remindersEnabled: d.reminders,
      notifyCaregiver: d.consent,
      escalationDelayMinutes: d.delay,
      timezone: d.timezone,
      record: med,
      occurrences: med.doses,
    );
  }
  MedicationDraft draft(String zone) => MedicationDraft(
    name: name,
    doseAmount: doseAmount,
    unit: doseUnit,
    form: form,
    frequency: frequency,
    times: times,
    weekdays: days,
    intervalHours: intervalHours,
    startDate: startDate!,
    endDate: endDate,
    timezone: zone,
    meal: relationToMeals,
    instructions: instructions,
    notes: specialNotes,
    reminders: remindersEnabled,
    consent: notifyCaregiver,
    delay: escalationDelayMinutes,
  );
  String formLabel(bool ar) => switch (form) {
    'capsule' => ar ? 'كبسولة' : 'Capsule',
    'syrup' => ar ? 'شراب' : 'Syrup',
    'drops' => ar ? 'نقط' : 'Drops',
    'injection' => ar ? 'حقن' : 'Injection',
    'inhaler' => ar ? 'بخاخ' : 'Inhaler',
    'cream' => ar ? 'كريم / مرهم' : 'Cream / Ointment',
    'other' => ar ? 'أخرى' : 'Other',
    _ => ar ? 'قرص' : 'Tablet',
  };
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({
    required this.isArabic,
    required this.scrollController,
    required this.onSave,
    required this.canConsent,
    required this.today,
    this.initial,
  });
  final bool isArabic;
  final ScrollController scrollController;
  final Future<bool> Function(_Medication) onSave;
  final bool canConsent;
  final DateTime today;
  final _Medication? initial;

  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  static const _accent = Color(0xFF212529);
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '4');
  final _times = <TimeOfDay>[const TimeOfDay(hour: 8, minute: 0)];
  final _days = <int>{};
  String _form = 'tablet';
  String _doseUnit = 'mg';
  String _frequency = 'onceDaily';
  String _relation = 'noPreference';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _reminders = true;
  bool _caregiverAlert = false;
  int _delay = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      _startDate = widget.today;
      return;
    }
    _nameController.text = initial.name;
    _doseController.text = initial.doseAmount;
    _instructionsController.text = initial.instructions;
    _notesController.text = initial.specialNotes;
    _intervalController.text = '${initial.intervalHours}';
    _form = initial.form;
    _doseUnit = initial.doseUnit;
    _frequency = initial.frequency;
    _relation = initial.relationToMeals;
    _startDate = DateTime.parse(initial.startDate!);
    _endDate = initial.endDate == null
        ? null
        : DateTime.parse(initial.endDate!);
    _reminders = initial.remindersEnabled;
    _caregiverAlert = initial.notifyCaregiver;
    _delay = initial.escalationDelayMinutes;
    _days.addAll(initial.days);
    _times.clear();
    _times.addAll(
      initial.times.map((time) {
        final parts = time.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }),
    );
    if (_times.isEmpty) _times.add(const TimeOfDay(hour: 8, minute: 0));
  }

  String tr(String en, String ar) => widget.isArabic ? ar : en;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _times.isEmpty
          ? const TimeOfDay(hour: 8, minute: 0)
          : _times.last,
      helpText: tr('Choose dose time', 'اختر موعد الجرعة'),
    );
    if (selected != null && !_times.contains(selected)) {
      setState(() => _times.add(selected));
      _times.sort((a, b) => a.hour * 60 + a.minute - b.hour * 60 - b.minute);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final doseValue = _doseController.text.trim();
    final dose = '$doseValue $_doseUnit';
    final needsTimes = _frequency != 'asNeeded';
    final needsDays = _frequency == 'specificDays';
    if (name.isEmpty ||
        doseValue.isEmpty ||
        (needsTimes && _times.isEmpty) ||
        (needsDays && _days.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Enter a medicine name and dose.', 'اكتب اسم الدواء والجرعة.'),
          ),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final record = _Medication(
      id: '${now.microsecondsSinceEpoch}',
      name: name,
      dose: dose,
      doseAmount: doseValue,
      doseUnit: _doseUnit,
      form: _form,
      times: needsTimes ? _times.map(_formatTime).toList() : [],
      frequency: _frequency,
      days: _days.toList()..sort(),
      intervalHours: _frequency == 'everyHours'
          ? (int.tryParse(_intervalController.text) ?? 4)
          : 0,
      startDate: _dateKey(_startDate),
      endDate: _endDate == null ? null : _dateKey(_endDate!),
      noEndDate: _endDate == null,
      relationToMeals: _relation,
      instructions: _instructionsController.text.trim(),
      specialNotes: _notesController.text.trim(),
      remindersEnabled: _reminders,
      notifyCaregiver: _caregiverAlert,
      escalationDelayMinutes: _delay,
    );
    setState(() => _saving = true);
    var saved = false;
    try {
      saved = await widget.onSave(record);
      if (saved && mounted) Navigator.of(context).pop(record);
    } finally {
      if (mounted && !saved) setState(() => _saving = false);
    }
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool start}) async {
    final now = widget.today;
    final date = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : (_endDate ?? _startDate),
      firstDate: start
          ? DateTime(
              _startDate.year < now.year - 1 ? _startDate.year : now.year - 1,
            )
          : _startDate,
      lastDate: DateTime(
        (_endDate?.year ?? _startDate.year) > now.year + 15
            ? (_endDate?.year ?? _startDate.year) + 1
            : now.year + 15,
      ),
    );
    if (date != null) {
      setState(() {
        if (start) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(date)) _endDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _weekday(int day) => switch (day) {
    1 => tr('Mon', 'اثن'),
    2 => tr('Tue', 'ثلا'),
    3 => tr('Wed', 'أرب'),
    4 => tr('Thu', 'خمي'),
    5 => tr('Fri', 'جمع'),
    6 => tr('Sat', 'سبت'),
    _ => tr('Sun', 'أحد'),
  };

  Widget _dropdown<T>({
    required T value,
    required List<T> values,
    required String Function(T) label,
    required ValueChanged<T> onChanged,
    bool enabled = true,
  }) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: values
            .map((v) => DropdownMenuItem<T>(value: v, child: Text(label(v))))
            .toList(),
        onChanged: !enabled
            ? null
            : (v) {
                if (v != null) onChanged(v);
              },
        style: const TextStyle(fontSize: 12, color: Color(0xFF171719)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: widget.scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9DE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    Text(
                      widget.initial == null
                          ? tr('Add a medicine', 'إضافة دواء')
                          : tr('Edit medicine', 'تعديل الدواء'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171719),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tr(
                        'Add the details from your prescription.',
                        'أدخل البيانات كما وردت في الوصفة الطبية.',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF85858B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      tr('Medication information', 'معلومات الدواء'),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Medicine name', 'اسم الدواء')),
                    const SizedBox(height: 7),
                    _input(
                      _nameController,
                      tr('e.g. Vitamin D', 'مثال: فيتامين د'),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Dose', 'الجرعة')),
                              const SizedBox(height: 7),
                              _input(
                                _doseController,
                                tr('e.g. 500', 'مثال: 500'),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Form', 'الشكل')),
                              const SizedBox(height: 7),
                              Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _form,
                                    isExpanded: true,
                                    items: [
                                      DropdownMenuItem(
                                        value: 'tablet',
                                        child: Text(tr('Tablet', 'قرص')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'capsule',
                                        child: Text(tr('Capsule', 'كبسولة')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'syrup',
                                        child: Text(tr('Syrup', 'شراب')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'drops',
                                        child: Text(tr('Drops', 'نقط')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'injection',
                                        child: Text(tr('Injection', 'حقن')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'inhaler',
                                        child: Text(tr('Inhaler', 'بخاخ')),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cream',
                                        child: Text(
                                          tr('Cream / Ointment', 'كريم / مرهم'),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'other',
                                        child: Text(tr('Other', 'أخرى')),
                                      ),
                                    ],
                                    onChanged: (value) => setState(
                                      () => _form = value ?? 'tablet',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF171719),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 15),
                    _fieldLabel(tr('Dose unit', 'وحدة الجرعة')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _doseUnit,
                      values: const [
                        'mg',
                        'g',
                        'ml',
                        'mcg',
                        'IU',
                        'tablet',
                        'capsule',
                        'drop',
                        'puff',
                      ],
                      label: (v) => v,
                      onChanged: (v) => setState(() => _doseUnit = v),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(tr('Medication schedule', 'جدول الدواء')),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Frequency', 'التكرار')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _frequency,
                      values: const [
                        'onceDaily',
                        'twiceDaily',
                        'threeDaily',
                        'specificDays',
                        'everyHours',
                        'asNeeded',
                      ],
                      label: (v) => switch (v) {
                        'onceDaily' => tr('Once Daily', 'مرة يوميًا'),
                        'twiceDaily' => tr('Twice Daily', 'مرتين يوميًا'),
                        'threeDaily' => tr(
                          'Three Times Daily',
                          'ثلاث مرات يوميًا',
                        ),
                        'specificDays' => tr('Specific Days', 'أيام محددة'),
                        'everyHours' => tr('Every X Hours', 'كل عدد ساعات'),
                        _ => tr('As Needed (PRN)', 'عند الحاجة (PRN)'),
                      },
                      onChanged: (value) => setState(() {
                        _frequency = value;
                        final count = switch (value) {
                          'twiceDaily' => 2,
                          'threeDaily' => 3,
                          _ => 1,
                        };
                        if (value != 'asNeeded' &&
                            value != 'specificDays' &&
                            value != 'everyHours') {
                          while (_times.length < count) {
                            _times.add(
                              TimeOfDay(
                                hour: 8 + (_times.length * 6),
                                minute: 0,
                              ),
                            );
                          }
                          while (_times.length > count) {
                            _times.removeLast();
                          }
                        }
                      }),
                    ),
                    if (_frequency == 'everyHours') ...[
                      const SizedBox(height: 12),
                      _fieldLabel(tr('Interval in hours', 'الفاصل بالساعات')),
                      const SizedBox(height: 7),
                      _input(
                        _intervalController,
                        '4',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    if (_frequency == 'specificDays') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 4,
                        children: [
                          for (var day = 1; day <= 7; day++)
                            FilterChip(
                              label: Text(_weekday(day)),
                              selected: _days.contains(day),
                              onSelected: (selected) => setState(
                                () => selected
                                    ? _days.add(day)
                                    : _days.remove(day),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    _fieldLabel(tr('Reminder times', 'مواعيد التذكير')),
                    const SizedBox(height: 7),
                    if (_frequency == 'asNeeded')
                      Text(
                        tr(
                          'No fixed reminder time for as-needed medicine.',
                          'دواء عند الحاجة لا يحتاج موعدًا ثابتًا.',
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF85858B),
                        ),
                      )
                    else if (_frequency == 'everyHours') ...[
                      Text(
                        tr('Starting at', 'يبدأ من'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF85858B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final time in _times.take(1))
                            InputChip(
                              avatar: const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                              ),
                              label: Text(time.format(context)),
                              onPressed: () async {
                                final selected = await showTimePicker(
                                  context: context,
                                  initialTime: time,
                                );
                                if (selected != null) {
                                  setState(() => _times[0] = selected);
                                }
                              },
                              backgroundColor: const Color(0xFFF0F3FE),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF263B70),
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(
                                'Select one or more times',
                                'اختر موعدًا أو أكثر',
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF85858B),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addTime,
                            icon: const Icon(Icons.add_rounded, size: 17),
                            label: Text(tr('Add time', 'إضافة موعد')),
                            style: TextButton.styleFrom(
                              foregroundColor: _accent,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final time in _times)
                            InputChip(
                              avatar: const Icon(
                                Icons.access_time_rounded,
                                size: 15,
                              ),
                              label: Text(time.format(context)),
                              onDeleted: _times.length == 1
                                  ? null
                                  : () => setState(() => _times.remove(time)),
                              backgroundColor: const Color(0xFFF0F3FE),
                              side: BorderSide.none,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF263B70),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _fieldLabel(tr('Start date', 'تاريخ البداية')),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('Start', 'البداية')),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: () => _pickDate(start: true),
                                child: Text(_dateLabel(_startDate)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(tr('End', 'النهاية')),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: _endDate == null
                                    ? () =>
                                          setState(() => _endDate = _startDate)
                                    : () => _pickDate(start: false),
                                child: Text(
                                  _endDate == null
                                      ? tr('No end date', 'بدون نهاية')
                                      : _dateLabel(_endDate!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _endDate == null
                            ? null
                            : () => setState(() => _endDate = null),
                        child: Text(
                          tr('Remove end date', 'إزالة تاريخ النهاية'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      tr('Intake instructions', 'تعليمات الاستخدام'),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel(tr('Relation to meals', 'العلاقة بالأكل')),
                    const SizedBox(height: 7),
                    _dropdown<String>(
                      value: _relation,
                      values: const [
                        'beforeFood',
                        'afterFood',
                        'withFood',
                        'noPreference',
                      ],
                      label: (v) => switch (v) {
                        'beforeFood' => tr('Before Food', 'قبل الأكل'),
                        'afterFood' => tr('After Food', 'بعد الأكل'),
                        'withFood' => tr('With Food', 'مع الأكل'),
                        _ => tr('No Preference', 'بدون تحديد'),
                      },
                      onChanged: (v) => setState(() => _relation = v),
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(
                      tr('Prescription instructions', 'تعليمات الوصفة'),
                    ),
                    const SizedBox(height: 7),
                    _input(
                      _instructionsController,
                      tr('As prescribed by your clinician', 'حسب وصف الطبيب'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel(tr('Special notes', 'ملاحظات خاصة')),
                    const SizedBox(height: 7),
                    _input(
                      _notesController,
                      tr('Notes from your prescription', 'ملاحظات حسب الوصفة'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr(
                        'Enter instructions as prescribed by your clinician; the app does not determine dosage.',
                        'أدخل التعليمات كما وصفها الطبيب؛ التطبيق لا يحدد الجرعة.',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF85858B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionTitle(
                      tr(
                        'Reminders & caregiver alerts',
                        'التذكيرات وتنبيهات المرافق',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr('Enable medication reminders', 'تفعيل تذكير الدواء'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _reminders,
                      onChanged: (v) => setState(() => _reminders = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        tr(
                          'Notify caregiver if missed',
                          'تنبيه المرافق عند تفويت الجرعة',
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _caregiverAlert,
                      onChanged: widget.canConsent && !_saving
                          ? (v) => setState(() => _caregiverAlert = v)
                          : null,
                    ),
                    if (_caregiverAlert) ...[
                      _fieldLabel(
                        tr('Escalation delay', 'مدة الانتظار قبل التنبيه'),
                      ),
                      const SizedBox(height: 7),
                      _dropdown<int>(
                        enabled: widget.canConsent && !_saving,
                        value: _delay,
                        values: const [15, 30, 60],
                        label: (v) => tr('$v minutes', '$v دقيقة'),
                        onChanged: (v) {
                          if (widget.canConsent && !_saving) {
                            setState(() => _delay = v);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 21),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF171719),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          tr('Save medicine', 'حفظ الدواء'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFF34343A),
    ),
  );

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 1),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -.15,
        color: Color(0xFF171719),
      ),
    ),
  );

  Widget _input(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAB1)),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
    ),
  );
}

class _MedicationTimezoneDialog extends StatefulWidget {
  const _MedicationTimezoneDialog({
    required this.isArabic,
    required this.confirmation,
    this.suggestion,
  });
  final bool isArabic, confirmation;
  final String? suggestion;
  @override
  State<_MedicationTimezoneDialog> createState() =>
      _MedicationTimezoneDialogState();
}

class _MedicationTimezoneDialogState extends State<_MedicationTimezoneDialog> {
  late final _input = TextEditingController(text: widget.suggestion ?? '');
  bool _invalid = false;
  String tr(String en, String ar) => widget.isArabic ? ar : en;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.confirmation
          ? tr('Confirm medication timezone', 'تأكيد المنطقة الزمنية للأدوية')
          : tr('Schedule timezone', 'المنطقة الزمنية للجدول'),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.confirmation
              ? tr(
                  'Confirm your IANA timezone. Existing schedules will not change.',
                  'أكد منطقتك الزمنية بصيغة IANA. الجداول الحالية لن تتغير.',
                )
              : tr(
                  'Enter the patient schedule timezone. This does not confirm the patient’s default.',
                  'أدخل المنطقة الزمنية لجدول المريض. هذا لا يؤكد إعداد المريض الافتراضي.',
                ),
        ),
        TextField(
          controller: _input,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            hintText: 'Region/City',
            errorText: _invalid
                ? tr(
                    'Enter a valid IANA timezone.',
                    'أدخل منطقة زمنية صحيحة بصيغة IANA.',
                  )
                : null,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(tr('Cancel', 'إلغاء')),
      ),
      TextButton(
        onPressed: () {
          if (MedicationTimezone.isValid(_input.text.trim())) {
            Navigator.pop(context, _input.text.trim());
          } else {
            setState(() => _invalid = true);
          }
        },
        child: Text(tr('Confirm', 'تأكيد')),
      ),
    ],
  );
}
