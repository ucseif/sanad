import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color.dart';
import '../../../presentation/widgets/auth/auth_text_field.dart';

class SignUpPhoneField extends StatelessWidget {
  const SignUpPhoneField({
    required this.countryCode,
    required this.phoneController,
    required this.label,
    required this.hintText,
    required this.countryCodeLabel,
    required this.errorText,
    required this.onCountryChanged,
    required this.onChanged,
  });

  final String countryCode;
  final TextEditingController phoneController;
  final String label;
  final String hintText;
  final String countryCodeLabel;
  final String? errorText;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: AppColor.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 54,
              child: Semantics(
                label: countryCodeLabel,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 3),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: countryCode,
                      isDense: true,
                      isExpanded: true,
                      iconSize: 18,
                      onChanged: (value) {
                        if (value != null) onCountryChanged(value);
                      },
                      items: AppConstants.signUpCountryCallingCodes
                          .map(
                            (code) => DropdownMenuItem<String>(
                              value: code,
                              child: Text(
                                code,
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: AppColor.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                label: label,
                textField: true,
                child: SizedBox(
                  height: 54,
                  child: AuthTextField(
                    key: const ValueKey('signup-phone-field'),
                    controller: phoneController,
                    label: '',
                    hintText: hintText,
                    compact: true,
                    errorText: null,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    textDirection: TextDirection.ltr,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +()\-]')),
                    ],
                    onChanged: onChanged,
                    autofillHints: const [AutofillHints.telephoneNumber],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppColor.alert, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}
