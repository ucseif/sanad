import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/shared_widgets/sanad_button.dart';

class SignUpFooter extends StatelessWidget {
  const SignUpFooter({
    super.key,
    required this.createAccountLabel,
    required this.alreadyHaveAccountPrompt,
    required this.signInLabel,
    required this.onSubmit,
    required this.onSignIn,
  });

  final String createAccountLabel;
  final String alreadyHaveAccountPrompt;
  final String signInLabel;
  final VoidCallback onSubmit;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SanadButton(
          key: const ValueKey('signup-submit'),
          label: createAccountLabel,
          onPressed: onSubmit,
          fontSize: 15,
          height: 54,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                alreadyHaveAccountPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColor.textSecondary,
                  fontSize: 13.5,
                ),
              ),
            ),
            TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                signInLabel,
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
    );
  }
}
