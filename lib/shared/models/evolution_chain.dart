import 'pokemon_summary.dart';

/// One species in an evolution tree and what it evolves into.
class EvolutionNode {
  const EvolutionNode({required this.species, required this.evolvesTo});

  factory EvolutionNode.fromJson(Map<String, dynamic> json) {
    return EvolutionNode(
      // `species` is `{name, url}`; id is the species id (== Pokédex number).
      species: PokemonSummary.fromJson(json['species'] as Map<String, dynamic>),
      evolvesTo: (json['evolves_to'] as List<dynamic>? ?? const [])
          .map((n) => EvolutionNode.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  final PokemonSummary species;
  final List<EvolutionNode> evolvesTo;
}

/// Evolution family from `GET /evolution-chain/{id}`.
class EvolutionChain {
  const EvolutionChain({required this.root});

  factory EvolutionChain.fromJson(Map<String, dynamic> json) {
    return EvolutionChain(
      root: EvolutionNode.fromJson(json['chain'] as Map<String, dynamic>),
    );
  }

  final EvolutionNode root;

  /// Species grouped by depth: `[[Eevee], [Vaporeon, Jolteon, ...]]`.
  List<List<PokemonSummary>> get stages {
    final result = <List<PokemonSummary>>[];
    var level = [root];
    while (level.isNotEmpty) {
      result.add(level.map((n) => n.species).toList());
      level = level.expand((n) => n.evolvesTo).toList();
    }
    return result;
  }
}
