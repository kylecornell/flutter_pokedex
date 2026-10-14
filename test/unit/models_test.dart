import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/models/evolution_chain.dart';
import 'package:pokedex_app/shared/models/generation.dart';
import 'package:pokedex_app/shared/models/move_info.dart';
import 'package:pokedex_app/shared/models/pokemon.dart';
import 'package:pokedex_app/shared/models/pokemon_species.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';
import 'package:pokedex_app/shared/models/pokemon_type.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  group('Pokemon.fromJson', () {
    test('parses a full response', () {
      final p = Pokemon.fromJson(fixture('pokemon_pikachu.json'));
      expect(p.id, 25);
      expect(p.name, 'pikachu');
      expect(p.types, ['electric']);
      expect(p.stats.map((s) => s.name), ['hp', 'attack']);
      expect(p.stats.first.value, 35);
      expect(p.heightMeters, 0.4);
      expect(p.weightKg, 6.0);
      expect(p.artworkUrl, 'https://example.com/art.png');
    });

    test('falls back when optional fields are missing', () {
      final p = Pokemon.fromJson({'id': 132});
      expect(p.name, 'unknown');
      expect(p.types, isEmpty);
      expect(p.stats, isEmpty);
      expect(p.abilities, isEmpty);
      expect(p.moves, isEmpty);
      expect(p.baseExperience, isNull);
      expect(p.artworkUrl, Pokemon.artworkUrlForId(132));
    });

    test('uses front sprite when artwork missing', () {
      final p = Pokemon.fromJson({
        'id': 1,
        'sprites': {'front_default': 'https://example.com/front.png'},
      });
      expect(p.artworkUrl, 'https://example.com/front.png');
    });

    test('throws when id is missing', () {
      expect(() => Pokemon.fromJson({'name': 'x'}), throwsA(isA<TypeError>()));
    });

    test('orders types and abilities by slot', () {
      final p = Pokemon.fromJson({
        'id': 6,
        'types': [
          {'slot': 2, 'type': {'name': 'flying'}},
          {'slot': 1, 'type': {'name': 'fire'}},
        ],
        'abilities': [
          {'slot': 3, 'is_hidden': true, 'ability': {'name': 'solar-power'}},
          {'slot': 1, 'is_hidden': false, 'ability': {'name': 'blaze'}},
        ],
      });
      expect(p.types, ['fire', 'flying']);
      expect(p.abilities.map((a) => a.name), ['blaze', 'solar-power']);
      expect(p.abilities.last.isHidden, isTrue);
    });

    test('keeps only the newest game learnset, level-up first', () {
      final p = Pokemon.fromJson(pokemonJson(4));
      expect(p.versionGroupName, 'scarlet-violet');
      expect(p.moves.map((m) => '${m.name}:${m.method}'), [
        'tackle:level-up',
        'ember:machine',
      ]);
      expect(p.moves.first.level, 1);
      expect(p.baseExperience, 64);
    });

    test('speciesName comes from species, else name', () {
      expect(
        Pokemon.fromJson({
          'id': 10034,
          'name': 'charizard-mega-x',
          'species': {'name': 'charizard'},
        }).speciesName,
        'charizard',
      );
      expect(
        Pokemon.fromJson({'id': 1, 'name': 'bulbasaur'}).speciesName,
        'bulbasaur',
      );
    });
  });

  group('PokemonSpecies', () {
    test('cleans flavor text, picks english genus, generation, forms', () {
      final s = PokemonSpecies.fromJson(speciesJson(6));
      expect(s.flavorText, 'A strange seed was planted on its back.');
      expect(s.genus, 'Seed Pokémon');
      expect(s.generation.region, 'Kanto');
      expect(s.habitat, 'grassland');
      expect(s.captureRate, 45);
      expect(s.rarity, PokemonRarity.standard);
      expect(s.forms.map((f) => f.label), ['Base', 'Mega X']);
      expect(s.forms.last.kind, FormKind.mega);
      expect(s.forms.last.id, 10034);
      expect(s.evolutionChainUrl, endsWith('/evolution-chain/2/'));
    });

    test('rarity and fallbacks', () {
      final s = PokemonSpecies.fromJson({
        'name': 'mewtwo',
        'is_legendary': true,
        'generation': {'name': 'generation-ix'},
      });
      expect(s.rarity, PokemonRarity.legendary);
      expect(s.flavorText, 'No Pokédex entry available.');
      expect(s.genus, 'Pokémon');
      expect(s.generation.roman, 'IX');
      expect(s.forms, isEmpty);
      expect(
        PokemonSpecies.fromJson({'is_mythical': true}).rarity,
        PokemonRarity.mythical,
      );
    });

    test('form kinds', () {
      PokemonForm form(String api, {bool def = false}) =>
          PokemonForm.fromVariety(
            apiName: api,
            speciesName: api.split('-').first,
            id: 1,
            isDefault: def,
          );
      expect(form('pikachu', def: true).kind, FormKind.base);
      expect(form('charizard-gmax').label, 'Gigantamax');
      expect(form('raichu-alola').label, 'Alolan');
      expect(form('raichu-alola').kind, FormKind.regional);
      expect(form('slowpoke-galar').label, 'Galarian');
      expect(form('pikachu-cosplay').label, 'Cosplay');
      expect(form('pikachu-cosplay').kind, FormKind.other);
    });

    test('generationIndexFromApiName', () {
      expect(generationIndexFromApiName('generation-v'), 4);
      expect(generationIndexFromApiName('nonsense'), 0);
      expect(generationIndexFromApiName(null), 0);
      expect(pokemonGenerations.last.contains(1025), isTrue);
    });
  });

  group('PokemonPage / summary', () {
    test('extracts ids from urls and paging info', () {
      final page = PokemonPage.fromJson(fixture('pokemon_list.json'));
      expect(page.items.map((i) => i.id), [1, 2]);
      expect(page.items.first.name, 'bulbasaur');
      expect(page.totalCount, 1350);
      expect(page.hasNext, isTrue);
    });

    test('summary builds artwork and sprite urls from the id', () {
      const s = PokemonSummary(id: 25, name: 'pikachu');
      expect(s.artworkUrl, contains('official-artwork/25.png'));
      expect(s.spriteUrl, endsWith('/pokemon/25.png'));
      expect(Pokemon.animatedSpriteUrlForId(25), endsWith('showdown/25.gif'));
    });
  });

  group('EvolutionChain', () {
    test('linear chain with requirements', () {
      final chain = EvolutionChain.fromJson(evolutionChainJson());
      final stages = chain.nodeStages;
      expect(stages.map((s) => s.map((n) => n.species.name).toList()), [
        ['charmander'],
        ['charmeleon'],
        ['charizard'],
      ]);
      expect(stages.map((s) => s.first.requirement), ['', 'Lv. 16', 'Lv. 36']);
      expect(chain.stages.last.single.id, 6);
    });

    test('branching chain groups siblings in one stage', () {
      final chain = EvolutionChain.fromJson({
        'chain': {
          'species': {'name': 'eevee', 'url': 'https://x/pokemon-species/133/'},
          'evolves_to': [
            {
              'species': {'name': 'vaporeon', 'url': 'https://x/pokemon-species/134/'},
              'evolves_to': [],
              'evolution_details': [
                {'trigger': {'name': 'use-item'}, 'item': {'name': 'water-stone'}},
              ],
            },
            {
              'species': {'name': 'jolteon', 'url': 'https://x/pokemon-species/135/'},
              'evolves_to': [],
              'evolution_details': [
                {'trigger': {'name': 'use-item'}, 'item': {'name': 'thunder-stone'}},
              ],
            },
          ],
        },
      });
      expect(chain.stages.map((s) => s.length), [1, 2]);
      expect(chain.nodeStages[1].map((n) => n.requirement), [
        'Water Stone',
        'Thunder Stone',
      ]);
    });

    test('requirement texts', () {
      expect(
        evolutionRequirement({
          'trigger': {'name': 'level-up'},
          'min_happiness': 220,
          'time_of_day': 'day',
        }),
        'Friendship (day)',
      );
      expect(
        evolutionRequirement({
          'trigger': {'name': 'trade'},
          'held_item': {'name': 'metal-coat'},
        }),
        'Trade + Metal Coat',
      );
      expect(
        evolutionRequirement({
          'trigger': {'name': 'level-up'},
          'known_move': {'name': 'ancient-power'},
        }),
        'Knows Ancient Power',
      );
      expect(evolutionRequirement({}), '');
      expect(
        evolutionRequirement({'trigger': {'name': 'shed'}}),
        'Shed',
      );
    });
  });

  group('PokemonType', () {
    test('parses relations and members with slots', () {
      final fire = PokemonType.fromJson(typeJson('fire'));
      expect(fire.doubleDamageTo, contains('grass'));
      expect(fire.members.map((m) => m.pokemon.id), containsAll([4, 5, 6]));
      expect(
        fire.members.firstWhere((m) => m.pokemon.id == 6).slot,
        1,
      );
      final flying = PokemonType.fromJson(typeJson('flying'));
      expect(flying.members.single.slot, 2);
    });

    test('missing sections fall back to empty', () {
      final t = PokemonType.fromJson({'name': 'x'});
      expect(t.doubleDamageTo, isEmpty);
      expect(t.members, isEmpty);
      expect(t.attackMultiplierAgainst('fire'), 1);
    });

    test('single multipliers', () {
      final fire = PokemonType.fromJson(typeJson('fire'));
      final ghost = PokemonType.fromJson(typeJson('ghost'));
      expect(fire.attackMultiplierAgainst('grass'), 2);
      expect(fire.attackMultiplierAgainst('water'), 0.5);
      expect(ghost.attackMultiplierAgainst('normal'), 0);
      expect(fire.defenseMultiplierFrom('water'), 2);
      expect(ghost.defenseMultiplierFrom('fighting'), 0);
    });
  });

  test('MoveInfo parses and falls back', () {
    final m = MoveInfo.fromJson({
      'type': {'name': 'fire'},
      'power': 40,
      'accuracy': null,
      'pp': 25,
      'damage_class': {'name': 'special'},
    });
    expect(m.type, 'fire');
    expect(m.power, 40);
    expect(m.accuracy, isNull);
    expect(m.damageClass, 'special');
    expect(MoveInfo.fromJson({}).type, 'normal');
  });
}
