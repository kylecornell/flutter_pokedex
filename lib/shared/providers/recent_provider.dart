import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_preferences_provider.dart';

/// Most recently opened Pokédex numbers, newest first (max 10).
class RecentNotifier extends Notifier<List<int>> {
  static const _key = 'recent_pokemon_ids';
  static const _max = 10;

  @override
  List<int> build() {
    final stored =
        ref.read(sharedPreferencesProvider).getStringList(_key) ?? const [];
    return [for (final raw in stored) ?int.tryParse(raw)];
  }

  Future<void> add(int pokemonId) {
    state = [pokemonId, ...state.where((id) => id != pokemonId)]
        .take(_max)
        .toList();
    return ref
        .read(sharedPreferencesProvider)
        .setStringList(_key, [for (final id in state) '$id']);
  }
}

final recentProvider =
    NotifierProvider<RecentNotifier, List<int>>(RecentNotifier.new);
