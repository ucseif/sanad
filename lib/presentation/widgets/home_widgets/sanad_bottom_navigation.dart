import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

/// A compact floating dock with a labeled capsule for the current destination.
class SanadBottomNavigation extends StatelessWidget {
  const SanadBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isArabic,
    required this.onSelected,
  });

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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: .14),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth / 6).clamp(
                      48.0,
                      double.infinity,
                    );
                    return Row(
                      children: [
                        for (
                          var index = 0;
                          index < destinations.length;
                          index++
                        )
                          SizedBox(
                            width: selectedIndex == index
                                ? constraints.maxWidth - itemWidth * 4
                                : itemWidth,
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
                                child: AnimatedContainer(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: selectedIndex == index
                                        ? AppColor.secondary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Material(
                                    type: MaterialType.transparency,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: () => onSelected(index),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: selectedIndex == index
                                              ? 8
                                              : 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              destinations[index].icon,
                                              size: 23,
                                              color: selectedIndex == index
                                                  ? AppColor.primary
                                                  : const Color(0xFFAEB7C0),
                                            ),
                                            if (selectedIndex == index) ...[
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  destinations[index].label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColor.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
