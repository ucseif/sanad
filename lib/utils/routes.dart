import 'package:flutter/material.dart';

import '../presentaion/screens/splash_screen/splash_screen.dart';
import '../presentaion/screens/home_screen/home_screen.dart';
import '../presentaion/screens/language_screen/language_screen.dart';
import '../presentaion/screens/onboarding/onboarding_screen.dart';

abstract final class AppRoutes {
  static const String splash = SplashScreen.routeName;
  static const String language = LanguageScreen.routeName;
  static const String home = '/home';
  static const String onboarding = OnboardingScreen.routeName;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
      case null:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case language:
        return MaterialPageRoute<void>(
          builder: (_) => const LanguageScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(),
          settings: settings,
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Page not found')));
  }
}
