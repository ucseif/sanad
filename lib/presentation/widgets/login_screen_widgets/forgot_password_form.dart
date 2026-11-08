import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared_widgets/auth_screen_styles.dart';
import 'login_screen_action_button.dart';
import '../shared_widgets/auth_form_input.dart';

class ForgotPasswordForm extends StatelessWidget {
  final bool isArabic, loading;
  final TextEditingController email;
  final bool emailError;
  final int emailShake;
  final VoidCallback onBack, onSubmit;
  const ForgotPasswordForm({
    super.key,
    required this.isArabic,
    required this.loading,
    required this.email,
    this.emailError = false,
    this.emailShake = 0,
    required this.onBack,
    required this.onSubmit,
  });
  @override
  Widget build(BuildContext context) {
    final t = isArabic ? GoogleFonts.tajawal : GoogleFonts.plusJakartaSans;
    return Column(
      key: const ValueKey('forgot'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
          style: t(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: context.sanadText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isArabic
              ? 'أدخل بريد الحساب. إذا كان مؤهلاً سنطلب إرسال كود عبر واتساب.'
              : 'Enter your account email. If eligible, WhatsApp code delivery will be requested.',
          style: t(fontSize: 16, color: context.sanadDim, height: 1.5),
        ),
        const SizedBox(height: 40),
        AuthFormInput(
          label: isArabic ? 'البريد الإلكتروني' : 'Email',
          controller: email,
          isArabic: isArabic,
          icon: Icons.mail_outline_rounded,
          error: emailError,
          hint: 'name@example.com',
        ),
        const SizedBox(height: 32),
        LoginScreenActionButton(
          text: isArabic ? 'إرسال الكود' : 'Send Code',
          loading: loading,
          onTap: onSubmit,
          isArabic: isArabic,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              isArabic ? 'رجوع' : 'Back',
              style: t(color: context.sanadDim, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
