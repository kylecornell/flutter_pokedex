import '../../core/network/api_client.dart';

/// Knows PokéAPI URLs. Returns raw JSON; parsing happens in the repository.
class PokeApiDataSource {
  PokeApiDataSource(this._client);

  final ApiClient _client;

  /// Name + url of every species (the National Pokédex, no alternate forms).
  Future<Map<String, dynamic>> fetchSpeciesList({int limit = 2000}) {
    return _client.getJson(
      'pokemon-species',
      query: {'limit': '$limit', 'offset': '0'},
    );
  }

  /// [idOrName] is a Pokédex number (`25`) or a name (`pikachu`).
  Future<Map<String, dynamic>> fetchPokemon(String idOrName) {
    return _client.getJson('pokemon/${idOrName.toLowerCase()}');
  }

  Future<Map<String, dynamic>> fetchSpecies(String name) {
    return _client.getJson('pokemon-species/${name.toLowerCase()}');
  }

  Future<Map<String, dynamic>> fetchEvolutionChain(int id) {
    return _client.getJson('evolution-chain/$id');
  }

  /// [name] is a type name such as `fire`.
  Future<Map<String, dynamic>> fetchType(String name) {
    return _client.getJson('type/${name.toLowerCase()}');
  }

  Future<Map<String, dynamic>> fetchAbility(String name) {
    return _client.getJson('ability/${name.toLowerCase()}');
  }

  Future<Map<String, dynamic>> fetchMove(String name) {
    return _client.getJson('move/${name.toLowerCase()}');
  }
}
