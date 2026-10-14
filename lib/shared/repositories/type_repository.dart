import '../../core/errors/app_exception.dart';
import '../datasources/pokeapi_datasource.dart';
import '../models/pokemon_type.dart';
import '../models/pokemon_types.dart';

/// Type data (damage relations + members), cached in memory.
class TypeRepository {
  TypeRepository(this._dataSource);

  final PokeApiDataSource _dataSource;
  final Map<String, PokemonType> _cache = {};
  Map<int, List<String>>? _typeIndex;

  Future<PokemonType> getType(String name) async {
    final key = name.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchType(key);
    final PokemonType type;
    try {
      type = PokemonType.fromJson(json);
    } catch (_) {
      throw const ParsingException();
    }
    _cache[key] = type;
    return type;
  }

  /// National Dex number -> its types in slot order, for all 1025 Pokémon.
  /// One request per type (18), cached. Alternate forms (id >= 10000) are
  /// left out.
  Future<Map<int, List<String>>> getTypeIndex() async {
    final cached = _typeIndex;
    if (cached != null) return cached;

    final all = await Future.wait(allPokemonTypes.map(getType));
    final slots = <int, Map<int, String>>{};
    for (final type in all) {
      for (final m in type.members) {
        if (m.pokemon.id >= 10000) continue;
        (slots[m.pokemon.id] ??= {})[m.slot] = type.name;
      }
    }
    return _typeIndex = {
      for (final entry in slots.entries)
        entry.key: [
          for (final slot in (entry.value.keys.toList()..sort()))
            entry.value[slot]!,
        ],
    };
  }
}
