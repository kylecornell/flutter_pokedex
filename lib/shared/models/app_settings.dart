import 'package:flutter/material.dart' show ThemeMode;

enum GridDensity {
  /// More, smaller cards per row.
  compact(maxCardWidth: 120),

  /// Fewer, larger cards per row.
  comfortable(maxCardWidth: 200);

  const GridDensity({required this.maxCardWidth});

  final double maxCardWidth;
}

/// How the Pokémon picture is shown on the details card.
enum ViewerMode {
  art('Artwork'),
  animated('Animated'),
  model3d('3D');

  const ViewerMode(this.label);

  final String label;
}

/// User preferences, persisted on the device.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.animationsEnabled = true,
    this.gridDensity = GridDensity.comfortable,
    this.cardEffects = true,
    this.viewerMode = ViewerMode.art,
  });

  final ThemeMode themeMode;
  final bool animationsEnabled;
  final GridDensity gridDensity;

  /// Tilt and holographic light on trading cards.
  final bool cardEffects;

  /// Mode used when a Pokémon is opened.
  final ViewerMode viewerMode;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? animationsEnabled,
    GridDensity? gridDensity,
    bool? cardEffects,
    ViewerMode? viewerMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      gridDensity: gridDensity ?? this.gridDensity,
      cardEffects: cardEffects ?? this.cardEffects,
      viewerMode: viewerMode ?? this.viewerMode,
    );
  }
}
