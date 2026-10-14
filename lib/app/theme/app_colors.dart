import 'package:flutter/material.dart';

/// Design tokens from the Pokédex design (light + dark).
///
/// Read with `context.palette`. Material widgets also pick these up through
/// the [ColorScheme] built in `app_theme.dart`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.accentForeground,
    required this.success,
    required this.destructive,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color accentForeground;
  final Color success;
  final Color destructive;

  static const light = AppPalette(
    background: Color(0xFFFBF7F1),
    foreground: Color(0xFF1E1A24),
    card: Color(0xFFFFFFFF),
    secondary: Color(0xFFFFF4CC),
    secondaryForeground: Color(0xFF5A4300),
    muted: Color(0xFFF4EEE6),
    mutedForeground: Color(0xFF6C6574),
    border: Color(0xFFECE3D7),
    primary: Color(0xFFE3350D),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0xFFFDE7E1),
    accentForeground: Color(0xFFB3260A),
    success: Color(0xFF16A34A),
    destructive: Color(0xFFDC2626),
  );

  static const dark = AppPalette(
    background: Color(0xFF15131C),
    foreground: Color(0xFFF6F2EA),
    card: Color(0xFF201D29),
    secondary: Color(0xFF2A2635),
    secondaryForeground: Color(0xFFF6F2EA),
    muted: Color(0xFF26222F),
    mutedForeground: Color(0xFFA8A1B3),
    border: Color(0xFF332E3F),
    primary: Color(0xFFFF4B2B),
    onPrimary: Color(0xFFFFFFFF),
    accent: Color(0x2EFF4B2B), // 18% opacity primary
    accentForeground: Color(0xFFFF8A70),
    success: Color(0xFF4ADE80),
    destructive: Color(0xFFF87171),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      foreground: l(foreground, other.foreground),
      card: l(card, other.card),
      secondary: l(secondary, other.secondary),
      secondaryForeground: l(secondaryForeground, other.secondaryForeground),
      muted: l(muted, other.muted),
      mutedForeground: l(mutedForeground, other.mutedForeground),
      border: l(border, other.border),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      accentForeground: l(accentForeground, other.accentForeground),
      success: l(success, other.success),
      destructive: l(destructive, other.destructive),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Brand colors used outside the light/dark palette (hero header, Pokéball).
abstract final class AppBrand {
  static const pokedexRed = Color(0xFFE3350D);
  static const pokedexRedDark = Color(0xFFC8280A);
  static const pikachuYellow = Color(0xFFFFCB05);
  static const pokemonBlue = Color(0xFF3B9BEA);
}
