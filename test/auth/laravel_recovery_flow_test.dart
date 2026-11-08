import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/login_screen/login_screen.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> frames(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 1100));
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'recovery uses six WhatsApp digits and returns to Login without a session',
    (tester) async {
      final f = LaravelAuthFixture();
      addTearDown(f.close);
      await tester.pumpWidget(
        f.app(
          const LoginScreen(
            arguments: AuthRouteArguments(role: UserRole.patient),
          ),
        ),
      );
      await frames(tester);
      await tester.tap(find.text('Forgot password?'));
      await frames(tester);
      await tester.enterText(
        find.byType(TextField).first,
        'unknown@example.com',
      );
      await tester.ensureVisible(find.text('Send Code'));
      await tester.tap(find.text('Send Code'));
      await frames(tester);
      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.textContaining('WhatsApp code'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(
          find.byKey(ValueKey('recovery-digit-$i')),
          '123456'[i],
        );
      }
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await frames(tester);
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).at(0), 'NewStrongPass1!');
      await tester.enterText(find.byType(TextField).at(1), 'NewStrongPass1!');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await frames(tester);
      expect(find.byKey(const ValueKey('login-submit')), findsOneWidget);
      expect(await f.tokens.read(), isNull);
      expect(
        f.requests.map((r) => r.url.path),
        contains('/api/auth/password/reset'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final language in ['en', 'ar']) {
    testWidgets(
      'recovery $language fits a small phone and keyboard, digits remain LTR',
      (tester) async {
        final f = LaravelAuthFixture();
        addTearDown(f.close);
        await tester.binding.setSurfaceSize(const Size(318, 644));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          f.app(
            const LoginScreen(
              arguments: AuthRouteArguments(role: UserRole.patient),
            ),
            language: language,
          ),
        );
        await frames(tester);
        await tester.tap(
          find.text(
            language == 'ar' ? 'نسيت كلمة المرور؟' : 'Forgot password?',
          ),
        );
        await frames(tester);
        await tester.enterText(
          find.byType(TextField).first,
          'amina@example.com',
        );
        final send = find.text(language == 'ar' ? 'إرسال الكود' : 'Send Code');
        await tester.ensureVisible(send);
        await tester.tap(send);
        await frames(tester);
        expect(find.byType(TextField), findsNWidgets(6));
        final first = find.byKey(const ValueKey('recovery-digit-0'));
        expect(Directionality.of(tester.element(first)), TextDirection.ltr);
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        final action = find.text(language == 'ar' ? 'استمرار' : 'Continue');
        await tester.ensureVisible(action);
        await tester.pump();
        expect(tester.takeException(), isNull);
        final back = find.text(language == 'ar' ? 'رجوع' : 'Back');
        await tester.ensureVisible(back);
        await tester.tap(back);
        await frames(tester);
        expect(find.byType(TextField), findsOneWidget);
        expect(f.auth.hasPendingRecovery, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
