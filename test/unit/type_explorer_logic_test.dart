import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/type_explorer/domain/type_explorer_logic.dart';
import 'package:pokedex_app/shared/models/pokemon_types.dart';

void main() {
  test('formatMultiplier', () {
    expect(formatMultiplier(0), '0×');
    expect(formatMultiplier(0.25), '0.25×');
    expect(formatMultiplier(0.5), '0.5×');
    expect(formatMultiplier(1), '1×');
    expect(formatMultiplier(2), '2×');
    expect(formatMultiplier(4), '4×');
  });

  test('relationColor depends on mode for super effective', () {
    expect(
      relationColor(2, MatchupMode.attack),
      isNot(relationColor(2, MatchupMode.defense)),
    );
    expect(relationColor(0, MatchupMode.attack), const Color(0xFF7C3AED));
    expect(relationColor(0.5, MatchupMode.attack), const Color(0xFF2563EB));
    expect(relationColor(1, MatchupMode.defense), const Color(0xFF71717A));
  });

  test('titles and legend per mode', () {
    expect(groupTitle(2, MatchupMode.attack), 'Super effective');
    expect(groupTitle(2, MatchupMode.defense), 'Weak to');
    expect(groupTitle(0, MatchupMode.defense), 'Immune to');
    expect(legendLabel(0.5, MatchupMode.defense), 'Resistance');
    expect(legendLabel(1, MatchupMode.attack), 'Normal');
  });

  test('matchupSentence keeps attack and defense apart', () {
    expect(
      matchupSentence(
        selected: 'fire',
        other: 'grass',
        multiplier: 2,
        mode: MatchupMode.attack,
      ),
      'Fire attacks deal 2× damage to Grass Pokémon.',
    );
    expect(
      matchupSentence(
        selected: 'fire',
        other: 'water',
        multiplier: 2,
        mode: MatchupMode.defense,
      ),
      'Water attacks deal 2× damage to Fire Pokémon.',
    );
    expect(
      matchupSentence(
        selected: 'ghost',
        other: 'normal',
        multiplier: 0,
        mode: MatchupMode.attack,
      ),
      'Ghost attacks have no effect on Normal Pokémon.',
    );
  });

  test('orbitOrder puts 2x first, 0.5x, 0x, then neutral', () {
    final chart = {
      for (final t in allPokemonTypes) t: 1.0,
      'grass': 2.0,
      'ice': 2.0,
      'water': 0.5,
      'ghost': 0.0,
    };
    final order = orbitOrder('fire', chart);
    expect(order, isNot(contains('fire')));
    expect(order, hasLength(17));
    expect(order.take(4), ['grass', 'ice', 'water', 'ghost']);
    // Neutral types keep the standard type order.
    expect(order.skip(4).first, 'normal');
  });

  test('ringPosition starts at the top and goes clockwise', () {
    const center = Offset(100, 100);
    final top = ringPosition(index: 0, count: 4, radius: 50, center: center);
    expect(top.dx, closeTo(100, 0.001));
    expect(top.dy, closeTo(50, 0.001));
    final right = ringPosition(index: 1, count: 4, radius: 50, center: center);
    expect(right.dx, closeTo(150, 0.001));
    expect(right.dy, closeTo(100, 0.001));
  });

  test('every type has a description', () {
    for (final t in allPokemonTypes) {
      expect(typeDescriptions[t], isNotEmpty, reason: t);
    }
  });
}
