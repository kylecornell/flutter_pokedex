import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_preferences_provider.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings.dart';

final settingsDataSourceProvider = Provider<SettingsLocalDataSource>(
  (ref) => SettingsLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

/// App-wide preferences. Shared state: the app shell reads theme and
/// animations, the grid reads density, the settings screen writes them.
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsDataSourceProvider).load();

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setAnimationsEnabled(bool enabled) =>
      _update(state.copyWith(animationsEnabled: enabled));

  Future<void> setGridDensity(GridDensity density) =>
      _update(state.copyWith(gridDensity: density));

  Future<void> setCardEffects(bool enabled) =>
      _update(state.copyWith(cardEffects: enabled));

  Future<void> setViewerMode(ViewerMode mode) =>
      _update(state.copyWith(viewerMode: mode));

  Future<void> _update(AppSettings next) {
    state = next;
    return ref.read(settingsDataSourceProvider).save(next);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
