import 'package:flutter/material.dart';
import '../../../core/theme/app_color.dart';

class SignUpTermsField extends StatelessWidget {
  const SignUpTermsField({
    super.key,
    required this.accepted,
    required this.label,
    required this.errorText,
    required this.onChanged,
  });

  final bool accepted;
  final String label;
  final String? errorText;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: accepted,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => onChanged(!accepted),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const ValueKey('signup-terms-checkbox'),
                  value: accepted,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: AppColor.primary,
                  visualDensity: VisualDensity.standard,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      label,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, top: 2),
              child: Text(
                errorText!,
                style: const TextStyle(color: AppColor.alert, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
