import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Page transition that shows the new page instantly.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

abstract final class AppTheme {
  /// [animations] false removes page transitions (Settings > Animations).
  static ThemeData light({bool animations = true}) =>
      _build(Brightness.light, animations);

  static ThemeData dark({bool animations = true}) =>
      _build(Brightness.dark, animations);

  static ThemeData _build(Brightness brightness, bool animations) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ),
      pageTransitionsTheme: animations
          ? null
          : PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: const _NoTransitionsBuilder(),
              },
            ),
    );
  }
}
