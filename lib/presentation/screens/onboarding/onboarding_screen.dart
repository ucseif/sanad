import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/onboarding_illustrations.dart';
import '../../../presentation/widgets/sanad_brand.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 5;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.pushNamed(context, AppRoutes.roleSelection);
  }

  Future<void> _next() async {
    if (_currentPage == _pageCount - 1) {
      _finish();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _buildPages(l10n);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 680;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 0),
                  child: SanadTopBar(
                    stepLabel: l10n.stepLabel(_currentPage + 1),
                    skipLabel: l10n.skip,
                    onSkip: _finish,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) =>
                        _OnboardingPage(data: pages[index], compact: compact),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    22,
                    0,
                    22,
                    compact ? 10 : 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PageDots(activeIndex: _currentPage),
                      const SizedBox(height: 14),
                      SanadButton(
                        label: _currentPage == _pageCount - 1
                            ? l10n.getStarted
                            : l10n.next,
                        onPressed: _next,
                        fontSize: 19,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_OnboardingData> _buildPages(AppLocalizations l10n) {
    return [
      _OnboardingData(
        title: l10n.onboardingWelcomeTitle,
        body: l10n.onboardingWelcomeBody,
        kind: OnboardingIllustrationKind.welcome,
      ),
      _OnboardingData(
        title: l10n.onboardingMonitoringTitle,
        body: l10n.onboardingMonitoringBody,
        kind: OnboardingIllustrationKind.monitoring,
      ),
      _OnboardingData(
        title: l10n.onboardingDetectionTitle,
        body: l10n.onboardingDetectionBody,
        kind: OnboardingIllustrationKind.detection,
      ),
      _OnboardingData(
        title: l10n.onboardingFamilyTitle,
        body: l10n.onboardingFamilyBody,
        kind: OnboardingIllustrationKind.family,
      ),
      _OnboardingData(
        title: l10n.onboardingIdTitle,
        body: l10n.onboardingIdBody,
        kind: OnboardingIllustrationKind.medicalId,
      ),
    ];
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.body,
    required this.kind,
  });

  final String title;
  final String body;
  final OnboardingIllustrationKind kind;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.compact});

  final _OnboardingData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final illustrationHeight = (constraints.maxHeight * .45)
              .clamp(205.0, compact ? 215.0 : 238.0)
              .toDouble();
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnboardingIllustration(
                kind: data.kind,
                compact: compact,
                height: illustrationHeight,
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColor.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Text(
                  data.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 19,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          );
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: content),
            ),
          );
        },
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == activeIndex ? 22 : 7,
          height: 6,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? AppColor.indicatorActive
                : AppColor.indicatorInactive,
            borderRadius: BorderRadius.circular(7),
          ),
        ),
      ),
    );
  }
}
