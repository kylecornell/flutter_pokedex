import 'pokemon.dart';

/// `https://pokeapi.co/api/v2/pokemon/25/` -> `25`
int idFromUrl(String url) {
  final segments = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
  return int.parse(segments.last);
}

/// Lightweight list entry from `GET /pokemon?limit=&offset=`.
class PokemonSummary {
  const PokemonSummary({required this.id, required this.name});

  /// The list endpoint gives `{name, url}`; id is the last URL segment.
  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    return PokemonSummary(
      id: idFromUrl(json['url'] as String),
      name: json['name'] as String? ?? 'unknown',
    );
  }

  final int id;
  final String name;

  String get artworkUrl => Pokemon.artworkUrlForId(id);

  /// Small pixel sprite, good for suggestion rows and chips.
  String get spriteUrl => Pokemon.spriteUrlForId(id);
}

/// One page of the list endpoint.
class PokemonPage {
  const PokemonPage({
    required this.items,
    required this.totalCount,
    required this.hasNext,
  });

  factory PokemonPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? const [])
        .map((r) => PokemonSummary.fromJson(r as Map<String, dynamic>))
        .toList();
    return PokemonPage(
      items: results,
      totalCount: json['count'] as int? ?? results.length,
      hasNext: json['next'] != null,
    );
  }

  final List<PokemonSummary> items;
  final int totalCount;
  final bool hasNext;
}
