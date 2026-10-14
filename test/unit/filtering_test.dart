import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/domain/pokemon_filtering.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';

const _all = [
  PokemonSummary(id: 1, name: 'bulbasaur'),
  PokemonSummary(id: 4, name: 'charmander'),
  PokemonSummary(id: 6, name: 'charizard'),
  PokemonSummary(id: 25, name: 'pikachu'),
  PokemonSummary(id: 152, name: 'chikorita'),
  PokemonSummary(id: 250, name: 'ho-oh'),
];

const _types = {
  1: ['grass', 'poison'],
  4: ['fire'],
  6: ['fire', 'flying'],
  25: ['electric'],
  152: ['grass'],
  250: ['fire', 'flying'],
};

List<int> ids(List<PokemonSummary> l) => l.map((p) => p.id).toList();

void main() {
  group('matchesQuery', () {
    test('empty query matches everything', () {
      expect(matchesQuery(_all.first, '  '), isTrue);
    });

    test('name substring, case-insensitive', () {
      expect(ids(filterPokemon(_all, query: 'CHAR')), [4, 6]);
    });

    test('numbers match the start of the Pokédex number', () {
      expect(ids(filterPokemon(_all, query: '25')), [25, 250]);
      expect(ids(filterPokemon(_all, query: '#4')), [4]);
      expect(ids(filterPokemon(_all, query: '0004')), [4]);
    });

    test('hyphenated names match with a space', () {
      expect(ids(filterPokemon(_all, query: 'ho oh')), [250]);
      expect(ids(filterPokemon(_all, query: 'ho-oh')), [250]);
    });
  });

  group('filterPokemon', () {
    test('single type', () {
      expect(
        ids(filterPokemon(_all, types: ['fire'], typeIndex: _types)),
        [4, 6, 250],
      );
    });

    test('dual type requires both', () {
      expect(
        ids(filterPokemon(_all, types: ['fire', 'flying'], typeIndex: _types)),
        [6, 250],
      );
      expect(
        ids(filterPokemon(_all, types: ['grass', 'fire'], typeIndex: _types)),
        isEmpty,
      );
    });

    test('type filter matches nothing until the index is loaded', () {
      expect(ids(filterPokemon(_all, types: ['fire'])), isEmpty);
    });

    test('generation range', () {
      expect(ids(filterPokemon(_all, generationIndex: 0)), [1, 4, 6, 25]);
      expect(ids(filterPokemon(_all, generationIndex: 1)), [152, 250]);
    });

    test('sort by name', () {
      expect(
        filterPokemon(_all, sort: PokemonSort.name).map((p) => p.name).first,
        'bulbasaur',
      );
      expect(
        filterPokemon(_all, sort: PokemonSort.name).map((p) => p.name).toList(),
        [
          'bulbasaur',
          'charizard',
          'charmander',
          'chikorita',
          'ho-oh',
          'pikachu',
        ],
      );
    });

    test('filters combine', () {
      expect(
        ids(
          filterPokemon(
            _all,
            query: 'ch',
            types: ['fire'],
            typeIndex: _types,
            generationIndex: 0,
          ),
        ),
        [4, 6],
      );
    });
  });

  group('toggleTypeSelection', () {
    test('adds, removes and keeps at most two', () {
      var s = <String>[];
      s = toggleTypeSelection(s, 'fire');
      s = toggleTypeSelection(s, 'flying');
      expect(s, ['fire', 'flying']);
      s = toggleTypeSelection(s, 'water');
      expect(s, ['flying', 'water']);
      s = toggleTypeSelection(s, 'water');
      expect(s, ['flying']);
    });

    test('max 1 behaves like single choice', () {
      expect(toggleTypeSelection(['fire'], 'water', max: 1), ['water']);
    });
  });
}
