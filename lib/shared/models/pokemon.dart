/// One base stat, e.g. `hp: 35`.
class PokemonStat {
  const PokemonStat({required this.name, required this.value});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    final stat = json['stat'] as Map<String, dynamic>?;
    return PokemonStat(
      name: stat?['name'] as String? ?? 'unknown',
      value: json['base_stat'] as int? ?? 0,
    );
  }

  final String name;
  final int value;
}

/// Full Pokémon data from `GET /pokemon/{id}`.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.heightDm,
    required this.weightHg,
    required this.stats,
    required this.artworkUrl,
  });

  /// Throws if `id` is missing/wrong type (callers map that to ParsingException).
  /// Every other field falls back to a safe default.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;

    final types = <String>[];
    for (final entry in (json['types'] as List<dynamic>? ?? const [])) {
      final name = ((entry as Map<String, dynamic>)['type']
          as Map<String, dynamic>?)?['name'] as String?;
      if (name != null) types.add(name);
    }

    final stats = (json['stats'] as List<dynamic>? ?? const [])
        .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
        .toList();

    final sprites = json['sprites'] as Map<String, dynamic>?;
    final other = sprites?['other'] as Map<String, dynamic>?;
    final official = other?['official-artwork'] as Map<String, dynamic>?;
    final artwork = official?['front_default'] as String? ??
        sprites?['front_default'] as String? ??
        artworkUrlForId(id);

    return Pokemon(
      id: id,
      name: json['name'] as String? ?? 'unknown',
      types: types,
      heightDm: json['height'] as int? ?? 0,
      weightHg: json['weight'] as int? ?? 0,
      stats: stats,
      artworkUrl: artwork,
    );
  }

  /// Official artwork URL derivable from the id alone (no extra request).
  static String artworkUrlForId(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  final int id;
  final String name;
  final List<String> types;

  /// Decimetres, as PokéAPI returns it.
  final int heightDm;

  /// Hectograms, as PokéAPI returns it.
  final int weightHg;
  final List<PokemonStat> stats;
  final String artworkUrl;

  double get heightMeters => heightDm / 10;
  double get weightKg => weightHg / 10;
}
