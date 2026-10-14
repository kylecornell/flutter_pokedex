import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/type_providers.dart';

/// Text currently typed in the search box.
class PokedexSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final pokedexSearchQueryProvider =
    NotifierProvider<PokedexSearchQuery, String>(PokedexSearchQuery.new);

/// Name + id of every Pokémon, fetched once (needed because the API has no
/// search endpoint).
final pokemonIndexProvider = FutureProvider<List<PokemonSummary>>(
  (ref) => ref.watch(pokemonRepositoryProvider).getIndex(),
  retry: (_, _) => null, // show errors immediately; user retries manually
);

/// Matches by name substring or exact Pokédex number (`25` or `#25`).
List<PokemonSummary> filterPokemon(List<PokemonSummary> all, String query) {
  final q = query.trim().toLowerCase().replaceFirst('#', '');
  if (q.isEmpty) return all;
  return all
      .where((p) => p.name.contains(q) || p.id.toString() == q)
      .toList();
}

/// Type chip currently selected (`fire`), or null for "all types".
class PokedexTypeFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? type) => state = type;
}

final pokedexTypeFilterProvider =
    NotifierProvider<PokedexTypeFilter, String?>(PokedexTypeFilter.new);

/// Pokémon of one type, by Pokédex number. Alternate forms (id >= 10000)
/// are dropped so the list matches the main Pokédex.
final pokemonOfTypeProvider =
    FutureProvider.family<List<PokemonSummary>, String>(
  (ref, type) async {
    final data = await ref.watch(pokemonTypeProvider(type).future);
    return data.pokemon.where((p) => p.id < 10000).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  },
  retry: (_, _) => null,
);

/// Result list for search and/or type filter (not used when both are empty).
final pokedexSearchResultsProvider =
    Provider<AsyncValue<List<PokemonSummary>>>((ref) {
  final query = ref.watch(pokedexSearchQueryProvider);
  final type = ref.watch(pokedexTypeFilterProvider);
  final source = type == null
      ? ref.watch(pokemonIndexProvider)
      : ref.watch(pokemonOfTypeProvider(type));
  return source.whenData((all) => filterPokemon(all, query));
});
