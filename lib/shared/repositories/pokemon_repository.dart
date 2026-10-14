import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../datasources/pokeapi_datasource.dart';
import '../models/pokemon.dart';
import '../models/pokemon_summary.dart';

/// Single entry point for Pokémon data. Parses JSON into models and keeps an
/// in-memory cache so screens never trigger duplicate requests.
class PokemonRepository {
  PokemonRepository(this._dataSource);

  final PokeApiDataSource _dataSource;
  final Map<String, Pokemon> _cache = {};

  Future<PokemonPage> getPage({
    int limit = ApiConstants.defaultPageSize,
    int offset = 0,
  }) async {
    final json = await _dataSource.fetchPokemonPage(limit: limit, offset: offset);
    return _parse(() => PokemonPage.fromJson(json));
  }

  /// [idOrName] is a Pokédex number or a name.
  Future<Pokemon> getPokemon(String idOrName) async {
    final key = idOrName.toLowerCase();
    final cached = _cache[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchPokemon(key);
    final pokemon = _parse(() => Pokemon.fromJson(json));
    _cache[pokemon.id.toString()] = pokemon;
    _cache[pokemon.name] = pokemon;
    return pokemon;
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ParsingException();
    }
  }
}
