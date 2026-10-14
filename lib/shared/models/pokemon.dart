import 'pokemon_summary.dart';

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

/// An ability slot of a Pokémon.
class PokemonAbility {
  const PokemonAbility({required this.name, required this.isHidden});

  final String name;
  final bool isHidden;
}

/// A move a Pokémon can learn and how.
class LearnedMove {
  const LearnedMove({
    required this.name,
    required this.method,
    required this.level,
  });

  final String name;

  /// `level-up`, `machine`, `egg`, `tutor`, ...
  final String method;
  final int level;
}

/// Full Pokémon data from `GET /pokemon/{id}`.
class Pokemon {
  const Pokemon({
    required this.id,
    required this.name,
    required this.speciesName,
    required this.types,
    required this.heightDm,
    required this.weightHg,
    required this.stats,
    required this.artworkUrl,
    this.baseExperience,
    this.abilities = const [],
    this.moves = const [],
    this.versionGroupName = '',
  });

  /// Throws if `id` is missing/wrong type (callers map that to ParsingException).
  /// Every other field falls back to a safe default.
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final name = json['name'] as String? ?? 'unknown';

    final typeEntries = [
      for (final e in (json['types'] as List<dynamic>? ?? const []))
        e as Map<String, dynamic>,
    ]..sort(
        (a, b) => (a['slot'] as int? ?? 0).compareTo(b['slot'] as int? ?? 0),
      );
    final types = <String>[
      for (final entry in typeEntries)
        if ((entry['type'] as Map<String, dynamic>?)?['name']
            case final String name)
          name,
    ];

    final abilityEntries = [
      for (final e in (json['abilities'] as List<dynamic>? ?? const []))
        e as Map<String, dynamic>,
    ]..sort(
        (a, b) => (a['slot'] as int? ?? 0).compareTo(b['slot'] as int? ?? 0),
      );
    final abilities = [
      for (final e in abilityEntries)
        if ((e['ability'] as Map<String, dynamic>?)?['name']
            case final String abilityName)
          PokemonAbility(
            name: abilityName,
            isHidden: e['is_hidden'] as bool? ?? false,
          ),
    ];

    final (moves, versionGroup) = _parseMoves(json['moves']);

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
      name: name,
      // Alternate forms (id > 10000) share their base species' evolution data.
      speciesName: (json['species'] as Map<String, dynamic>?)?['name']
              as String? ??
          name,
      types: types,
      heightDm: json['height'] as int? ?? 0,
      weightHg: json['weight'] as int? ?? 0,
      stats: stats,
      artworkUrl: artwork,
      baseExperience: json['base_experience'] as int?,
      abilities: abilities,
      moves: moves,
      versionGroupName: versionGroup,
    );
  }

  /// Keeps the learnset of the newest game (highest version-group id), since
  /// moves differ between games.
  static (List<LearnedMove>, String) _parseMoves(Object? raw) {
    final entries = raw as List<dynamic>? ?? const [];

    int groupId(Map<String, dynamic> detail) {
      final url = (detail['version_group'] as Map<String, dynamic>?)?['url']
          as String?;
      return url == null ? 0 : idFromUrl(url);
    }

    var newest = 0;
    var newestName = '';
    for (final e in entries) {
      for (final d in (e as Map<String, dynamic>)['version_group_details']
              as List<dynamic>? ??
          const []) {
        final detail = d as Map<String, dynamic>;
        final id = groupId(detail);
        if (id > newest) {
          newest = id;
          newestName =
              (detail['version_group'] as Map<String, dynamic>)['name']
                  as String? ??
                  '';
        }
      }
    }

    const methodOrder = {'level-up': 0, 'machine': 1, 'egg': 2, 'tutor': 3};
    final seen = <String>{};
    final moves = <LearnedMove>[];
    for (final e in entries) {
      final entry = e as Map<String, dynamic>;
      final name = (entry['move'] as Map<String, dynamic>)['name'] as String;
      for (final d in entry['version_group_details'] as List<dynamic>? ??
          const []) {
        final detail = d as Map<String, dynamic>;
        if (newestName.isEmpty ||
            (detail['version_group'] as Map<String, dynamic>)['name'] !=
                newestName) {
          continue;
        }
        final method =
            (detail['move_learn_method'] as Map<String, dynamic>?)?['name']
                    as String? ??
                'level-up';
        if (!seen.add('$name|$method')) continue;
        moves.add(
          LearnedMove(
            name: name,
            method: method,
            level: detail['level_learned_at'] as int? ?? 0,
          ),
        );
      }
    }
    moves.sort((a, b) {
      final byMethod =
          (methodOrder[a.method] ?? 9).compareTo(methodOrder[b.method] ?? 9);
      if (byMethod != 0) return byMethod;
      final byLevel = a.level.compareTo(b.level);
      return byLevel != 0 ? byLevel : a.name.compareTo(b.name);
    });
    return (moves, newestName);
  }

  /// Official artwork URL derivable from the id alone (no extra request).
  static String artworkUrlForId(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  /// Small front sprite from the PokéAPI sprites repository.
  static String spriteUrlForId(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  /// Animated Showdown-style sprite (not available for every Pokémon).
  static String animatedSpriteUrlForId(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/showdown/$id.gif';

  final int id;
  final String name;

  /// Name used by `/pokemon-species/{name}`; differs from [name] for forms.
  final String speciesName;
  final List<String> types;

  /// Decimetres, as PokéAPI returns it.
  final int heightDm;

  /// Hectograms, as PokéAPI returns it.
  final int weightHg;
  final List<PokemonStat> stats;
  final String artworkUrl;

  /// XP given when defeated; null when the API does not list it.
  final int? baseExperience;
  final List<PokemonAbility> abilities;

  /// Learnset of the newest game (see [versionGroupName]).
  final List<LearnedMove> moves;
  final String versionGroupName;

  double get heightMeters => heightDm / 10;
  double get weightKg => weightHg / 10;
}
