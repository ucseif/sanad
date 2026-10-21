import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/masked_email.dart';
import '../../../presentation/widgets/auth/auth_header.dart';
import '../../../presentation/widgets/auth/verification_method_card.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class VerificationMethodScreen extends StatefulWidget {
  const VerificationMethodScreen({super.key, required this.arguments});

  static const routeName = '/verification-method';

  final AuthRouteArguments arguments;

  @override
  State<VerificationMethodScreen> createState() =>
      _VerificationMethodScreenState();
}

class _VerificationMethodScreenState extends State<VerificationMethodScreen> {
  void _showSmsUnavailable() {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.unavailableSmsMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColor.primary,
        ),
      );
  }

  void _continueWithEmail() {
    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: widget.arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maskedEmail = maskEmail(widget.arguments.email);
    return AuthPageLayout(
      header: AuthHeader(
        title: l10n.verificationMethodTitle,
        subtitle: l10n.verificationMethodSubtitle,
        onBack: () => Navigator.maybePop(context),
        topBarTitle: l10n.verificationAppBarTitle,
        trailingIcon: Icons.person_outline_rounded,
        heroIcon: Icons.shield_outlined,
        centerTitle: true,
        titleFontSize: 24,
      ),
      footer: SanadButton(
        key: const ValueKey('verification-continue'),
        label: l10n.continueWithEmailLabel,
        onPressed: _continueWithEmail,
        fontSize: 15,
        height: 54,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerificationMethodCard(
            key: const ValueKey('sms-method-card'),
            title: l10n.smsVerificationOption,
            description: l10n.smsVerificationDescription,
            unavailableLabel: l10n.smsNotAvailableShort,
            icon: Icons.sms_outlined,
            selected: false,
            available: false,
            onTap: _showSmsUnavailable,
          ),
          const SizedBox(height: 12),
          VerificationMethodCard(
            key: const ValueKey('email-method-card'),
            title: l10n.emailVerificationOption,
            description: l10n.emailVerificationDescription,
            valueText: maskedEmail,
            icon: Icons.alternate_email_rounded,
            selected: true,
            available: true,
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 11, 14, 11),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColor.border.withValues(alpha: 0.8),
                width: 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 19,
                  color: AppColor.textSecondary,
                ),
                const SizedBox(width: 9),
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
          ),
        ],
      ),
    );
  }
}
