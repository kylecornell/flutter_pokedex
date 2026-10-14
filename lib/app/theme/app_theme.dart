import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

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
      _build(AppPalette.light, Brightness.light, animations);

  static ThemeData dark({bool animations = true}) =>
      _build(AppPalette.dark, Brightness.dark, animations);

  static ThemeData _build(AppPalette p, Brightness brightness, bool animations) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.secondary,
      onSecondary: p.secondaryForeground,
      secondaryContainer: p.accent,
      onSecondaryContainer: p.accentForeground,
      error: p.destructive,
      onError: Colors.white,
      surface: p.background,
      onSurface: p.foreground,
      onSurfaceVariant: p.mutedForeground,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: p.card,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.muted,
      surfaceContainerHighest: p.muted,
      outline: p.border,
      outlineVariant: p.border,
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final textTheme = AppTypography.textTheme(base.textTheme, p.foreground);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: textTheme,
      extensions: [p],
      dividerColor: p.border,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.display(20, color: p.foreground),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.accent,
        side: BorderSide(color: p.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.foreground,
          side: BorderSide(color: p.border),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.foreground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: p.background,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
