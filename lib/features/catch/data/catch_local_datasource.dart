import 'package:shared_preferences/shared_preferences.dart';

/// Persists the catch game: caught Pokédex numbers and Master Balls left.
class CatchLocalDataSource {
  CatchLocalDataSource(this._prefs);

  static const _caughtKey = 'catch_caught_ids';
  static const _masterKey = 'catch_master_balls';

  /// One Master Ball to start with.
  static const initialMasterBalls = 1;

  final SharedPreferences _prefs;

  Set<int> loadCaught() => {
        for (final raw in _prefs.getStringList(_caughtKey) ?? const <String>[])
          ?int.tryParse(raw),
      };

  int loadMasterBalls() => _prefs.getInt(_masterKey) ?? initialMasterBalls;

  Future<void> saveCaught(Set<int> ids) =>
      _prefs.setStringList(_caughtKey, [for (final id in ids) '$id']);

  Future<void> saveMasterBalls(int count) => _prefs.setInt(_masterKey, count);
}
