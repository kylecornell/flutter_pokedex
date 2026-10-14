import '../../core/errors/app_exception.dart';
import '../datasources/pokeapi_datasource.dart';
import '../models/evolution_chain.dart';
import '../models/move_info.dart';
import '../models/pokemon.dart';
import '../models/pokemon_species.dart';
import '../models/pokemon_summary.dart';

/// Single entry point for Pokémon data. Parses JSON into models and keeps an
/// in-memory cache so screens never trigger duplicate requests.
class PokemonRepository {
  PokemonRepository(this._dataSource);

  final PokeApiDataSource _dataSource;
  final Map<String, Pokemon> _pokemon = {};
  final Map<String, PokemonSpecies> _species = {};
  final Map<String, EvolutionChain?> _evolution = {};
  final Map<String, String> _abilities = {};
  final Map<String, MoveInfo> _moves = {};
  List<PokemonSummary>? _index;

  /// Every species' id + name in one request (the National Pokédex).
  /// Cached; used for the list, search and favorites.
  Future<List<PokemonSummary>> getIndex() async {
    final cached = _index;
    if (cached != null) return cached;
    final json = await _dataSource.fetchSpeciesList();
    final page = _parse(() => PokemonPage.fromJson(json));
    return _index = page.items;
  }

  /// [idOrName] is a Pokédex number or a name.
  Future<Pokemon> getPokemon(String idOrName) async {
    final key = idOrName.toLowerCase();
    final cached = _pokemon[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchPokemon(key);
    final pokemon = _parse(() => Pokemon.fromJson(json));
    _pokemon[pokemon.id.toString()] = pokemon;
    _pokemon[pokemon.name] = pokemon;
    return pokemon;
  }

  /// [idOrName] is a species number or name.
  Future<PokemonSpecies> getSpecies(String idOrName) async {
    final key = idOrName.toLowerCase();
    final cached = _species[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchSpecies(key);
    final species = _parse(() => PokemonSpecies.fromJson(json));
    _species[key] = species;
    _species[species.name] = species;
    return species;
  }

  /// Evolution family of a species, or null when the API lists none.
  Future<EvolutionChain?> getEvolutionChain(String speciesName) async {
    final key = speciesName.toLowerCase();
    if (_evolution.containsKey(key)) return _evolution[key];

    final species = await getSpecies(key);
    final url = species.evolutionChainUrl;

    EvolutionChain? chain;
    if (url != null) {
      final json = await _dataSource.fetchEvolutionChain(idFromUrl(url));
      chain = _parse(() => EvolutionChain.fromJson(json));
    }
    _evolution[key] = chain;
    return chain;
  }

  /// Short English effect text of an ability.
  Future<String> getAbilityDescription(String name) async {
    final key = name.toLowerCase();
    final cached = _abilities[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchAbility(key);
    final description = _parse(() {
      List<Map<String, dynamic>> english(String field) =>
          (json[field] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()
              .where(
                (e) =>
                    (e['language'] as Map<String, dynamic>?)?['name'] == 'en',
              )
              .toList();

      final effects = english('effect_entries');
      if (effects.isNotEmpty) {
        final short = effects.first['short_effect'] as String?;
        if (short != null && short.isNotEmpty) return short;
      }
      final flavors = english('flavor_text_entries');
      if (flavors.isNotEmpty) {
        final text = flavors.last['flavor_text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
      }
      return 'No description available.';
    });
    return _abilities[key] = description;
  }

  Future<MoveInfo> getMove(String name) async {
    final key = name.toLowerCase();
    final cached = _moves[key];
    if (cached != null) return cached;

    final json = await _dataSource.fetchMove(key);
    return _moves[key] = _parse(() => MoveInfo.fromJson(json));
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
