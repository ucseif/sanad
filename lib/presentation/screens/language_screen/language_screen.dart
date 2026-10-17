import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_scope.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/onboarding_illustrations.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  static const routeName = '/language';

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  Locale _selectedLocale = const Locale('ar');
  bool _localeInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      _selectedLocale = context.localeController.locale;
      _localeInitialized = true;
    }
  }

  Future<void> _select(Locale locale) async {
    if (_selectedLocale == locale) return;
    setState(() => _selectedLocale = locale);
    await context.localeController.setLocale(locale);
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth * 0.52)
                          .clamp(170.0, 230.0)
                          .toDouble(),
                      maxHeight: compact ? 36 : 56,
                    ),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        AppAssets.sanadLogo,
                        fit: BoxFit.contain,
                        semanticLabel: 'SANAD logo',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 21),
                LanguageIllustration(
                  label: l10n.languageVisualLabel,
                  height: compact ? 100 : 144,
                ),
                SizedBox(height: compact ? 6 : 17),
                Text(
                  l10n.chooseAppLanguage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: compact ? 5 : 7),
                Text(
                  l10n.languageSettingsHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: compact ? 8 : 19),
                _LanguageOption(
                  key: const ValueKey('language-option-ar'),
                  locale: const Locale('ar'),
                  title: l10n.arabic,
                  subtitle: l10n.arabicInterface,
                  compact: compact,
                  selected: _selectedLocale.languageCode == 'ar',
                  onTap: () => _select(const Locale('ar')),
                ),
                SizedBox(height: compact ? 6 : 10),
                _LanguageOption(
                  key: const ValueKey('language-option-en'),
                  locale: const Locale('en'),
                  title: l10n.english,
                  subtitle: l10n.englishInterface,
                  compact: compact,
                  selected: _selectedLocale.languageCode == 'en',
                  onTap: () => _select(const Locale('en')),
                ),
                if (!compact) const Spacer(),
                SizedBox(height: compact ? 8 : 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: AppColor.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l10n.languageProtected,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 7 : 13),
                SanadButton(label: l10n.continueLabel, onPressed: _continue),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                18,
                compact ? 4 : 8,
                18,
                compact ? 6 : 14,
              ),
              child: compact
                  ? content
                  : SizedBox(
                      height: constraints.maxHeight - 22,
                      child: content,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    super.key,
    required this.locale,
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final String title;
  final String subtitle;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = locale.languageCode == 'ar';
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: BoxConstraints(minHeight: compact ? 72 : 80),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: compact ? 11 : 13,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColor.surfaceMuted : AppColor.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColor.border : AppColor.surface,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 42 : 44,
                height: compact ? 42 : 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColor.primary : AppColor.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'ع' : 'Aa',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColor.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: compact ? 18 : 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColor.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColor.primary : AppColor.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
