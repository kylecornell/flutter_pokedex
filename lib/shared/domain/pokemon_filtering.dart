import '../models/generation.dart';
import '../models/pokemon_summary.dart';

enum PokemonSort { number, name }

/// Toggles [type] in a chip selection that allows at most [max] types.
/// Picking a type beyond the limit drops the oldest pick.
List<String> toggleTypeSelection(
  List<String> selected,
  String type, {
  int max = 2,
}) {
  final next = selected.contains(type)
      ? selected.where((t) => t != type).toList()
      : [...selected, type];
  return next.length > max ? next.sublist(next.length - max) : next;
}

/// Whether [pokemon] matches a search [query]: all-digit queries match the
/// start of the Pokédex number (`25`, `#25`), anything else matches names.
bool matchesQuery(PokemonSummary pokemon, String query) {
  final q = query.trim().toLowerCase().replaceFirst('#', '');
  if (q.isEmpty) return true;
  if (RegExp(r'^\d+$').hasMatch(q)) {
    return pokemon.id.toString().startsWith(int.parse(q).toString());
  }
  return pokemon.name.toLowerCase().replaceAll('-', ' ').contains(q) ||
      pokemon.name.toLowerCase().contains(q);
}

/// Applies search, type, generation and sort to the full Pokédex.
///
/// [types] are AND-ed: `[fire, flying]` keeps only Fire/Flying Pokémon.
/// Until the [typeIndex] has loaded, a type filter matches nothing.
List<PokemonSummary> filterPokemon(
  List<PokemonSummary> all, {
  String query = '',
  List<String> types = const [],
  Map<int, List<String>> typeIndex = const {},
  int generationIndex = -1,
  PokemonSort sort = PokemonSort.number,
}) {
  final generation =
      generationIndex < 0 ? null : pokemonGenerations[generationIndex];

  var result = all.where((p) {
    if (!matchesQuery(p, query)) return false;
    if (generation != null && !generation.contains(p.id)) return false;
    if (types.isNotEmpty) {
      final own = typeIndex[p.id] ?? const <String>[];
      if (!types.every(own.contains)) return false;
    }
    return true;
  }).toList();

  if (sort == PokemonSort.name) {
    result.sort((a, b) => a.name.compareTo(b.name));
  }
  return result;
}
