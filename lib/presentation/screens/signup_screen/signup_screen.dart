import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/auth/validation/auth_validators.dart';
import '../../../presentation/widgets/auth/auth_header.dart';
import '../../../utils/routes.dart';
import '../../widgets/signup_screen_widgets/signup_footer.dart';
import '../../widgets/signup_screen_widgets/signup_form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.arguments});

  static const routeName = '/signup';

  final AuthRouteArguments arguments;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  String _countryCode = AppConstants.defaultCountryCallingCode;
  bool _termsAccepted = false;
  bool _passwordFocused = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  String? _fieldError(
    AppLocalizations l10n,
    AuthValidationError? error, {
    required String field,
  }) {
    return switch (error) {
      null => null,
      AuthValidationError.required => l10n.fieldRequired(field),
      AuthValidationError.invalidEmail => l10n.invalidEmailMessage,
      AuthValidationError.invalidPhone => l10n.invalidPhoneMessage,
      AuthValidationError.tooLong => l10n.nameTooLongMessage,
      AuthValidationError.invalidPassword => l10n.passwordRequirementsMessage,
      AuthValidationError.passwordMismatch => l10n.passwordMismatchMessage,
    };
  }

  void _validateAndContinue() {
    final l10n = context.l10n;
    final nameError = AuthValidators.validateFullName(_nameController.text);
    final phoneError = AuthValidators.validatePhone(
      _countryCode,
      _phoneController.text,
    );
    final emailError = AuthValidators.validateEmail(_emailController.text);
    final passwordError = AuthValidators.validatePassword(
      _passwordController.text,
    );
    final confirmError = AuthValidators.validateConfirmation(
      password: _passwordController.text,
      confirmation: _confirmPasswordController.text,
    );
    final termsError = _termsAccepted ? null : AuthValidationError.required;

    setState(() {
      _nameError = _fieldError(l10n, nameError, field: l10n.fullNameLabel);
      _phoneError = _fieldError(l10n, phoneError, field: l10n.phoneLabel);
      _emailError = _fieldError(l10n, emailError, field: l10n.emailLabel);
      _passwordError = _fieldError(
        l10n,
        passwordError,
        field: l10n.passwordLabel,
      );
      _confirmPasswordError = _fieldError(
        l10n,
        confirmError,
        field: l10n.confirmPasswordLabel,
      );
      _termsError = termsError == null ? null : l10n.termsRequiredMessage;
      _passwordFocused =
          _passwordFocused || _passwordController.text.isNotEmpty;
    });

    if ([
      nameError,
      phoneError,
      emailError,
      passwordError,
      confirmError,
      termsError,
    ].any((error) => error != null)) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: widget.arguments.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: AuthValidators.normalizedPhone(
          _countryCode,
          _phoneController.text,
        ),
      ),
    );
  }

  void _setPasswordFocus(bool hasFocus) {
    if (_passwordFocused == hasFocus) return;
    setState(() => _passwordFocused = hasFocus);
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
        case 'phone':
          _phoneError = null;
        case 'email':
          _emailError = null;
        case 'password':
          _passwordError = null;
        case 'confirm':
          _confirmPasswordError = null;
      }
    });
  }

  void _returnToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.login, arguments: widget.arguments);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final passwordValidation = PasswordValidation.evaluate(
      _passwordController.text,
    );
    final showPasswordRequirements =
        _passwordFocused ||
        (_passwordController.text.isNotEmpty && !passwordValidation.isValid) ||
        _passwordError != null;

    return AuthPageLayout(
      header: AuthHeader(
        title: l10n.signupWelcomeTitle,
        subtitle: l10n.createAccountSubtitle,
        onBack: () => Navigator.maybePop(context),
        topBarTitle: l10n.createAccountTitle,
        trailingIcon: Icons.person_outline_rounded,
        titleFontSize: 24,
        compact: true,
      ),
      footer: SignUpFooter(
        createAccountLabel: l10n.createAccountLabel,
        alreadyHaveAccountPrompt: l10n.alreadyHaveAccountPrompt,
        signInLabel: l10n.signInLabel,
        onSubmit: _validateAndContinue,
        onSignIn: _returnToLogin,
      ),
      child: SignUpForm(
        l10n: l10n,
        nameController: _nameController,
        phoneController: _phoneController,
        emailController: _emailController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        passwordFocusNode: _passwordFocusNode,
        countryCode: _countryCode,
        nameError: _nameError,
        phoneError: _phoneError,
        emailError: _emailError,
        passwordError: _passwordError,
        confirmPasswordError: _confirmPasswordError,
        termsError: _termsError,
        passwordValidation: passwordValidation,
        showPasswordRequirements: showPasswordRequirements,
        termsAccepted: _termsAccepted,
        onNameChanged: (_) => _clearError('name'),
        onPhoneChanged: (_) => _clearError('phone'),
        onCountryChanged: (value) => setState(() => _countryCode = value),
        onEmailChanged: (_) => _clearError('email'),
        onPasswordChanged: (_) {
          _clearError('password');
          setState(() {});
        },
        onPasswordFocusChanged: _setPasswordFocus,
        onConfirmPasswordChanged: (_) => _clearError('confirm'),
        onTermsChanged: (value) => setState(() {
          _termsAccepted = value;
          if (value) _termsError = null;
        }),
      ),
    );
  }
}
