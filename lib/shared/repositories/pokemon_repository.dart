import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../datasources/pokeapi_datasource.dart';
import '../models/pokemon.dart';
import '../models/pokemon_summary.dart';

/// Single entry point for Pokémon data. Parses JSON into models and keeps an
/// in-memory cache so screens never trigger duplicate requests.
class PokemonRepository {
  PokemonRepository(this._dataSource);

  /// Comfortably above the ~1350 entries PokéAPI currently lists.
  static const _indexLimit = 3000;

  final PokeApiDataSource _dataSource;
  final Map<String, Pokemon> _cache = {};
  List<PokemonSummary>? _index;

  Future<PokemonPage> getPage({
    int limit = ApiConstants.defaultPageSize,
    int offset = 0,
  }) async {
    final json = await _dataSource.fetchPokemonPage(limit: limit, offset: offset);
    return _parse(() => PokemonPage.fromJson(json));
  }

  /// Every Pokémon's id + name in one request. Cached; used for search.
  Future<List<PokemonSummary>> getIndex() async {
    final cached = _index;
    if (cached != null) return cached;
    final page = await getPage(limit: _indexLimit);
    return _index = page.items;
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
