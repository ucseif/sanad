import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

/// Lightweight floating navigation using the login screen's monochrome palette.
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
      (
        id: 'home',
        label: isArabic ? 'الرئيسية' : 'Home',
        icon: Icons.home_outlined,
      ),
      (
        id: 'activity',
        label: isArabic ? 'النشاط' : 'Activity',
        icon: Icons.directions_run_rounded,
      ),
      (
        id: 'health',
        label: isArabic ? 'الصحة' : 'Health',
        icon: Icons.favorite_border_rounded,
      ),
      (
        id: 'insights',
        label: isArabic ? 'المؤشرات' : 'Insights',
        icon: Icons.insights_rounded,
      ),
      (
        id: 'profile',
        label: isArabic ? 'حسابي' : 'Profile',
        icon: Icons.person_outline_rounded,
      ),
    ];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Align(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.loginLightBackground,
            borderRadius: BorderRadius.circular(14),
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
              final itemWidth = constraints.maxWidth / destinations.length;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    start: itemWidth * selectedIndex,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: DecoratedBox(
                      key: const ValueKey('nav-selection-indicator'),
                      decoration: BoxDecoration(
                        color: AppColor.loginLightText,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var index = 0; index < destinations.length; index++)
                        Expanded(
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
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => onSelected(index),
                                  child: SizedBox(
                                    height: double.infinity,
                                    child: TweenAnimationBuilder<Color?>(
                                      tween: ColorTween(
                                        end: selectedIndex == index
                                            ? AppColor.loginLightBackground
                                            : AppColor.loginLightSecondaryText,
                                      ),
                                      duration: duration,
                                      builder: (context, color, child) =>
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                destinations[index].icon,
                                                size: 22,
                                                color: color,
                                              ),
                                              const SizedBox(height: 4),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                child: Text(
                                                  destinations[index].label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w600,
                                                    color: color,
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
