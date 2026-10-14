import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/models/pokemon_types.dart';

/// Pure type-chart math. No Flutter, no network, easy to test.
///
/// Dual types multiply: a Grass/Steel defender hit by Fire takes
/// 2 (grass) x 2 (steel) = 4x.
abstract final class TypeEffectivenessService {
  /// [attacker] hitting a Pokémon of [defenderTypes] (1 or 2 types).
  static double attackMultiplier(
    PokemonType attacker,
    List<String> defenderTypes,
  ) {
    return defenderTypes.fold(
      1.0,
      (m, d) => m * attacker.attackMultiplierAgainst(d),
    );
  }

  /// Multiplier of [attacker] against each single type.
  static Map<String, double> attackChart(
    PokemonType attacker, {
    List<String> types = allPokemonTypes,
  }) {
    return {for (final t in types) t: attacker.attackMultiplierAgainst(t)};
  }

  /// Multiplier each attacking type deals to a Pokémon with [defenders]
  /// (1 or 2 types).
  static Map<String, double> defenseChart(
    List<PokemonType> defenders, {
    List<String> types = allPokemonTypes,
  }) {
    return {
      for (final attacker in types)
        attacker: defenders.fold(
          1.0,
          (m, d) => m * d.defenseMultiplierFrom(attacker),
        ),
    };
  }

  /// `{fire: 2, water: 0.5, ...}` -> `{2: [fire], 0.5: [water]}`,
  /// highest multiplier first.
  static Map<double, List<String>> groupByMultiplier(
    Map<String, double> chart,
  ) {
    final grouped = <double, List<String>>{};
    for (final entry in chart.entries) {
      grouped.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: grouped[k]!};
  }
}
