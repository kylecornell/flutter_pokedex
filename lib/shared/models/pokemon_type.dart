import 'pokemon_summary.dart';

/// A Pokémon that has a type, and whether it is its first or second type.
class TypeMember {
  const TypeMember({required this.pokemon, required this.slot});

  final PokemonSummary pokemon;

  /// 1 = primary type, 2 = secondary type.
  final int slot;
}

/// One type with its damage relations, from `GET /type/{name}`.
///
/// "To" = this type attacking, "from" = this type defending.
class PokemonType {
  const PokemonType({
    required this.name,
    this.doubleDamageTo = const {},
    this.halfDamageTo = const {},
    this.noDamageTo = const {},
    this.doubleDamageFrom = const {},
    this.halfDamageFrom = const {},
    this.noDamageFrom = const {},
    this.members = const [],
  });

  factory PokemonType.fromJson(Map<String, dynamic> json) {
    final relations = json['damage_relations'] as Map<String, dynamic>? ?? {};

    Set<String> names(String key) => (relations[key] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .toSet();

    final members = (json['pokemon'] as List<dynamic>? ?? []).map((e) {
      final entry = e as Map<String, dynamic>;
      return TypeMember(
        pokemon: PokemonSummary.fromJson(
          entry['pokemon'] as Map<String, dynamic>,
        ),
        slot: entry['slot'] as int? ?? 1,
      );
    }).toList();

    return PokemonType(
      name: json['name'] as String? ?? 'unknown',
      doubleDamageTo: names('double_damage_to'),
      halfDamageTo: names('half_damage_to'),
      noDamageTo: names('no_damage_to'),
      doubleDamageFrom: names('double_damage_from'),
      halfDamageFrom: names('half_damage_from'),
      noDamageFrom: names('no_damage_from'),
      members: members,
    );
  }

  final String name;
  final Set<String> doubleDamageTo;
  final Set<String> halfDamageTo;
  final Set<String> noDamageTo;
  final Set<String> doubleDamageFrom;
  final Set<String> halfDamageFrom;
  final Set<String> noDamageFrom;

  /// Every Pokémon (and form) of this type, with which type slot it fills.
  final List<TypeMember> members;

  List<PokemonSummary> get pokemon => [for (final m in members) m.pokemon];

  /// Damage multiplier when this type attacks a single [defender] type.
  double attackMultiplierAgainst(String defender) {
    if (noDamageTo.contains(defender)) return 0;
    if (doubleDamageTo.contains(defender)) return 2;
    if (halfDamageTo.contains(defender)) return 0.5;
    return 1;
  }

  /// Damage multiplier when this type is hit by a single [attacker] type.
  double defenseMultiplierFrom(String attacker) {
    if (noDamageFrom.contains(attacker)) return 0;
    if (doubleDamageFrom.contains(attacker)) return 2;
    if (halfDamageFrom.contains(attacker)) return 0.5;
    return 1;
  }
}
