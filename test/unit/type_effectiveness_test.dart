import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/type_explorer/domain/services/type_effectiveness_service.dart';
import 'package:pokedex_app/shared/models/pokemon_type.dart';

PokemonType fixtureType(String name) => PokemonType.fromJson(
      jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, dynamic>,
    );

// Hand-built defenders (only the relations these tests need).
const grass = PokemonType(
  name: 'grass',
  doubleDamageFrom: {'fire', 'ice', 'poison', 'flying', 'bug'},
  halfDamageFrom: {'water', 'electric', 'grass', 'ground'},
);
const steel = PokemonType(
  name: 'steel',
  doubleDamageFrom: {'fire', 'fighting', 'ground'},
  halfDamageFrom: {'normal', 'grass', 'ice', 'flying', 'psychic', 'bug', 'rock',
      'dragon', 'steel', 'fairy'},
  noDamageFrom: {'poison'},
);
const water = PokemonType(
  name: 'water',
  doubleDamageFrom: {'electric', 'grass'},
  halfDamageFrom: {'fire', 'water', 'ice', 'steel'},
);
const ground = PokemonType(
  name: 'ground',
  doubleDamageFrom: {'water', 'grass', 'ice'},
  halfDamageFrom: {'poison', 'rock'},
  noDamageFrom: {'electric'},
);

void main() {
  final fire = fixtureType('type_fire.json');
  final ghost = fixtureType('type_ghost.json');

  group('PokemonType.fromJson', () {
    test('parses relations and members', () {
      expect(fire.name, 'fire');
      expect(fire.doubleDamageTo, {'bug', 'steel', 'grass', 'ice'});
      expect(fire.pokemon.map((p) => p.id), [6, 4, 10034]);
    });

    test('missing sections fall back to empty', () {
      final t = PokemonType.fromJson({'name': 'x'});
      expect(t.doubleDamageTo, isEmpty);
      expect(t.pokemon, isEmpty);
      expect(t.attackMultiplierAgainst('fire'), 1);
    });
  });

  group('single multipliers', () {
    test('attack', () {
      expect(fire.attackMultiplierAgainst('grass'), 2);
      expect(fire.attackMultiplierAgainst('water'), 0.5);
      expect(fire.attackMultiplierAgainst('normal'), 1);
      expect(ghost.attackMultiplierAgainst('normal'), 0);
    });

    test('defense', () {
      expect(fire.defenseMultiplierFrom('water'), 2);
      expect(fire.defenseMultiplierFrom('grass'), 0.5);
      expect(ghost.defenseMultiplierFrom('fighting'), 0);
    });
  });

  group('TypeEffectivenessService', () {
    test('attackMultiplier multiplies dual defender types', () {
      expect(
        TypeEffectivenessService.attackMultiplier(fire, ['grass', 'steel']),
        4,
      );
      expect(
        TypeEffectivenessService.attackMultiplier(fire, ['water', 'rock']),
        0.25,
      );
      expect(
        TypeEffectivenessService.attackMultiplier(ghost, ['normal', 'ghost']),
        0,
      );
    });

    test('defenseChart for a single type', () {
      final chart = TypeEffectivenessService.defenseChart([grass]);
      expect(chart['fire'], 2);
      expect(chart['water'], 0.5);
      expect(chart['normal'], 1);
      expect(chart, hasLength(18));
    });

    test('defenseChart for dual type: ground immunity beats weakness', () {
      final chart = TypeEffectivenessService.defenseChart([water, ground]);
      expect(chart['electric'], 0); // 2 * 0
      expect(chart['grass'], 4); // 2 * 2
      expect(chart['fire'], 0.5); // 0.5 * 1
      expect(chart['poison'], 0.5);
    });

    test('defenseChart grass/steel has a 4x fire weakness and poison immunity',
        () {
      final chart = TypeEffectivenessService.defenseChart([grass, steel]);
      expect(chart['fire'], 4);
      expect(chart['poison'], 0);
    });

    test('groupByMultiplier orders highest first', () {
      final grouped = TypeEffectivenessService.groupByMultiplier(
        {'a': 0.5, 'b': 2, 'c': 0, 'd': 2, 'e': 1},
      );
      expect(grouped.keys.toList(), [2, 1, 0.5, 0]);
      expect(grouped[2], ['b', 'd']);
    });
  });
}
