import 'dart:convert';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/model_3d_repository.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';
import 'package:pokedex_app/shared/repositories/type_repository.dart';

import 'prefs.dart';

/// Tiny fake PokéAPI: six Pokémon (the Kanto starters and their evolutions)
/// with real-looking JSON shapes. Everything else answers 404.
const fakeDex = <int, String>{
  1: 'bulbasaur',
  2: 'ivysaur',
  3: 'venusaur',
  4: 'charmander',
  5: 'charmeleon',
  6: 'charizard',
  // Alternate form: never part of the Pokédex list or the type index.
  10034: 'charizard-mega-x',
};

/// Species name of a Pokémon id (forms share their base species).
String fakeSpeciesName(int id) => id >= 10000 ? 'charizard' : fakeDex[id]!;

const fakeTypes = <int, List<String>>{
  1: ['grass', 'poison'],
  2: ['grass', 'poison'],
  3: ['grass', 'poison'],
  4: ['fire'],
  5: ['fire'],
  6: ['fire', 'flying'],
  10034: ['fire', 'dragon'],
};

Map<String, dynamic> _named(String name, String path, int id) => {
      'name': name,
      'url': 'https://pokeapi.co/api/v2/$path/$id/',
    };

Map<String, dynamic> speciesListJson() => {
      'count': fakeDex.keys.where((id) => id < 10000).length,
      'next': null,
      'results': [
        for (final e in fakeDex.entries)
          if (e.key < 10000) _named(e.value, 'pokemon-species', e.key),
      ],
    };

Map<String, dynamic> pokemonJson(int id) {
  final name = fakeDex[id]!;
  return {
    'id': id,
    'name': name,
    'height': 10 + id,
    'weight': 100 + id,
    'base_experience': 60 + id,
    'species': _named(fakeSpeciesName(id), 'pokemon-species', id % 10000),
    'types': [
      for (final (i, t) in fakeTypes[id]!.indexed)
        {
          'slot': i + 1,
          'type': {'name': t},
        },
    ],
    'stats': [
      {'base_stat': 40 + id, 'stat': {'name': 'hp'}},
      {'base_stat': 50 + id, 'stat': {'name': 'attack'}},
      {'base_stat': 60 + id, 'stat': {'name': 'special-attack'}},
    ],
    'abilities': [
      {
        'slot': 1,
        'is_hidden': false,
        'ability': {'name': 'overgrow'},
      },
      {
        'slot': 3,
        'is_hidden': true,
        'ability': {'name': 'chlorophyll'},
      },
    ],
    'moves': [
      {
        'move': {'name': 'tackle'},
        'version_group_details': [
          {
            'level_learned_at': 1,
            'move_learn_method': {'name': 'level-up'},
            'version_group': {
              'name': 'scarlet-violet',
              'url': 'https://pokeapi.co/api/v2/version-group/25/',
            },
          },
          // Older game: must be ignored.
          {
            'level_learned_at': 5,
            'move_learn_method': {'name': 'level-up'},
            'version_group': {
              'name': 'red-blue',
              'url': 'https://pokeapi.co/api/v2/version-group/1/',
            },
          },
        ],
      },
      {
        'move': {'name': 'ember'},
        'version_group_details': [
          {
            'level_learned_at': 0,
            'move_learn_method': {'name': 'machine'},
            'version_group': {
              'name': 'scarlet-violet',
              'url': 'https://pokeapi.co/api/v2/version-group/25/',
            },
          },
        ],
      },
    ],
    'sprites': {
      'other': {
        'official-artwork': {'front_default': 'https://example.com/$id.png'},
      },
    },
  };
}

Map<String, dynamic> speciesJson(int id) {
  final name = fakeSpeciesName(id);
  return {
    'name': name,
    'capture_rate': 45,
    'is_legendary': false,
    'is_mythical': false,
    'habitat': {'name': 'grassland'},
    'generation': {'name': 'generation-i'},
    'genera': [
      {'genus': 'Seed Pokémon', 'language': {'name': 'en'}},
    ],
    'flavor_text_entries': [
      {'flavor_text': 'Old text.', 'language': {'name': 'en'}},
      {
        'flavor_text': 'A strange seed\nwas planted\fon its back.',
        'language': {'name': 'en'},
      },
      {'flavor_text': 'Texto.', 'language': {'name': 'es'}},
    ],
    'varieties': [
      {
        'is_default': true,
        'pokemon': _named(name, 'pokemon', id),
      },
      if (id == 6)
        {
          'is_default': false,
          'pokemon': _named('charizard-mega-x', 'pokemon', 10034),
        },
    ],
    'evolution_chain': {'url': 'https://pokeapi.co/api/v2/evolution-chain/2/'},
  };
}

Map<String, dynamic> evolutionChainJson() => {
      'id': 2,
      'chain': {
        'species': _named('charmander', 'pokemon-species', 4),
        'evolution_details': [],
        'evolves_to': [
          {
            'species': _named('charmeleon', 'pokemon-species', 5),
            'evolution_details': [
              {
                'trigger': {'name': 'level-up'},
                'min_level': 16,
              },
            ],
            'evolves_to': [
              {
                'species': _named('charizard', 'pokemon-species', 6),
                'evolution_details': [
                  {
                    'trigger': {'name': 'level-up'},
                    'min_level': 36,
                  },
                ],
                'evolves_to': [],
              },
            ],
          },
        ],
      },
    };

/// Minimal damage chart for the types the tests touch.
const _relations = <String, Map<String, List<String>>>{
  'fire': {
    'double_damage_to': ['grass', 'bug', 'ice', 'steel'],
    'half_damage_to': ['fire', 'water', 'rock', 'dragon'],
    'no_damage_to': [],
    'double_damage_from': ['water', 'ground', 'rock'],
    'half_damage_from': ['fire', 'grass', 'ice', 'bug', 'steel', 'fairy'],
    'no_damage_from': [],
  },
  'ghost': {
    'double_damage_to': ['ghost', 'psychic'],
    'half_damage_to': ['dark'],
    'no_damage_to': ['normal'],
    'double_damage_from': ['ghost', 'dark'],
    'half_damage_from': ['poison', 'bug'],
    'no_damage_from': ['normal', 'fighting'],
  },
  'grass': {
    'double_damage_to': ['water', 'ground', 'rock'],
    'half_damage_to': ['fire', 'grass', 'poison', 'flying', 'bug', 'dragon', 'steel'],
    'no_damage_to': [],
    'double_damage_from': ['fire', 'ice', 'poison', 'flying', 'bug'],
    'half_damage_from': ['water', 'electric', 'grass', 'ground'],
    'no_damage_from': [],
  },
};

Map<String, dynamic> typeJson(String name) {
  final relations = _relations[name] ??
      {
        for (final k in [
          'double_damage_to',
          'half_damage_to',
          'no_damage_to',
          'double_damage_from',
          'half_damage_from',
          'no_damage_from',
        ])
          k: <String>[],
      };
  return {
    'name': name,
    'damage_relations': {
      for (final e in relations.entries)
        e.key: [for (final t in e.value) {'name': t}],
    },
    'pokemon': [
      for (final e in fakeTypes.entries)
        if (e.value.contains(name))
          {
            'slot': e.value.indexOf(name) + 1,
            'pokemon': _named(fakeDex[e.key]!, 'pokemon', e.key),
          },
    ],
  };
}

/// Request handler for [MockClient]. Counts requests per path in [calls].
class FakePokeApi {
  FakePokeApi({this.failEverything = false});

  /// When true every request answers HTTP 500.
  bool failEverything;
  final Map<String, int> calls = {};

  int callsTo(String pathPrefix) => calls.entries
      .where((e) => e.key.startsWith(pathPrefix))
      .fold(0, (sum, e) => sum + e.value);

  Future<http.Response> call(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/v2/', '');
    calls[path] = (calls[path] ?? 0) + 1;
    if (failEverything) return http.Response('', 500);

    final parts = path.split('/');
    int? idOf(String s) => int.tryParse(s) ?? fakeDex.entries
        .where((e) => e.value == s)
        .map((e) => e.key)
        .firstOrNull;

    Object? body;
    switch (parts.first) {
      case 'pokemon-species':
        if (parts.length == 1) {
          body = speciesListJson();
        } else {
          final id = idOf(parts[1]);
          if (id != null && fakeDex.containsKey(id)) body = speciesJson(id);
        }
      case 'pokemon':
        final id = parts.length > 1 ? idOf(parts[1]) : null;
        if (id != null && fakeDex.containsKey(id)) body = pokemonJson(id);
      case 'evolution-chain':
        body = evolutionChainJson();
      case 'type':
        if (parts.length > 1) body = typeJson(parts[1]);
      case 'ability':
        body = {
          'effect_entries': [
            {
              'short_effect': 'Powers up Grass moves in a pinch.',
              'language': {'name': 'en'},
            },
          ],
        };
      case 'move':
        body = {
          'type': {'name': parts.length > 1 && parts[1] == 'ember' ? 'fire' : 'normal'},
          'power': 40,
          'accuracy': 100,
          'pp': 25,
          'damage_class': {'name': 'physical'},
        };
    }
    if (body == null) return http.Response('', 404);
    // The real API sends UTF-8 ("Pokémon"); http.Response(String) would
    // encode as Latin-1.
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

/// ProviderScope overrides that serve everything from [api] and an
/// in-memory SharedPreferences.
Future<List<Override>> testOverrides(
  FakePokeApi api, {
  Map<String, Object> prefs = const {},
}) async {
  final client = MockClient(api.call);
  final dataSource = PokeApiDataSource(ApiClient(client: client));
  return [
    await prefsOverride(prefs),
    pokemonRepositoryProvider.overrideWithValue(PokemonRepository(dataSource)),
    typeRepositoryProvider.overrideWithValue(TypeRepository(dataSource)),
    // No 3D model lookups over the real network in tests.
    model3dRepositoryProvider.overrideWithValue(
      Model3dRepository(
        client: MockClient((_) async => http.Response('', 404)),
      ),
    ),
  ];
}
