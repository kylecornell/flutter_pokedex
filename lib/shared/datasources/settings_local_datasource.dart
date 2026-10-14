import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Reads and writes [AppSettings]. Missing or unknown values fall back to
/// defaults so an old or corrupted file never breaks startup.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._prefs);

  static const _themeKey = 'settings_theme_mode';
  static const _animationsKey = 'settings_animations';
  static const _densityKey = 'settings_grid_density';

  final SharedPreferences _prefs;

  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ??
          defaults.themeMode,
      animationsEnabled:
          _prefs.getBool(_animationsKey) ?? defaults.animationsEnabled,
      gridDensity:
          GridDensity.values.asNameMap()[_prefs.getString(_densityKey)] ??
              defaults.gridDensity,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_themeKey, settings.themeMode.name);
    await _prefs.setBool(_animationsKey, settings.animationsEnabled);
    await _prefs.setString(_densityKey, settings.gridDensity.name);
  }
}
