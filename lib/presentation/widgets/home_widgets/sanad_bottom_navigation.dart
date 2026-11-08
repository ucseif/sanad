import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

/// Floating capsule navigation in SANAD's monochrome visual language.
class SanadBottomNavigation extends StatelessWidget {
  const SanadBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isArabic,
    required this.onSelected,
  });

  static const double height = 72;
  static const double bottomSpacing = 12;
  static const double contentClearance = 20;

  final int selectedIndex;
  final bool isArabic;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final destinations = [
      (id: 'home', label: isArabic ? 'الرئيسية' : 'Home'),
      (id: 'activity', label: isArabic ? 'النشاط' : 'Activity'),
      (id: 'health', label: isArabic ? 'الصحة' : 'Health'),
      (id: 'insights', label: isArabic ? 'المؤشرات' : 'Insights'),
      (id: 'profile', label: isArabic ? 'حسابي' : 'Profile'),
    ];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColor.loginLightBackground,
    );

    return Align(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.loginLightBackground,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColor.loginLightBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Preserve generous icon targets while making room for one label.
              final inactiveWidth = (constraints.maxWidth / 6).clamp(
                48.0,
                double.infinity,
              );
              final activeWidth = constraints.maxWidth - inactiveWidth * 4;
              final labelWidth = (activeWidth - 46).clamp(0.0, double.infinity);
              // Center the visible icon/text pair, not a full-width text box
              // whose unused space pushes a short label toward the leading edge.
              final labelWidths = destinations.map((destination) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: destination.label,
                    style: DefaultTextStyle.of(context).style.merge(labelStyle),
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 1,
                  ellipsis: '…',
                )..layout(maxWidth: labelWidth);
                final width = painter.width;
                painter.dispose();
                return width;
              }).toList(growable: false);
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    start: inactiveWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: activeWidth,
                    child: DecoratedBox(
                      key: const ValueKey('nav-selection-indicator'),
                      decoration: BoxDecoration(
                        color: AppColor.loginLightText,
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            end: selectedIndex == index ? 1 : 0,
                          ),
                          duration: duration,
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) => SizedBox(
                            width:
                                inactiveWidth +
                                (activeWidth - inactiveWidth) * progress,
                            height: double.infinity,
                            child: Semantics(
                              key: ValueKey('nav-${destinations[index].id}'),
                              label: destinations[index].label,
                              button: true,
                              selected: selectedIndex == index,
                              onTap: () => onSelected(index),
                              excludeSemantics: true,
                              child: Tooltip(
                                message: destinations[index].label,
                                excludeFromSemantics: true,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: () => onSelected(index),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size.square(24),
                                            painter: _NavigationIconPainter(
                                              index: index,
                                              color: Color.lerp(
                                                AppColor
                                                    .loginLightSecondaryText,
                                                AppColor.loginLightBackground,
                                                progress,
                                              )!,
                                            ),
                                          ),
                                          SizedBox(width: 6 * progress),
                                          ClipRect(
                                            child: SizedBox(
                                              width: labelWidths[index] * progress,
                                              child: Opacity(
                                                opacity: progress,
                                                child: Text(
                                                  destinations[index].label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: labelStyle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A consistent set of rounded outline icons, drawn at any display density.
class _NavigationIconPainter extends CustomPainter {
  const _NavigationIconPainter({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (index) {
      case 0:
        final home = Path()
          ..moveTo(9.8, 3.7)
          ..quadraticBezierTo(12, 2, 14.2, 3.7)
          ..lineTo(20.3, 8.5)
          ..quadraticBezierTo(21.3, 9.3, 21, 11)
          ..lineTo(19.4, 19.1)
          ..quadraticBezierTo(19, 21, 17, 21)
          ..lineTo(7, 21)
          ..quadraticBezierTo(5, 21, 4.6, 19.1)
          ..lineTo(3, 11)
          ..quadraticBezierTo(2.7, 9.3, 3.7, 8.5)
          ..close();
        canvas.drawPath(home, pen);
        canvas.drawLine(const Offset(9.5, 16.5), const Offset(14.5, 16.5), pen);
      case 1:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(6),
          ),
          pen,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 13)
            ..lineTo(9, 13)
            ..lineTo(11, 8)
            ..lineTo(14, 17)
            ..lineTo(16, 12)
            ..lineTo(18, 12),
          pen,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20.5)
            ..cubicTo(8, 17.5, 3, 13.7, 3, 8.8)
            ..cubicTo(3, 3.2, 9.5, 2.5, 12, 7)
            ..cubicTo(14.5, 2.5, 21, 3.2, 21, 8.8)
            ..cubicTo(21, 13.7, 16, 17.5, 12, 20.5)
            ..close(),
          pen,
        );
      case 3:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(5),
          ),
          pen,
        );
        canvas.drawLine(const Offset(7.5, 16.5), const Offset(7.5, 12.5), pen);
        canvas.drawLine(const Offset(12, 16.5), const Offset(12, 7.5), pen);
        canvas.drawLine(const Offset(16.5, 16.5), const Offset(16.5, 10), pen);
      case 4:
        canvas.drawCircle(const Offset(12, 7), 3.7, pen);
        canvas.drawPath(
          Path()
            ..moveTo(4, 21)
            ..lineTo(4.6, 17.6)
            ..cubicTo(5.4, 12.9, 18.6, 12.9, 19.4, 17.6)
            ..lineTo(20, 21)
            ..close(),
          pen,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavigationIconPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
