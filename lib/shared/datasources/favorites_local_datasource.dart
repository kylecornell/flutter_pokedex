import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite Pokédex numbers on the device.
///
/// No separate repository: it would only forward these two calls.
class FavoritesLocalDataSource {
  FavoritesLocalDataSource(this._prefs);

  static const _key = 'favorite_pokemon_ids';

  final SharedPreferences _prefs;

  /// Newest first. Corrupt entries are skipped instead of crashing the app.
  List<int> load() {
    final stored = _prefs.getStringList(_key) ?? const [];
    return [
      for (final raw in stored) ?int.tryParse(raw),
    ];
  }

  Future<void> save(List<int> ids) {
    return _prefs.setStringList(_key, [for (final id in ids) '$id']);
  }
}
