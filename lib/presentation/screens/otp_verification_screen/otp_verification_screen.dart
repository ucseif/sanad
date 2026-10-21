import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/masked_email.dart';
import '../../../presentation/widgets/auth/auth_header.dart';
import '../../../presentation/widgets/auth/otp_input.dart';
import '../../../presentation/widgets/sanad_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.arguments});

  static const routeName = '/otp-verification';

  final AuthRouteArguments arguments;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';
  String? _errorText;

  void _verifyPreview() {
    final l10n = context.l10n;
    if (_code.length != 6) {
      setState(() => _errorText = l10n.otpIncompleteMessage);
      return;
    }
    setState(() => _errorText = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.otpNotConnectedMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColor.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPageLayout(
      header: AuthHeader(
        title: l10n.otpTitle,
        subtitle: l10n.otpSubtitle,
        onBack: () => Navigator.maybePop(context),
        topBarTitle: l10n.verificationAppBarTitle,
        trailingIcon: Icons.person_outline_rounded,
        heroIcon: Icons.password_rounded,
        heroLabel: l10n.verificationIllustrationLabel,
        centerTitle: true,
        titleFontSize: 24,
      ),
      footer: SanadButton(
        key: const ValueKey('otp-verify-submit'),
        label: l10n.verifyLabel,
        onPressed: _verifyPreview,
        fontSize: 15,
        height: 54,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: AppColor.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alternate_email_rounded,
                  size: 19,
                  color: AppColor.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    maskEmail(widget.arguments.email),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColor.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.verificationPreviewNotice,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.otpCodeLabel,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppColor.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 7),
          OtpInput(
            key: const ValueKey('otp-input'),
            errorText: _errorText,
            digitLabel: l10n.otpDigitLabel,
            onChanged: (value) => setState(() {
              _code = value;
              if (value.length == 6) _errorText = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_clock_outlined,
                size: 18,
                color: AppColor.mutedText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  l10n.otpResendUnavailable,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColor.mutedText,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
