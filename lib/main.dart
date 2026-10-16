import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/localization/locale_scope.dart';
import 'core/theme/app_color.dart';
import 'presentaion/screens/splash_screen/splash_screen.dart';
import 'utils/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = LocaleController();
  runApp(LocaleScope(controller: localeController, child: const SanadApp()));
  localeController.load();
}

class SanadApp extends StatelessWidget {
  const SanadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.localeController.locale.languageCode == 'ar';

    return MaterialApp(
      title: 'SANAD',
      debugShowCheckedModeBanner: false,
      theme: AppColor.theme(isArabic: isArabic),
      locale: context.localeController.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      localeResolutionCallback: (locale, supported) => supported.firstWhere(
        (item) => item.languageCode == locale?.languageCode,
        orElse: () => supported.first,
      ),
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const SplashScreen(),
    );
  }
}
