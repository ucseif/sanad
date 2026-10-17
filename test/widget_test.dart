import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sanad/core/localization/locale_controller.dart';
import 'package:sanad/core/localization/locale_scope.dart';
import 'package:sanad/main.dart';
import 'package:sanad/presentation/screens/language_screen/language_screen.dart';
import 'package:sanad/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:sanad/presentation/screens/role_selection/role_selection_screen.dart';
import 'package:sanad/presentation/screens/home_screen/home_screen.dart';
import 'package:sanad/presentation/widgets/sanad_button.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app() {
    return LocaleScope(controller: LocaleController(), child: const SanadApp());
  }

  Future<void> openLanguage(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
  }

  testWidgets('splash renders SANAD branding and navigates to language', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.bySemanticsLabel('SANAD logo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();
    expect(find.byType(LanguageScreen), findsOneWidget);
  });

  testWidgets('language selection updates locale and continues to welcome', (
    tester,
  ) async {
    await openLanguage(tester);
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('language-option-ar')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    expect(find.text('Choose App Language'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Care That Stays With You.'), findsOneWidget);
    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('language screen switches between RTL and LTR layouts', (
    tester,
  ) async {
    await openLanguage(tester);
    expect(
      Directionality.of(tester.element(find.byType(LanguageScreen))),
      TextDirection.rtl,
    );

    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(LanguageScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('locale selects the matching global font family', (tester) async {
    await openLanguage(tester);
    expect(
      Theme.of(
        tester.element(find.byType(LanguageScreen)),
      ).textTheme.bodyMedium?.fontFamily,
      'Tajawal',
    );

    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(
        tester.element(find.byType(LanguageScreen)),
      ).textTheme.bodyMedium?.fontFamily,
      'Poppins',
    );
  });

  testWidgets('onboarding next advances pages and opens role selection', (
    tester,
  ) async {
    await openLanguage(tester);
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 5'), findsOneWidget);
    for (var page = 2; page <= 5; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step $page of 5'), findsOneWidget);
    }

    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('role-option-patient')), findsOneWidget);

    final caregiverOption = find.byKey(const ValueKey('role-option-caregiver'));
    await tester.ensureVisible(caregiverOption);
    await tester.tap(caregiverOption);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('role screen renders role selection', (tester) async {
    await openLanguage(tester);
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    for (var page = 2; page <= 5; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('Choose Your Role to Continue'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    final caregiverOption = find.byKey(const ValueKey('role-option-caregiver'));
    await tester.ensureVisible(caregiverOption);
    await tester.tap(caregiverOption);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('role-option-caregiver')), findsOneWidget);
  });

  testWidgets('Arabic role screen uses RTL content without a back button', (
    tester,
  ) async {
    await openLanguage(tester);
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    for (var page = 2; page <= 5; page++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.text('اختر صفتك للمتابعة'), findsOneWidget);
    expect(find.text('Choose Your Role to Continue'), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('role screen remains usable at common phone sizes', (
    tester,
  ) async {
    const sizes = [Size(360, 640), Size(390, 844), Size(430, 900)];

    await tester.binding.setSurfaceSize(sizes.first);
    await openLanguage(tester);
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    for (var page = 2; page <= 5; page++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('redesigned flow renders at compact, standard, and large sizes', (
    tester,
  ) async {
    const sizes = [Size(320, 568), Size(390, 844), Size(440, 900)];

    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await openLanguage(tester);
      await tester.tap(find.byType(SanadButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });
}
