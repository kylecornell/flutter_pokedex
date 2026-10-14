import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/datasources/settings_local_datasource.dart';
import 'package:pokedex_app/shared/models/app_settings.dart';
import 'package:pokedex_app/shared/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/prefs.dart';

void main() {
  group('SettingsLocalDataSource', () {
    test('defaults when nothing stored', () async {
      SharedPreferences.setMockInitialValues({});
      final ds =
          SettingsLocalDataSource(await SharedPreferences.getInstance());
      final s = ds.load();
      expect(s.themeMode, ThemeMode.system);
      expect(s.animationsEnabled, isTrue);
      expect(s.gridDensity, GridDensity.comfortable);
      expect(s.cardEffects, isTrue);
      expect(s.viewerMode, ViewerMode.art);
    });

    test('round-trips all fields', () async {
      SharedPreferences.setMockInitialValues({});
      final ds =
          SettingsLocalDataSource(await SharedPreferences.getInstance());
      await ds.save(const AppSettings(
        themeMode: ThemeMode.dark,
        animationsEnabled: false,
        gridDensity: GridDensity.compact,
        cardEffects: false,
        viewerMode: ViewerMode.model3d,
      ));
      final s = ds.load();
      expect(s.themeMode, ThemeMode.dark);
      expect(s.animationsEnabled, isFalse);
      expect(s.gridDensity, GridDensity.compact);
      expect(s.cardEffects, isFalse);
      expect(s.viewerMode, ViewerMode.model3d);
    });

    test('unknown stored values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'settings_theme_mode': 'neon',
        'settings_grid_density': 42.toString(),
      });
      final ds =
          SettingsLocalDataSource(await SharedPreferences.getInstance());
      final s = ds.load();
      expect(s.themeMode, ThemeMode.system);
      expect(s.gridDensity, GridDensity.comfortable);
    });
  });

  test('SettingsNotifier updates state and persists', () async {
    final c = ProviderContainer(overrides: [await prefsOverride()]);
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);

    await n.setThemeMode(ThemeMode.light);
    await n.setAnimationsEnabled(false);
    await n.setGridDensity(GridDensity.compact);
    await n.setCardEffects(false);
    await n.setViewerMode(ViewerMode.animated);

    final s = c.read(settingsProvider);
    expect(s.themeMode, ThemeMode.light);
    expect(s.animationsEnabled, isFalse);
    expect(s.gridDensity, GridDensity.compact);
    expect(s.cardEffects, isFalse);
    expect(s.viewerMode, ViewerMode.animated);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_theme_mode'), 'light');
    expect(prefs.getBool('settings_animations'), isFalse);
    expect(prefs.getString('settings_grid_density'), 'compact');
    expect(prefs.getBool('settings_card_effects'), isFalse);
    expect(prefs.getString('settings_viewer_mode'), 'animated');
  });
}
