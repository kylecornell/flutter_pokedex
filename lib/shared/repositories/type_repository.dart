import '../../core/errors/app_exception.dart';
import '../datasources/pokeapi_datasource.dart';
import '../models/pokemon_type.dart';

/// Type data (damage relations + members), cached in memory.
class TypeRepository {
  TypeRepository(this._dataSource);

  final PokeApiDataSource _dataSource;
  final Map<String, PokemonType> _cache = {};

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
}
