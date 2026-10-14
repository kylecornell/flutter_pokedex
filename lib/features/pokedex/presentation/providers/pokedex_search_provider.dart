import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/pokemon_providers.dart';

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

final pokedexSearchResultsProvider =
    Provider<AsyncValue<List<PokemonSummary>>>((ref) {
  final query = ref.watch(pokedexSearchQueryProvider);
  return ref
      .watch(pokemonIndexProvider)
      .whenData((all) => filterPokemon(all, query));
});
