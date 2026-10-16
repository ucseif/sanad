import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  static const supportedLocales = [Locale('ar'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations is missing from the widget tree.');
    return value!;
  }

  String get appName => 'SANAD';
  String get chooseAppLanguage =>
      isArabic ? 'اختر لغة التطبيق' : 'Choose App Language';
  String get languageSettingsHint => isArabic
      ? 'يمكنك تغيير اللغة في أي وقت من الإعدادات'
      : 'You can change this anytime in Settings';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get arabicInterface =>
      isArabic ? 'العربية (الخليجية والفصحى)' : 'Arabic (Gulf & Classical)';
  String get englishInterface =>
      isArabic ? 'الإنجليزية (الدولية)' : 'English (International)';
  String get languageProtected => isArabic
      ? 'محمي بمعايير سيادة البيانات الطبية'
      : 'Protected by medical-grade data sovereignty';
  String get splashCopyrightEnglish => '© 2026 SANAD. All rights reserved.';
  String get splashCopyrightArabic => '© ٢٠٢٦ سند. جميع الحقوق محفوظة.';
  String get languageVisualLabel =>
      isArabic ? 'تجربة سريرية ثنائية اللغة' : 'Bilingual clinical experience';
  String get continueLabel => isArabic ? 'متابعة' : 'Continue';
  String stepLabel(int step) =>
      isArabic ? 'الخطوة $step من 5' : 'Step $step of 5';
  String get homeTitle => isArabic ? 'مرحبًا بك في سند' : 'Welcome to SANAD';
  String get homeSubtitle => isArabic
      ? 'تطبيق رعاية متصل بالمرضى وعائلاتهم'
      : 'Connected care for patients and their families';

  String get skip => isArabic ? 'تخطي' : 'Skip';
  String get next => isArabic ? 'التالي' : 'Next';
  String get getStarted => isArabic ? 'ابدأ الآن' : 'Get Started';
  String get onboardingWelcomeTitle =>
      isArabic ? 'رعايتك، في كل لحظة.' : 'Care That Stays With You.';

  String get onboardingWelcomeBody => isArabic
      ? 'سند يساعدك على متابعة صحتك وفهم حالتك والبقاء على اتصال بمن يهتمون بك.'
      : 'SANAD helps you stay aware of your health, understand your condition, and stay connected with those who care.';

  String get onboardingMonitoringTitle =>
      isArabic ? 'صحتك تحت المتابعة دائمًا.' : 'Your Health, Always in View.';

  String get onboardingMonitoringBody => isArabic
      ? 'تابع نبض القلب، مستوى الأكسجين، والنشاط اليومي بسهولة طوال اليوم.'
      : 'Track your heart rate, oxygen level, and daily activity throughout the day.';

  String get onboardingDetectionTitle => isArabic
      ? 'نفهم ما يحدث، لا نكتفي باكتشافه.'
      : 'More Than Just Detection.';

  String get onboardingDetectionBody => isArabic
      ? 'سند يحلل الحركة والمؤشرات الصحية لفهم الموقف وإرسال التنبيه المناسب عند الحاجة.'
      : 'SANAD analyzes movement and health signals to understand what is happening and alert the right people when needed.';

  String get onboardingFamilyTitle =>
      isArabic ? 'دائمًا قريب ممن يهتمون بك.' : 'Stay Close to Those Who Care.';

  String get onboardingFamilyBody => isArabic
      ? 'شارك حالتك وموقعك والتنبيهات المهمة مع عائلتك أو مقدم الرعاية وقت الحاجة.'
      : 'Share your status, location, and important alerts with family or caregivers when it matters most.';

  String get onboardingIdTitle => isArabic
      ? 'معلوماتك الطبية وقت الطوارئ.'
      : 'Your Medical Info, When It Matters.';

  String get onboardingIdBody => isArabic
      ? 'يمكن الوصول إلى معلوماتك الطبية الأساسية بسرعة عبر NFC أو QR في حالات الطوارئ.'
      : 'Give first responders quick access to essential medical information through NFC or QR in an emergency.';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
