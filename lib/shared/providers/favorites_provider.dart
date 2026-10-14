import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_preferences_provider.dart';
import '../datasources/favorites_local_datasource.dart';

final favoritesDataSourceProvider = Provider<FavoritesLocalDataSource>(
  (ref) => FavoritesLocalDataSource(ref.watch(sharedPreferencesProvider)),
);

/// Favorite Pokédex numbers, newest first. Shared state: read by list cards,
/// the details page and the favorites screen.
class FavoritesNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => ref.read(favoritesDataSourceProvider).load();

  /// Updates the UI immediately, then persists.
  Future<void> toggle(int pokemonId) {
    state = state.contains(pokemonId)
        ? [...state.where((id) => id != pokemonId)]
        : [pokemonId, ...state];
    return ref.read(favoritesDataSourceProvider).save(state);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<int>>(FavoritesNotifier.new);

/// Rebuilds a widget only when this one Pokémon's favorite status changes.
final isFavoriteProvider = Provider.family<bool, int>(
  (ref, id) => ref.watch(favoritesProvider.select((ids) => ids.contains(id))),
);
