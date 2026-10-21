import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/validation/auth_validators.dart';
import '../../../presentation/widgets/auth/auth_text_field.dart';
import '../../../presentation/widgets/auth/password_requirements.dart';
import 'signup_phone_field.dart';
import 'signup_privacy_reassurance.dart';
import 'signup_terms_field.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({
    super.key,
    required this.l10n,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordFocusNode,
    required this.countryCode,
    required this.nameError,
    required this.phoneError,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.termsError,
    required this.passwordValidation,
    required this.showPasswordRequirements,
    required this.termsAccepted,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onCountryChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onPasswordFocusChanged,
    required this.onConfirmPasswordChanged,
    required this.onTermsChanged,
  });

  final AppLocalizations l10n;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final FocusNode passwordFocusNode;
  final String countryCode;
  final String? nameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? termsError;
  final PasswordValidation passwordValidation;
  final bool showPasswordRequirements;
  final bool termsAccepted;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<bool> onPasswordFocusChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final ValueChanged<bool> onTermsChanged;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            key: const ValueKey('signup-name-field'),
            controller: nameController,
            label: l10n.fullNameLabel,
            hintText: l10n.exampleFullName,
            labelAbove: true,
            compact: true,
            errorText: nameError,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            maxLength: AuthValidators.maxNameLength,
            autofillHints: const [AutofillHints.name],
            suffixIcon: const Icon(
              Icons.badge_outlined,
              size: 20,
              color: AppColor.textSecondary,
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 12),
          SignUpPhoneField(
            countryCode: countryCode,
            phoneController: phoneController,
            label: l10n.phoneLabel,
            hintText: l10n.examplePhoneNumber,
            countryCodeLabel: l10n.countryCodeLabel,
            errorText: phoneError,
            onCountryChanged: onCountryChanged,
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            key: const ValueKey('signup-email-field'),
            controller: emailController,
            label: l10n.emailLabel,
            hintText: l10n.exampleEmail,
            labelAbove: true,
            compact: true,
            errorText: emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            suffixIcon: const Icon(
              Icons.alternate_email_rounded,
              size: 20,
              color: AppColor.textSecondary,
            ),
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            key: const ValueKey('signup-password-field'),
            controller: passwordController,
            focusNode: passwordFocusNode,
            label: l10n.passwordLabel,
            labelAbove: true,
            compact: true,
            errorText: passwordError,
            showPasswordLabel: l10n.showPasswordLabel,
            hidePasswordLabel: l10n.hidePasswordLabel,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: onPasswordChanged,
            onFocusChanged: onPasswordFocusChanged,
          ),
          PasswordRequirements(
            validation: passwordValidation,
            visible: showPasswordRequirements,
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            key: const ValueKey('signup-confirm-password-field'),
            controller: confirmPasswordController,
            label: l10n.confirmPasswordLabel,
            labelAbove: true,
            compact: true,
            errorText: confirmPasswordError,
            showPasswordLabel: l10n.showPasswordLabel,
            hidePasswordLabel: l10n.hidePasswordLabel,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: onConfirmPasswordChanged,
          ),
          const SizedBox(height: 8),
          SignUpPrivacyReassurance(text: l10n.privacyReassurance),
          const SizedBox(height: 6),
          SignUpTermsField(
            key: const ValueKey('signup-terms-field'),
            accepted: termsAccepted,
            label: l10n.termsAcknowledgement,
            errorText: termsError,
            onChanged: onTermsChanged,
          ),
        ],
      ),
    );
  }
}
