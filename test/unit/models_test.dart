import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/models/pokemon.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';

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
