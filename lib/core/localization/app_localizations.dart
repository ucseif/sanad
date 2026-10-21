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
  String get sanadLogoLabel => isArabic ? 'شعار سند' : 'SANAD logo';
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
  String get back => isArabic ? 'رجوع' : 'Back';
  String get roleTitle =>
      isArabic ? 'اختر صفتك للمتابعة' : 'Choose Your Role to Continue';
  String get roleSubtitle => isArabic
      ? 'سنخصص تجربة سند بما يناسب احتياجاتك اليومية.'
      : "We'll tailor your SANAD experience around your daily needs.";
  String get patient => isArabic ? 'المريض' : 'Patient';
  String get patientDescription => isArabic
      ? 'تابع صحتك واتصل بجهاز سند القابل للارتداء.'
      : 'Monitor your health and connect your SANAD wearable.';
  String get patientChip =>
      isArabic ? 'المزامنة مع الجهاز نشطة' : 'Wearable Sync Active';
  String get caregiver => isArabic ? 'مقدم الرعاية' : 'Caregiver';
  String get caregiverDescription => isArabic
      ? 'ابقَ على اتصال وادعم الشخص الذي ترعاه.'
      : 'Stay connected and support the person you care for.';
  String get caregiverChip =>
      isArabic ? 'وصول العائلة إلى البيانات' : 'Family Telemetry Access';
  String get privacyTitle =>
      isArabic ? 'خصوصية وأمان البيانات' : 'Privacy & Data Security';
  String get privacySubtitle => isArabic
      ? 'وصول آمن إلى بياناتك الطبية.'
      : 'Secure access to your medical data.';
  String get roleHelper => isArabic
      ? 'يمكنك ربط الأدوار أو التبديل بينها في أي وقت.'
      : 'You can link or switch roles anytime.';
  String stepLabel(int step) =>
      isArabic ? 'الخطوة $step من 5' : 'Step $step of 5';
  String get homeTitle => isArabic ? 'مرحبًا بك في سند' : 'Welcome to SANAD';
  String get homeSubtitle => isArabic
      ? 'تطبيق رعاية متصل بالمرضى وعائلاتهم'
      : 'Connected care for patients and their families';

  String get loginTitle => isArabic ? 'مرحبًا بعودتك' : 'Welcome back';
  String get loginSubtitle => isArabic
      ? 'سجل الدخول لمتابعة صحتك أو صحة من تحب.'
      : 'Sign in to monitor your health or a loved one.';
  String get createAccountTitle => isArabic ? 'إنشاء حساب' : 'Create account';
  String get signupWelcomeTitle =>
      isArabic ? 'إنشاء حساب جديد' : 'Create a new account';
  String get createAccountSubtitle => isArabic
      ? 'ابقَ على اتصال بمن يهتمون بك.'
      : 'Stay connected with the people who care.';
  String get exampleFullName => isArabic ? 'سارة أحمد' : 'Sarah Ahmed';
  String get examplePhoneNumber => isArabic ? '010 1234 5678' : '10 1234 5678';
  String get exampleEmail => isArabic ? 'name@example.com' : 'name@example.com';
  String get emailLabel => isArabic ? 'البريد الإلكتروني' : 'Email address';
  String get passwordLabel => isArabic ? 'كلمة المرور' : 'Password';
  String get confirmPasswordLabel =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm password';
  String get fullNameLabel => isArabic ? 'الاسم بالكامل' : 'Full name';
  String get phoneLabel => isArabic ? 'رقم الهاتف' : 'Phone number';
  String get countryCodeLabel => isArabic ? 'رمز الدولة' : 'Country code';
  String get signInLabel => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get createAccountLabel => isArabic ? 'إنشاء حساب' : 'Create account';
  String get forgotPasswordLabel =>
      isArabic ? 'هل نسيت كلمة المرور؟' : 'Forgot password?';
  String get noAccountPrompt =>
      isArabic ? 'ليس لديك حساب؟' : 'Don’t have an account?';
  String get alreadyHaveAccountPrompt =>
      isArabic ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get privacyReassurance => isArabic
      ? 'خصوصيتك وأمان بياناتك من أولوياتنا'
      : 'Your privacy and data security matter to us';
  String get termsAcknowledgement => isArabic
      ? 'أوافق على الشروط وسياسة الخصوصية'
      : 'I agree to the Terms and Privacy Policy';
  String get signInPreviewMessage => isArabic
      ? 'سيتم ربط تسجيل الدخول لاحقًا. لم يتم إنشاء جلسة دخول.'
      : 'Sign-in will be connected later. No account session was created.';
  String get comingSoonMessage =>
      isArabic ? 'هذه الميزة ستتوفر قريبًا.' : 'This feature is coming soon.';
  String fieldRequired(String field) =>
      isArabic ? 'يرجى إدخال $field.' : '$field is required.';
  String get invalidEmailMessage => isArabic
      ? 'أدخل بريدًا إلكترونيًا صالحًا.'
      : 'Enter a valid email address.';
  String get invalidPhoneMessage =>
      isArabic ? 'أدخل رقم هاتف صالحًا.' : 'Enter a valid phone number.';
  String get nameTooLongMessage => isArabic
      ? 'يجب ألا يتجاوز الاسم 80 حرفًا.'
      : 'Name must be 80 characters or fewer.';
  String get passwordRequirementsMessage => isArabic
      ? 'يجب استيفاء متطلبات كلمة المرور.'
      : 'Meet all password requirements.';
  String get passwordMismatchMessage =>
      isArabic ? 'كلمتا المرور غير متطابقتين.' : 'Passwords do not match.';
  String get termsRequiredMessage => isArabic
      ? 'يرجى الموافقة قبل المتابعة.'
      : 'Please agree before continuing.';
  String get passwordMinimumLength =>
      isArabic ? '9 أحرف على الأقل' : 'At least 9 characters';
  String get passwordUppercase =>
      isArabic ? 'حرف كبير (A–Z)' : 'One uppercase letter';
  String get passwordLowercase =>
      isArabic ? 'حرف صغير (a–z)' : 'One lowercase letter';
  String get passwordDigit => isArabic ? 'رقم واحد على الأقل' : 'One number';
  String get passwordSpecialCharacter =>
      isArabic ? 'رمز خاص مثل @ أو # أو \$' : 'One special character';
  String get passwordStrengthLabel =>
      isArabic ? 'قوة كلمة المرور' : 'Password strength';
  String get passwordStrengthWeak => isArabic ? 'ضعيفة' : 'Weak';
  String get passwordStrengthMedium => isArabic ? 'متوسطة' : 'Medium';
  String get passwordStrengthStrong => isArabic ? 'قوية' : 'Strong';
  String get showPasswordLabel =>
      isArabic ? 'إظهار كلمة المرور' : 'Show password';
  String get hidePasswordLabel =>
      isArabic ? 'إخفاء كلمة المرور' : 'Hide password';
  String get roleContextLabel => isArabic ? 'الدور المختار' : 'Selected role';
  String get selectedEmailLabel =>
      isArabic ? 'البريد المختار' : 'Selected email';
  String get verificationMethodTitle =>
      isArabic ? 'اختر طريقة التحقق' : 'Choose a verification method';
  String get verificationAppBarTitle =>
      isArabic ? 'التحقق من الرمز' : 'OTP Verification';
  String get verificationMethodSubtitle => isArabic
      ? 'اختر الطريقة التي سنستخدمها في تجربة التحقق الحالية.'
      : 'Choose how the current verification preview should continue.';
  String get emailVerificationOption =>
      isArabic ? 'التحقق عبر البريد الإلكتروني' : 'Email verification';
  String get emailVerificationDescription => isArabic
      ? 'سنستخدم بريدك الإلكتروني في تجربة التحقق.'
      : 'Use your email address for the verification preview.';
  String get smsVerificationOption =>
      isArabic ? 'التحقق عبر الرسائل النصية' : 'SMS verification';
  String get smsVerificationDescription => isArabic
      ? 'التحقق عبر الرسائل النصية غير متاح في هذه المرحلة.'
      : 'SMS verification is not available in this stage.';
  String get smsNotAvailableShort =>
      isArabic ? 'غير متاح حاليًا' : 'Not available yet';
  String get unavailableSmsMessage => isArabic
      ? 'التحقق عبر الرسائل النصية غير متاح حاليًا. يمكنك المتابعة باستخدام البريد الإلكتروني.'
      : 'SMS verification is not available yet. Please continue using email verification.';
  String get verificationPreviewNotice => isArabic
      ? 'هذه معاينة لواجهة التحقق فقط؛ لم يتم إرسال رمز.'
      : 'This is a verification UI preview; no code has been sent.';
  String get continueWithEmailLabel =>
      isArabic ? 'المتابعة بالبريد الإلكتروني' : 'Continue with email';
  String get otpTitle =>
      isArabic ? 'أدخل رمز التحقق' : 'Enter verification code';
  String get otpSubtitle => isArabic
      ? 'أدخل الرمز المكوّن من 6 أرقام في واجهة المعاينة.'
      : 'Enter the 6-digit code in this verification preview.';
  String get otpCodeLabel => isArabic ? 'رمز التحقق' : 'Verification code';
  String get otpIncompleteMessage => isArabic
      ? 'أدخل رمز التحقق المكوّن من 6 أرقام.'
      : 'Enter the 6-digit verification code.';
  String get otpNotConnectedMessage => isArabic
      ? 'سيتم ربط التحقق الحقيقي لاحقًا. لم يتم التحقق من الرمز.'
      : 'Real verification will be connected later. The code was not verified.';
  String get otpResendUnavailable => isArabic
      ? 'إعادة الإرسال غير متاحة حتى يتم ربط مزود تحقق حقيقي.'
      : 'Resend is unavailable until a real verification provider is connected.';
  String get verifyLabel => isArabic ? 'تحقق' : 'Verify';
  String get verificationIllustrationLabel =>
      isArabic ? 'رمز تحقق عبر البريد الإلكتروني' : 'Email verification code';
  String otpDigitLabel(int index) => isArabic
      ? 'الرقم ${index + 1} من رمز التحقق'
      : 'Verification code digit ${index + 1}';

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
