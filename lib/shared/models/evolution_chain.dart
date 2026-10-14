import 'pokemon_summary.dart';

/// One species in an evolution tree and what it evolves into.
class EvolutionNode {
  const EvolutionNode({
    required this.species,
    required this.evolvesTo,
    this.requirement = '',
  });

  factory EvolutionNode.fromJson(Map<String, dynamic> json) {
    final details = json['evolution_details'] as List<dynamic>? ?? const [];
    return EvolutionNode(
      // `species` is `{name, url}`; id is the species id (== Pokédex number).
      species: PokemonSummary.fromJson(json['species'] as Map<String, dynamic>),
      requirement: details.isEmpty
          ? ''
          : evolutionRequirement(details.first as Map<String, dynamic>),
      evolvesTo: (json['evolves_to'] as List<dynamic>? ?? const [])
          .map((n) => EvolutionNode.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  final PokemonSummary species;
  final List<EvolutionNode> evolvesTo;

  /// What it takes to evolve into [species], e.g. `Lv. 16` or `Thunder Stone`.
  /// Empty for the first stage.
  final String requirement;
}

String _nice(String s) => s
    .split('-')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

String _name(Object? ref) =>
    _nice((ref as Map<String, dynamic>?)?['name'] as String? ?? '');

/// Short human text for one `evolution_details` entry.
String evolutionRequirement(Map<String, dynamic> d) {
  final trigger = (d['trigger'] as Map<String, dynamic>?)?['name'] as String?;
  final timeOfDay = d['time_of_day'] as String? ?? '';
  final tod = timeOfDay.isEmpty ? '' : ' ($timeOfDay)';

  switch (trigger) {
    case 'level-up':
      final level = d['min_level'] as int?;
      if (level != null) return 'Lv. $level$tod';
      if (d['min_happiness'] != null) return 'Friendship$tod';
      if (d['min_affection'] != null) return 'Affection';
      if (d['known_move'] != null) return 'Knows ${_name(d['known_move'])}';
      if (d['known_move_type'] != null) {
        return 'Knows ${_name(d['known_move_type'])} move';
      }
      if (d['held_item'] != null) return 'Hold ${_name(d['held_item'])}$tod';
      if (d['location'] != null) return 'Level up at location';
      return 'Level up$tod';
    case 'use-item':
      return d['item'] == null ? 'Use item' : _name(d['item']);
    case 'trade':
      final held = d['held_item'];
      return 'Trade${held == null ? '' : ' + ${_name(held)}'}';
    case null:
      return '';
    default:
      return _nice(trigger);
  }
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

  /// Nodes grouped by depth: `[[Eevee], [Vaporeon, Jolteon, ...]]`.
  List<List<EvolutionNode>> get nodeStages {
    final result = <List<EvolutionNode>>[];
    var level = [root];
    while (level.isNotEmpty) {
      result.add(level);
      level = level.expand((n) => n.evolvesTo).toList();
    }
    return result;
  }

  /// Species grouped by depth, without evolution requirements.
  List<List<PokemonSummary>> get stages => [
        for (final stage in nodeStages) [for (final n in stage) n.species],
      ];
}
