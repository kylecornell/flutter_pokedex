import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Knows PokéAPI URLs. Returns raw JSON; parsing happens in the repository.
class PokeApiDataSource {
  PokeApiDataSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetchPokemonPage({
    int limit = ApiConstants.defaultPageSize,
    int offset = 0,
  }) {
    return _client.getJson(
      'pokemon',
      query: {'limit': '$limit', 'offset': '$offset'},
    );
  }

  /// [idOrName] is a Pokédex number (`25`) or a name (`pikachu`).
  Future<Map<String, dynamic>> fetchPokemon(String idOrName) {
    return _client.getJson('pokemon/${idOrName.toLowerCase()}');
  }
}
