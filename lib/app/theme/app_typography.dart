import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fredoka for headings and numbers, Nunito for everything else.
abstract final class AppTypography {
  /// Heading style (page titles, card names, section titles).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Rebuilds [base] (Flutter's default sizes) with Nunito, and Fredoka for
  /// the large heading styles.
  static TextTheme textTheme(TextTheme base, Color color) {
    TextStyle? nunito(TextStyle? s) =>
        s == null ? null : GoogleFonts.nunito(textStyle: s.copyWith(color: color));

    TextStyle? fredoka(TextStyle? s, FontWeight weight) => s == null
        ? null
        : GoogleFonts.fredoka(
            textStyle: s.copyWith(color: color),
            fontWeight: weight,
          );

    return TextTheme(
      displayLarge: fredoka(base.displayLarge, FontWeight.w700),
      displayMedium: fredoka(base.displayMedium, FontWeight.w700),
      displaySmall: fredoka(base.displaySmall, FontWeight.w700),
      headlineLarge: fredoka(base.headlineLarge, FontWeight.w700),
      headlineMedium: fredoka(base.headlineMedium, FontWeight.w700),
      headlineSmall: fredoka(base.headlineSmall, FontWeight.w600),
      titleLarge: fredoka(base.titleLarge, FontWeight.w600),
      titleMedium: nunito(base.titleMedium),
      titleSmall: nunito(base.titleSmall),
      bodyLarge: nunito(base.bodyLarge),
      bodyMedium: nunito(base.bodyMedium),
      bodySmall: nunito(base.bodySmall),
      labelLarge: nunito(base.labelLarge),
      labelMedium: nunito(base.labelMedium),
      labelSmall: nunito(base.labelSmall),
    );
  }
}

/// Monospaced numerals (Pokédex numbers, multipliers, stat values).
TextStyle monoStyle(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return GoogleFonts.geistMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}
