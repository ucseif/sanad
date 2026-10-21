import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color.dart';
import '../shared_widgets/app_back_button.dart';
import 'login_screen_styles.dart';
import 'login_screen_action_button.dart';
import 'login_screen_input.dart';
import 'login_screen_input_formatters.dart';
import 'login_screen_status_dots.dart';

class RegisterForm extends StatelessWidget {
  final int regStep;
  final VoidCallback onStepNext, onStepBack;
  final bool isArabic,
      loading,
      obscure,
      obscureConfirm,
      hasUpper,
      hasNum,
      hasSpec,
      hasMinLen,
      passMatch,
      agreeTerms;
  final String? selectedGov, selectedCountry, selectedCountryCode;
  final int expectedPhoneLength;
  final TextEditingController first,
      last,
      username,
      email,
      phone,
      address,
      password,
      confirm;
  final bool usernameError, emailError;
  final int usernameShake, emailShake;
  final bool usernameChecking, emailChecking;
  final String? usernameHint, emailHint;
  final bool? usernameTaken, emailTaken;
  final VoidCallback onToggle,
      onToggleObscure,
      onToggleConfirm,
      onGovTap,
      onCountryTap,
      onCountryCodeTap;
  final Function(bool) onAgreeToggle;
  const RegisterForm({
    required this.regStep,
    required this.onStepNext,
    required this.onStepBack,
    required this.isArabic,
    required this.loading,
    required this.first,
    required this.last,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
    required this.confirm,
    required this.onToggle,
    this.selectedGov,
    this.selectedCountry,
    this.selectedCountryCode,
    required this.expectedPhoneLength,
    required this.agreeTerms,
    required this.onAgreeToggle,
    required this.onToggleObscure,
    required this.onToggleConfirm,
    required this.onGovTap,
    required this.onCountryTap,
    required this.onCountryCodeTap,
    required this.hasUpper,
    required this.hasNum,
    required this.hasSpec,
    required this.hasMinLen,
    required this.passMatch,
    required this.obscure,
    required this.obscureConfirm,
    this.usernameError = false,
    this.emailError = false,
    this.usernameShake = 0,
    this.emailShake = 0,
    this.usernameChecking = false,
    this.emailChecking = false,
    this.usernameHint,
    this.emailHint,
    this.usernameTaken,
    this.emailTaken,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final bool isCompact = MediaQuery.sizeOf(context).height < 720;
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    final String title = switch (regStep) {
      0 => isArabic ? 'أهلاً بك، ابدأ ببريدك' : 'Welcome, Start with email',
      1 => isArabic ? 'اسم المستخدم' : 'Choose username',
      2 => isArabic ? 'ما هو اسمك؟' : 'What is your name?',
      3 => isArabic ? 'كلمة المرور' : 'Secure account',
      4 => isArabic ? 'رقم الهاتف' : 'Phone number',
      5 => isArabic ? 'أين تسكن؟' : 'Where do you live?',
      6 => isArabic ? 'الخطوة الأخيرة' : 'Almost there',
      _ => '',
    };
    bool canNext = switch (regStep) {
      0 => email.text.contains('@') && emailTaken == false,
      1 => username.text.length >= 3 && usernameTaken == false,
      2 => first.text.isNotEmpty && last.text.isNotEmpty,
      3 => passMatch && hasMinLen,
      4 => phone.text.trim().length == expectedPhoneLength,
      5 => selectedCountry != null && selectedGov != null,
      6 => address.text.isNotEmpty,
      _ => false,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppBackButton(
                onPressed: onStepBack,
                tooltip: isArabic ? 'رجوع' : 'Back',
                buttonSize: 40,
                imageSize: 14,
                borderColor: context.sanadBorder,
                foregroundColor: context.sanadText,
              ),
              Row(
                children: List.generate(
                  7,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: i == regStep ? 24 : 10,
                    height: 4,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: i <= regStep
                          ? context.sanadText
                          : context.sanadBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isKeyboardVisible ? 0.3 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: context.sanadText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'يرجى إكمال البيانات للمتابعة'
                      : 'Please complete the details to continue',
                  style: t(fontSize: 15, color: context.sanadDim),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isKeyboardVisible ? 12 : (isCompact ? 18 : 32)),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: AlignmentDirectional.topCenter,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: _buildForm(context),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            12,
            28,
            isKeyboardVisible ? 12 : (isCompact ? 16 : 24),
          ),
          child: GestureDetector(
            onTap: canNext ? onStepNext : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: canNext ? 1.0 : 0.3,
              child: Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  color: context.sanadText,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.loginShadow,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    regStep == 6
                        ? (isArabic ? 'إنهاء التسجيل' : 'Finish')
                        : (isArabic ? 'التالي' : 'Next'),
                    style: t(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.isDark
                          ? AppColor.loginActionForegroundDarkTheme
                          : AppColor.loginActionForegroundLightTheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        key: ValueKey(regStep),
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (regStep) {
            0 => LoginScreenInput(
              label: isArabic ? 'البريد' : 'Email',
              controller: email,
              isArabic: isArabic,
              icon: Icons.mail_outline_rounded,
              error: emailError,
              helperText: emailHint,
              helperColor: emailTaken == true
                  ? AppColor.loginError
                  : AppColor.loginAvailable,
              hint: 'example@email.com',
            ),
            1 => LoginScreenInput(
              label: isArabic ? 'اسم المستخدم' : 'Username',
              controller: username,
              isArabic: isArabic,
              icon: Icons.alternate_email_rounded,
              error: usernameError,
              helperText: usernameHint,
              helperColor: usernameTaken == true
                  ? AppColor.loginError
                  : AppColor.loginAvailable,
              suffix: usernameChecking
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: context.sanadDim,
                        ),
                      ),
                    )
                  : null,
              hint: isArabic ? 'مثال: sara_ahmed' : 'e.g. sara_ahmed',
            ),
            2 => Column(
              children: [
                LoginScreenInput(
                  label: isArabic ? 'الاسم الأول' : 'First Name',
                  controller: first,
                  isArabic: isArabic,
                  icon: Icons.person_outline_rounded,
                  hint: 'Ahmed',
                ),
                const SizedBox(height: 20),
                LoginScreenInput(
                  label: isArabic ? 'الاسم الأخير' : 'Last Name',
                  controller: last,
                  isArabic: isArabic,
                  icon: Icons.person_outline_rounded,
                  hint: 'Mostafa',
                ),
              ],
            ),
            3 => Column(
              children: [
                LoginScreenInput(
                  label: isArabic ? 'كلمة المرور' : 'Password',
                  controller: password,
                  obscure: obscure,
                  isArabic: isArabic,
                  icon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  extraLabel: LoginScreenStatusDots(
                    status: [hasMinLen, hasUpper, hasNum, hasSpec],
                  ),
                  hint: '********',
                ),
                const SizedBox(height: 20),
                LoginScreenInput(
                  label: isArabic ? 'التأكيد' : 'Confirm',
                  controller: confirm,
                  obscure: obscureConfirm,
                  isArabic: isArabic,
                  icon: Icons.password_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: onToggleConfirm,
                  ),
                  hint: '********',
                ),
              ],
            ),
            4 => LoginScreenInput(
              label: isArabic ? 'رقم الهاتف' : 'Phone',
              controller: phone,
              isArabic: isArabic,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(expectedPhoneLength),
                NoLeadingZeroFormatter(),
              ],
              hint: isArabic
                  ? 'أدخل $expectedPhoneLength أرقام'
                  : 'Enter $expectedPhoneLength digits',
              prefix: GestureDetector(
                onTap: onCountryCodeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: context.sanadBorder, width: 1.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCountryCode ?? '+20',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            5 => Column(
              children: [
                GestureDetector(
                  onTap: onCountryTap,
                  child: AbsorbPointer(
                    child: LoginScreenInput(
                      label: isArabic ? 'الدولة' : 'Country',
                      controller: TextEditingController(text: selectedCountry),
                      isArabic: isArabic,
                      icon: Icons.public_rounded,
                      hint: 'Select Country',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onGovTap,
                  child: AbsorbPointer(
                    child: LoginScreenInput(
                      label: isArabic ? 'المنطقة' : 'Area',
                      controller: TextEditingController(text: selectedGov),
                      isArabic: isArabic,
                      icon: Icons.explore_outlined,
                      hint: 'Select Area',
                    ),
                  ),
                ),
              ],
            ),
            6 => LoginScreenInput(
              label: isArabic ? 'العنوان' : 'Address',
              controller: address,
              isArabic: isArabic,
              icon: Icons.location_on_outlined,
              hint: isArabic ? 'اكتب عنوانك بالتفصيل' : 'Enter your address',
              maxLines: 1,
            ),
            _ => const SizedBox(),
          },
        ],
      ),
    );
  }
}
