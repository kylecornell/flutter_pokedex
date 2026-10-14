import 'dart:math' as math;
import 'dart:ui';

import '../../../core/utils/text_format.dart';
import '../../../shared/models/pokemon_types.dart';

/// Whether the explorer shows what the selected type deals or what it takes.
enum MatchupMode { attack, defense }

/// Label for a multiplier: `0×`, `0.25×`, `0.5×`, `1×`, `2×`, `4×`.
String formatMultiplier(double m) =>
    m == 0.5 ? '0.5×' : m == 0.25 ? '0.25×' : '${m % 1 == 0 ? m.toInt() : m}×';

/// Color of a multiplier badge/line. Good for the viewer = green when
/// attacking, red when defending (a weakness).
Color relationColor(double m, MatchupMode mode) {
  if (m == 0) return const Color(0xFF7C3AED);
  if (m > 1) {
    return mode == MatchupMode.attack
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
  }
  if (m < 1) return const Color(0xFF2563EB);
  return const Color(0xFF71717A);
}

/// Words for the four multiplier groups, per mode.
String groupTitle(double m, MatchupMode mode) {
  final attack = mode == MatchupMode.attack;
  if (m == 2) return attack ? 'Super effective' : 'Weak to';
  if (m == 0.5) return attack ? 'Not very effective' : 'Resists';
  if (m == 0) return attack ? 'No effect' : 'Immune to';
  return attack ? 'Normal damage' : 'Neutral';
}

/// Short label (legend / badge description) for a multiplier.
String legendLabel(double m, MatchupMode mode) {
  final attack = mode == MatchupMode.attack;
  if (m == 2) return attack ? 'Super effective' : 'Weakness';
  if (m == 0.5) return attack ? 'Not very effective' : 'Resistance';
  if (m == 0) return attack ? 'No effect' : 'Immunity';
  return attack ? 'Normal' : 'Neutral';
}

/// One-sentence explanation of a matchup.
String matchupSentence({
  required String selected,
  required String other,
  required double multiplier,
  required MatchupMode mode,
}) {
  final s = formatPokemonName(selected);
  final o = formatPokemonName(other);
  if (mode == MatchupMode.attack) {
    return multiplier == 0
        ? '$s attacks have no effect on $o Pokémon.'
        : '$s attacks deal ${formatMultiplier(multiplier)} damage to $o Pokémon.';
  }
  return multiplier == 0
      ? '$o attacks have no effect on $s Pokémon.'
      : '$o attacks deal ${formatMultiplier(multiplier)} damage to $s Pokémon.';
}

/// The other 17 types ordered for the orbit ring: 2x first, then 0.5x, 0x,
/// then neutral; ties keep the standard type order.
List<String> orbitOrder(String selected, Map<String, double> chart) {
  const order = [2.0, 0.5, 0.0, 1.0];
  int rank(double m) {
    final i = order.indexOf(m);
    return i < 0 ? order.length : i;
  }

  return [
    for (final t in allPokemonTypes)
      if (t != selected) t,
  ]..sort((a, b) {
      final byRank = rank(chart[a] ?? 1).compareTo(rank(chart[b] ?? 1));
      return byRank != 0
          ? byRank
          : allPokemonTypes.indexOf(a).compareTo(allPokemonTypes.indexOf(b));
    });
}

/// Position of ring slot [index] of [count] around a circle, starting at the
/// top and going clockwise.
Offset ringPosition({
  required int index,
  required int count,
  required double radius,
  required Offset center,
}) {
  final angle = (-90 + index * 360 / count) * math.pi / 180;
  return Offset(
    center.dx + radius * math.cos(angle),
    center.dy + radius * math.sin(angle),
  );
}

const Map<String, String> typeDescriptions = {
  'normal': 'Versatile all-rounders with no weaknesses except Fighting.',
  'fire': 'Fire-type Pokémon are known for their powerful flame-based attacks.',
  'water': 'Adaptable and common, strong against Fire, Ground and Rock.',
  'electric': 'Fast hitters that shock Water and Flying types.',
  'grass': 'Plant-based Pokémon that drain and overgrow Water, Ground and Rock.',
  'ice': 'Frosty attackers that hit hard but resist only Ice.',
  'fighting': 'Martial artists that break Normal, Rock, Steel, Ice and Dark.',
  'poison': 'Toxic Pokémon that wear down Grass and Fairy types.',
  'ground': 'Earth movers immune to Electric attacks.',
  'flying': 'Airborne Pokémon that avoid Ground attacks entirely.',
  'psychic': 'Mind-power users that outthink Fighting and Poison.',
  'bug': 'Small but numerous, strong against Grass, Psychic and Dark.',
  'rock': 'Sturdy fighters that knock down Flying, Fire, Ice and Bug.',
  'ghost': 'Spirits untouched by Normal and Fighting moves.',
  'dragon': 'Rare and powerful, only weak to Ice, Dragon and Fairy.',
  'dark': 'Tricky fighters that Psychic moves cannot touch.',
  'steel': 'Armored defenders with the most resistances of any type.',
  'fairy': 'Enchanting Pokémon immune to Dragon attacks.',
};
