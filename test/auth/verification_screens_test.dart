import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show Tristate;

import 'package:sanad/core/localization/app_localizations.dart';
import 'package:sanad/core/theme/app_color.dart';
import 'package:sanad/domain/models/user_role.dart';
import 'package:sanad/presentation/auth/auth_route_arguments.dart';
import 'package:sanad/presentation/screens/otp_verification_screen/otp_verification_screen.dart';
import 'package:sanad/presentation/screens/verification_method_screen/verification_method_screen.dart';
import 'package:sanad/utils/routes.dart';

void main() {
  Widget app(
    Widget home, {
    Locale locale = const Locale('en'),
    NavigatorObserver? observer,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppColor.theme(isArabic: locale.languageCode == 'ar'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: [?observer],
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: home,
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Locale locale = const Locale('en'),
    NavigatorObserver? observer,
  }) async {
    await tester.pumpWidget(app(screen, locale: locale, observer: observer));
    await tester.pumpAndSettle();
  }

  const arguments = AuthRouteArguments(
    role: UserRole.patient,
    email: 'sarah@gmail.com',
  );

  testWidgets(
    'verification method masks the entered email and keeps email selected',
    (tester) async {
      await pumpScreen(
        tester,
        const VerificationMethodScreen(arguments: arguments),
      );

      expect(find.text('s***@gmail.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('email-method-card')), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    },
  );

  testWidgets('verification screens share the readable auth heading and CTA', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const VerificationMethodScreen(arguments: arguments),
    );
    expect(
      tester
          .widget<Text>(find.text('Choose a verification method'))
          .style
          ?.fontSize,
      24,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('verification-continue')))
          .height,
      54,
    );

    await pumpScreen(tester, const OtpVerificationScreen(arguments: arguments));
    expect(
      tester.widget<Text>(find.text('Enter verification code')).style?.fontSize,
      24,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('otp-verify-submit'))).height,
      54,
    );
  });

  testWidgets('SMS remains unavailable and only shows localized feedback', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const VerificationMethodScreen(arguments: arguments),
    );

    final smsCardSemantics = tester
        .getSemantics(find.byKey(const ValueKey('sms-method-card')))
        .getSemanticsData();
    expect(smsCardSemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(smsCardSemantics.flagsCollection.isEnabled, Tristate.isTrue);
    expect(smsCardSemantics.label, contains('Not available yet'));

    await tester.tap(find.byKey(const ValueKey('sms-method-card')));
    await tester.pump();
    expect(
      find.text(
        'SMS verification is not available yet. Please continue using email verification.',
      ),
      findsOneWidget,
    );
    expect(find.byType(OtpVerificationScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('Arabic verification preserves LTR email and OTP content', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const VerificationMethodScreen(arguments: arguments),
      locale: const Locale('ar'),
    );

    expect(find.text('s***@gmail.com'), findsOneWidget);
    final emailValue = find.text('s***@gmail.com');
    expect(tester.widget<Text>(emailValue).textDirection, TextDirection.ltr);
    await tester.tap(find.byKey(const ValueKey('sms-method-card')));
    await tester.pump();
    expect(
      find.text(
        'التحقق عبر الرسائل النصية غير متاح حاليًا. يمكنك المتابعة باستخدام البريد الإلكتروني.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await pumpScreen(
      tester,
      const OtpVerificationScreen(arguments: arguments),
      locale: const Locale('ar'),
    );
    final firstDigitField = find.descendant(
      of: find.byKey(const ValueKey('otp-input-0')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(firstDigitField).textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('email continue preserves role and email for OTP presentation', (
    tester,
  ) async {
    final observer = _RecordingObserver();
    await pumpScreen(
      tester,
      const VerificationMethodScreen(arguments: arguments),
      observer: observer,
    );
    observer.lastPushed = null;

    await tester.ensureVisible(
      find.byKey(const ValueKey('verification-continue')),
    );
    await tester.tap(find.byKey(const ValueKey('verification-continue')));
    await tester.pumpAndSettle();

    expect(observer.lastPushed?.settings.name, AppRoutes.otpVerification);
    final nextArguments =
        observer.lastPushed?.settings.arguments as AuthRouteArguments;
    expect(nextArguments.role, UserRole.patient);
    expect(nextArguments.email, 'sarah@gmail.com');
  });

  testWidgets('OTP requires six digits and does not claim verification success', (
    tester,
  ) async {
    await pumpScreen(tester, const OtpVerificationScreen(arguments: arguments));

    await tester.ensureVisible(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    expect(find.text('Enter the 6-digit verification code.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('otp-input-0')));
    await tester.enterText(find.byKey(const ValueKey('otp-input-0')), '123456');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.tap(find.byKey(const ValueKey('otp-verify-submit')));
    await tester.pump();
    expect(
      find.text(
        'Real verification will be connected later. The code was not verified.',
      ),
      findsOneWidget,
    );
    expect(find.text('Welcome to SANAD'), findsNothing);
  });

  testWidgets(
    'verification pages keep their action reachable at reference size',
    (tester) async {
      const size = Size(318, 644);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpScreen(
        tester,
        const VerificationMethodScreen(arguments: arguments),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('verification-continue')),
      );
      await tester.pumpAndSettle();
      var action = tester.getRect(
        find.byKey(const ValueKey('verification-continue')),
      );
      expect(action.top, greaterThanOrEqualTo(0));
      expect(action.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);

      await pumpScreen(
        tester,
        const OtpVerificationScreen(arguments: arguments),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('otp-verify-submit')),
      );
      await tester.pumpAndSettle();
      action = tester.getRect(find.byKey(const ValueKey('otp-verify-submit')));
      expect(action.top, greaterThanOrEqualTo(0));
      expect(action.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    lastPushed = route;
    super.didPush(route, previousRoute);
  }
}
