import 'package:flutter/material.dart' show ThemeMode;

enum GridDensity {
  /// More, smaller cards per row.
  compact(maxCardWidth: 130),

  /// Fewer, larger cards per row.
  comfortable(maxCardWidth: 180);

  const GridDensity({required this.maxCardWidth});

  final double maxCardWidth;
}

/// User preferences, persisted on the device.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.animationsEnabled = true,
    this.gridDensity = GridDensity.comfortable,
  });

  final ThemeMode themeMode;
  final bool animationsEnabled;
  final GridDensity gridDensity;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? animationsEnabled,
    GridDensity? gridDensity,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      gridDensity: gridDensity ?? this.gridDensity,
    );
  }
}
