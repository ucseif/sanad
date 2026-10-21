import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../domain/models/user_role.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  static const routeName = '/role-selection';

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.patient;

  void _selectRole(UserRole role) {
    if (_selectedRole == role) return;
    setState(() => _selectedRole = role);
  }

  void _continue() {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: AuthRouteArguments(role: _selectedRole),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: (constraints.maxWidth * .34)
                        .clamp(104.0, 128.0)
                        .toDouble(),
                    height: compact ? 122 : 144,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        AppAssets.sanadLogo,
                        fit: BoxFit.contain,
                        semanticLabel: 'SANAD logo',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 1 : 2),

                SizedBox(height: compact ? 5 : 16),
                Text(
                  l10n.roleTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: compact ? 22 : 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: compact ? 5 : 7),
                Text(
                  l10n.roleSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: compact ? 15 : 22),
                _RoleCard(
                  key: const ValueKey('role-option-patient'),
                  role: UserRole.patient,
                  title: l10n.patient,
                  description: l10n.patientDescription,
                  chipLabel: l10n.patientChip,
                  selected: _selectedRole == UserRole.patient,
                  compact: compact,
                  onTap: () => _selectRole(UserRole.patient),
                ),
                SizedBox(height: compact ? 10 : 12),
                _RoleCard(
                  key: const ValueKey('role-option-caregiver'),
                  role: UserRole.caregiver,
                  title: l10n.caregiver,
                  description: l10n.caregiverDescription,
                  chipLabel: l10n.caregiverChip,
                  selected: _selectedRole == UserRole.caregiver,
                  compact: compact,
                  onTap: () => _selectRole(UserRole.caregiver),
                ),
                SizedBox(height: compact ? 14 : 18),
                _PrivacyBanner(
                  title: l10n.privacyTitle,
                  subtitle: l10n.privacySubtitle,
                  compact: compact,
                ),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                18,
                compact ? 6 : 12,
                18,
                compact ? 12 : 18,
              ),
              child: content,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.roleHelper,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColor.mutedText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              SanadButton(
                label: l10n.continueLabel,
                onPressed: _continue,
                fontSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.role,
    required this.title,
    required this.description,
    required this.chipLabel,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final UserRole role;
  final String title;
  final String description;
  final String chipLabel;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final roleLabel = role == UserRole.patient ? 'Patient' : 'Caregiver';
    final roleIcon = role == UserRole.patient
        ? Icons.favorite_rounded
        : Icons.groups_rounded;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: BoxConstraints(minHeight: compact ? 126 : 140),
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 14 : 16,
            compact ? 14 : 17,
            compact ? 14 : 16,
            compact ? 14 : 17,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColor.surfaceMuted : AppColor.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColor.primary : AppColor.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 44 : 48,
                height: compact ? 44 : 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColor.primary : AppColor.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  roleIcon,
                  size: compact ? 21 : 23,
                  color: selected ? Colors.white : AppColor.textSecondary,
                ),
              ),
              SizedBox(width: compact ? 11 : 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: compact ? 17 : 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _RoleChip(
                      icon: role == UserRole.patient
                          ? Icons.monitor_heart_outlined
                          : Icons.family_restroom_outlined,
                      label: chipLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SelectionIndicator(selected: selected, label: roleLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColor.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColor.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColor.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: selected ? AppColor.primary : AppColor.indicatorInactive,
          shape: BoxShape.circle,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
            : null,
      ),
    );
  }
}

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        compact ? 12 : 14,
        compact ? 10 : 12,
        compact ? 12 : 14,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: compact ? 18 : 20,
            color: AppColor.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 12,
                    height: 1.25,
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
