import 'package:http/http.dart' as http;

/// Finds a 3D model (.glb) for a Pokémon in the community "Pokémon 3D API"
/// asset repository.
///
/// Not every Pokémon has a model, and the models are fan-made and
/// non-commercial, so this is optional: callers must handle `null`.
class Model3dRepository {
  Model3dRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? defaultBaseUrl;

  static const defaultBaseUrl =
      'https://raw.githubusercontent.com/Pokemon-3D-api/assets/main/models/opt/regular/';

  final http.Client _client;
  final String _baseUrl;
  final Map<int, String?> _cache = {};

  /// URL of the first model file that exists (`{id}.glb`, `{id}-M.glb`,
  /// `{id}-F.glb`), or null.
  Future<String?> findModel(int pokemonId) async {
    if (_cache.containsKey(pokemonId)) return _cache[pokemonId];

    String? found;
    for (final file in ['$pokemonId.glb', '$pokemonId-M.glb', '$pokemonId-F.glb']) {
      final url = '$_baseUrl$file';
      try {
        final response = await _client
            .head(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          found = url;
          break;
        }
      } catch (_) {
        // Network error or timeout: treat this candidate as missing.
      }
    }
    return _cache[pokemonId] = found;
  }
}
