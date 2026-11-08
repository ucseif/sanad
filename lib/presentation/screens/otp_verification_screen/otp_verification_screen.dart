import 'dart:async';
import 'package:flutter/material.dart';
import '../../../application/auth/auth_service.dart';
import '../../../application/auth/auth_scope.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../data/network/api_exception.dart';
import '../../../utils/routes.dart';
import '../../auth/auth_route_arguments.dart';
import '../../auth/api_error_message.dart';
import '../home_screen/home_screen.dart';
import '../../widgets/otp_verification_screen_widgets/otp_verification_content.dart';
import '../../widgets/otp_verification_screen_widgets/otp_verification_header.dart';
import '../../widgets/otp_verification_screen_widgets/otp_verification_submit_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.arguments,
    this.authService,
  });
  static const routeName = '/otp-verification';
  final AuthRouteArguments arguments;
  final AuthService? authService;
  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  AuthService get _auth => widget.authService ?? AuthScope.read(context);
  String _code = '';
  String? _errorText;
  bool _busy = false, _sending = false, _verified = false;
  int _inputRevision = 0;
  DateTime? _resendAt;
  Timer? _countdownTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendCode();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _back() {
    if (_busy || _sending) return;
    if (widget.arguments.isLoginVerification) {
      _auth.login.discardPendingAttempt();
    } else {
      _auth.discardSignup();
    }
    Navigator.maybePop(context);
  }

  Future<void> _sendCode() async {
    if (_busy || _sending) return;
    setState(() {
      _sending = true;
      _errorText = null;
    });
    try {
      final sent = widget.arguments.isLoginVerification
          ? await _auth.sendLoginOtp()
          : await _auth.sendSignupOtp();
      if (!mounted) return;
      setState(() {
        _resendAt = sent.resendAt;
        _code = '';
        _inputRevision++;
      });
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (error) {
      if (mounted) {
        if (error is ApiException &&
            [
              'otp-expired',
              'invalid-challenge',
              'challenge-used',
              'account-changed',
            ].contains(error.code) &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop(error.code);
          return;
        }
        setState(() => _errorText = apiErrorMessage(context.l10n, error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || _sending) return;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(_code)) {
      setState(() => _errorText = context.l10n.otpIncompleteMessage);
      return;
    }
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      final user = widget.arguments.isLoginVerification
          ? await _auth.verifyLoginOtp(_code)
          : await _auth.verifySignupOtp(_code);
      if (!mounted) return;
      _verified = true;
      Navigator.of(context).pushAndRemoveUntil(
        AppRoutes.transition(
          settings: const RouteSettings(name: AppRoutes.home),
          builder: (_) => HomeScreen(initialUser: user, authService: _auth),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      if (error is ApiException &&
              [
                'invalid-challenge',
                'challenge-used',
                'account-changed',
                'email-already-in-use',
                'username-taken',
              ].contains(apiErrorCode(error)) ||
          (error is ApiException &&
              error.code == 'otp-expired' &&
              _auth.attemptExpired(
                loginFlow: widget.arguments.isLoginVerification,
              )) ||
          (!widget.arguments.isLoginVerification && !_auth.hasPendingSignup)) {
        Navigator.of(context).pop(apiErrorCode(error));
        return;
      }
      setState(() => _errorText = apiErrorMessage(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _maskedPhone(String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) return '—';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '••••$digits';
    return '+••••••${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    return PopScope(
      canPop: !_busy && !_sending,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_auth.isBusy) {
          if (widget.arguments.isLoginVerification) {
            _auth.login.discardPendingAttempt();
          } else {
            _auth.discardSignup();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.surface,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(28, 12, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OtpVerificationHeader(backLabel: l10n.back, onBack: _back),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: OtpVerificationContent(
                          title: l10n.otpTitle,
                          description: isArabic
                              ? 'أدخل الرمز المكوّن من 6 أرقام المرسل عبر'
                              : 'Enter the 6-digit code sent to you on',
                          whatsAppLabel: isArabic ? 'واتساب' : 'WhatsApp',
                          phoneNumber: _maskedPhone(
                            widget.arguments.phoneNumber,
                          ),
                          codeLabel: l10n.otpCodeLabel,
                          inputKey: ValueKey('otp-input-$_inputRevision'),
                          errorText: _errorText,
                          digitLabel: l10n.otpDigitLabel,
                          onCodeChanged: (value) => setState(() {
                            _code = value;
                            if (value.length == 6) _errorText = null;
                          }),
                          resendLabel: _resendLabel(l10n),
                          isArabic: isArabic,
                          canResend:
                              !_sending &&
                              !_busy &&
                              (_resendAt == null ||
                                  !DateTime.now().isBefore(_resendAt!)),
                          onResend: _sendCode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OtpVerificationSubmitButton(
                      isBusy: _busy,
                      isSending: _sending,
                      isVerified: _verified,
                      verifyLabel: l10n.verifyLabel,
                      verifiedLabel: l10n.otpVerifiedMessage,
                      onPressed: _verify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _resendLabel(AppLocalizations l10n) {
    if (_resendAt == null) return l10n.otpResendLabel;
    final remaining = _resendAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) return l10n.otpResendLabel;
    return l10n.otpResendCountdown(remaining);
  }
}
