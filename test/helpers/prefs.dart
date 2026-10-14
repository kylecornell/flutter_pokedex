import 'package:flutter_riverpod/misc.dart';
import 'package:pokedex_app/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider override backed by in-memory SharedPreferences.
Future<Override> prefsOverride([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return sharedPreferencesProvider.overrideWithValue(prefs);
}
