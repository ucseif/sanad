import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_color.dart';

enum OnboardingIllustrationKind {
  welcome,
  monitoring,
  detection,
  family,
  medicalId,
}

class LanguageIllustration extends StatelessWidget {
  const LanguageIllustration({
    super.key,
    required this.label,
    this.height = 144,
  });

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 340,
          height: 144,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 25,
                right: 25,
                top: 10,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120D263D),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LanguageSheet(
                          title: 'العربية',
                          icon: 'ع',
                          color: AppColor.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LanguageSheet(
                          title: 'English',
                          icon: 'Aa',
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x160D263D), blurRadius: 10),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColor.success,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                icon,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.check_circle_rounded, color: color, size: 14),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColor.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.kind,
    this.compact = false,
    this.height,
  });

  final OnboardingIllustrationKind kind;
  final bool compact;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final illustrationHeight = height ?? (compact ? 205.0 : 238.0);
    return SizedBox(
      height: illustrationHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 340.0);
          return Center(
            child: SizedBox(
              width: width,
              height: illustrationHeight,
              child: switch (kind) {
                OnboardingIllustrationKind.welcome => const _WelcomeVisual(),
                OnboardingIllustrationKind.monitoring =>
                  const _MonitoringVisual(),
                OnboardingIllustrationKind.detection =>
                  const _DetectionVisual(),
                OnboardingIllustrationKind.family => const _FamilyVisual(),
                OnboardingIllustrationKind.medicalId =>
                  const _MedicalIdVisual(),
              },
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeVisual extends StatelessWidget {
  const _WelcomeVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 15,
          top: 35,
          child: _DevicePanel(
            width: 195,
            height: 135,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BPM',
                  style: TextStyle(
                    color: AppColor.mutedText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: CustomPaint(painter: _PulsePainter()),
                ),
                const Spacer(),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColor.success,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 53,
          child: _WatchCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 15,
                      color: AppColor.success,
                    ),
                    Text(
                      '98%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .9),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Pulse',
                  style: TextStyle(color: Colors.white70, fontSize: 8),
                ),
                const Text(
                  'Optimal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  height: 4,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColor.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 38,
          child: _StatusPill(
            icon: Icons.shield_outlined,
            label: 'Precision Feed',
            color: AppColor.textSecondary,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 36,
          child: _StatusPill(
            icon: Icons.favorite_rounded,
            label: '24/7 Care',
            color: AppColor.success,
          ),
        ),
      ],
    );
  }
}

class _MonitoringVisual extends StatelessWidget {
  const _MonitoringVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LargePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _MiniIcon(
                  icon: Icons.favorite_rounded,
                  color: AppColor.alert,
                ),
                _Tag(label: '● Normal', color: AppColor.success),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Heart Rate',
              style: TextStyle(
                color: AppColor.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '72',
                  style: TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5, bottom: 4),
                  child: Text(
                    'BPM',
                    style: TextStyle(
                      color: AppColor.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Expanded(
              child: CustomPaint(
                painter: _PulsePainter(dark: true),
                child: const SizedBox.expand(),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.air_rounded,
                    value: '98%',
                    label: 'SpO₂',
                    color: AppColor.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.directions_walk_rounded,
                    value: '8,420',
                    label: 'Daily Steps',
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionVisual extends StatelessWidget {
  const _DetectionVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LargePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniIcon(
                  icon: Icons.graphic_eq_rounded,
                  color: AppColor.success,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Context-Aware AI',
                    style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Tag(label: '99.4% • Stable', color: AppColor.success),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                13,
                (index) => Container(
                  width: 5,
                  height: [
                    26,
                    38,
                    20,
                    48,
                    32,
                    18,
                    39,
                    24,
                    47,
                    29,
                    19,
                    36,
                    27,
                  ][index].toDouble(),
                  decoration: BoxDecoration(
                    color: index == 7
                        ? AppColor.success
                        : AppColor.mutedText.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  _MiniIcon(
                    icon: Icons.shield_outlined,
                    color: AppColor.primary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Impact Guard',
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Auto-Detect',
                    style: TextStyle(
                      color: AppColor.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyVisual extends StatelessWidget {
  const _FamilyVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LargePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColor.surfaceMuted,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColor.textSecondary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ahmed • Primary Care',
                        style: TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Connected caregiver',
                        style: TextStyle(
                          color: AppColor.mutedText,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                _Tag(label: '● Online', color: AppColor.success),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColor.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColor.textSecondary,
                    size: 17,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'At Home • Safe Zone',
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColor.mutedText,
                    size: 18,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                for (final color in const [
                  AppColor.primary,
                  AppColor.success,
                  AppColor.alert,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: CircleAvatar(radius: 12, backgroundColor: color),
                  ),
                const Text(
                  '+2 family members',
                  style: TextStyle(color: AppColor.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalIdVisual extends StatelessWidget {
  const _MedicalIdVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _LargePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MiniIcon(
                  icon: Icons.medical_services_rounded,
                  color: AppColor.alert,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Digital Medical ID',
                    style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Tag(label: 'NFC', color: AppColor.success),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoBlock(
                    icon: Icons.bloodtype_rounded,
                    label: 'Blood Type',
                    value: 'O+',
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoBlock(
                    icon: Icons.warning_amber_rounded,
                    label: 'Allergy',
                    value: 'Penicillin',
                    color: AppColor.alert,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColor.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 17,
                    color: AppColor.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency contact',
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '1-Tap',
                    style: TextStyle(
                      color: AppColor.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColor.mutedText,
                ),
                SizedBox(width: 5),
                Text(
                  'No App Needed',
                  style: TextStyle(color: AppColor.mutedText, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LargePanel extends StatelessWidget {
  const _LargePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 298,
      height: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D263D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DevicePanel extends StatelessWidget {
  const _DevicePanel({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D263D),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      height: 137,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0D263D),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColor.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColor.mutedText,
                    fontSize: 8,
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

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColor.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              Icon(Icons.circle, size: 7, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColor.mutedText, fontSize: 7),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  const _MiniIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120D263D),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({this.dark = false});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .58)
      ..lineTo(size.width * .27, size.height * .58)
      ..lineTo(size.width * .35, size.height * .58)
      ..lineTo(size.width * .41, size.height * .18)
      ..lineTo(size.width * .48, size.height * .82)
      ..lineTo(size.width * .57, size.height * .42)
      ..lineTo(size.width * .64, size.height * .58)
      ..lineTo(size.width, size.height * .58);
    canvas.drawPath(
      path,
      Paint()
        ..color = dark ? AppColor.textPrimary : AppColor.textSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.dark != dark;
}
