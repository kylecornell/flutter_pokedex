import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/models/evolution_chain.dart';
import 'package:pokedex_app/shared/models/pokemon.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  evolutionTests();

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
  });

  group('PokemonPage.fromJson', () {
    test('extracts ids from urls and paging info', () {
      final page = PokemonPage.fromJson(fixture('pokemon_list.json'));
      expect(page.items.map((i) => i.id), [1, 2]);
      expect(page.items.first.name, 'bulbasaur');
      expect(page.totalCount, 1350);
      expect(page.hasNext, isTrue);
    });
  });
}

void evolutionTests() {
  group('EvolutionChain', () {
    test('linear chain -> one species per stage', () {
      final chain =
          EvolutionChain.fromJson(fixture('evolution_chain_charmander.json'));
      final stages = chain.stages;
      expect(stages.map((s) => s.map((p) => p.name).toList()), [
        ['charmander'],
        ['charmeleon'],
        ['charizard'],
      ]);
      expect(stages.last.single.id, 6);
    });

    test('branching chain groups siblings in one stage', () {
      final chain = EvolutionChain.fromJson({
        'chain': {
          'species': {'name': 'eevee', 'url': 'https://x/pokemon-species/133/'},
          'evolves_to': [
            {
              'species': {'name': 'vaporeon', 'url': 'https://x/pokemon-species/134/'},
              'evolves_to': [],
            },
            {
              'species': {'name': 'jolteon', 'url': 'https://x/pokemon-species/135/'},
              'evolves_to': [],
            },
          ],
        },
      });
      expect(chain.stages.map((s) => s.length), [1, 2]);
    });

    test('single species -> one stage', () {
      final chain = EvolutionChain.fromJson({
        'chain': {
          'species': {'name': 'tauros', 'url': 'https://x/pokemon-species/128/'},
          'evolves_to': [],
        },
      });
      expect(chain.stages, hasLength(1));
    });
  });

  test('Pokemon.speciesName from species field, else name', () {
    expect(
      Pokemon.fromJson({
        'id': 10034,
        'name': 'charizard-mega-x',
        'species': {'name': 'charizard'},
      }).speciesName,
      'charizard',
    );
    expect(Pokemon.fromJson({'id': 1, 'name': 'bulbasaur'}).speciesName,
        'bulbasaur');
  });
}
