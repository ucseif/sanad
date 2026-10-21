import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/validation/auth_validators.dart';
import '../../../presentation/widgets/auth/auth_header.dart';
import '../../../presentation/widgets/auth/auth_text_field.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.arguments});

  static const routeName = '/login';

  final AuthRouteArguments arguments;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _errorMessage(
    AppLocalizations l10n,
    AuthValidationError? error, {
    required String field,
  }) {
    return switch (error) {
      null => null,
      AuthValidationError.required => l10n.fieldRequired(field),
      AuthValidationError.invalidEmail => l10n.invalidEmailMessage,
      AuthValidationError.invalidPassword => l10n.passwordRequirementsMessage,
      _ => l10n.fieldRequired(field),
    };
  }

  void _validateAndPreview() {
    final l10n = context.l10n;
    final emailError = AuthValidators.validateEmail(_emailController.text);
    final passwordError = AuthValidators.validatePassword(
      _passwordController.text,
    );
    setState(() {
      _emailError = _errorMessage(l10n, emailError, field: l10n.emailLabel);
      _passwordError = _errorMessage(
        l10n,
        passwordError,
        field: l10n.passwordLabel,
      );
    });
    if (emailError != null || passwordError != null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.signInPreviewMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColor.primary,
        ),
      );
  }

  void _clearEmailError(String value) {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearPasswordError(String value) {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthPageLayout(
      header: AuthHeader(
        title: l10n.loginTitle,
        subtitle: l10n.loginSubtitle,
        onBack: () => Navigator.maybePop(context),
        topBarTitle: l10n.appName,
        heroIcon: Icons.monitor_heart_outlined,
        heroLabel: l10n.loginTitle,
        centerTitle: true,
        titleFontSize: 26,
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SanadButton(
            key: const ValueKey('login-submit'),
            label: l10n.signInLabel,
            onPressed: _validateAndPreview,
            fontSize: 15,
            height: 54,
          ),
          const SizedBox(height: 6),
          _Reassurance(text: l10n.privacyReassurance),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  l10n.noAccountPrompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.signup,
                  arguments: widget.arguments,
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.createAccountLabel,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              key: const ValueKey('auth-email-field'),
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: l10n.emailLabel,
              hintText: l10n.exampleEmail,
              labelAbove: true,
              compact: true,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              suffixIcon: const Icon(
                Icons.alternate_email_rounded,
                size: 20,
                color: AppColor.textSecondary,
              ),
              onChanged: _clearEmailError,
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),
            AuthPasswordField(
              key: const ValueKey('auth-password-field'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: l10n.passwordLabel,
              labelAbove: true,
              compact: true,
              showLockIcon: true,
              errorText: _passwordError,
              showPasswordLabel: l10n.showPasswordLabel,
              hidePasswordLabel: l10n.hidePasswordLabel,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onChanged: _clearPasswordError,
              onSubmitted: (_) => _validateAndPreview(),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.comingSoonMessage),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  minimumSize: const Size(48, 40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(
                  l10n.forgotPasswordLabel,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reassurance extends StatelessWidget {
  const _Reassurance({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColor.border.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColor.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 18,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColor.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
