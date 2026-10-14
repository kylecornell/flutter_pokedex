import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/errors/app_exception.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';

import '../helpers/fake_api.dart';

PokemonRepository repoFor(FakePokeApi api) => PokemonRepository(
      PokeApiDataSource(ApiClient(client: MockClient(api.call))),
    );

PokemonRepository repoWith(
  Future<http.Response> Function(http.Request) handler,
) =>
    PokemonRepository(
      PokeApiDataSource(ApiClient(client: MockClient(handler))),
    );

void main() {
  test('getIndex lists every species once and caches', () async {
    final api = FakePokeApi();
    final repo = repoFor(api);

    final first = await repo.getIndex();
    final second = await repo.getIndex();

    expect(first.map((s) => s.id), [1, 2, 3, 4, 5, 6]);
    expect(first.first.name, 'bulbasaur');
    expect(second, same(first));
    expect(api.callsTo('pokemon-species'), 1);
  });

  test('getPokemon parses and caches by id and name', () async {
    final api = FakePokeApi();
    final repo = repoFor(api);

    final first = await repo.getPokemon('Charmander');
    final byId = await repo.getPokemon('4');
    final byName = await repo.getPokemon('charmander');

    expect(first.id, 4);
    expect(byId, same(first));
    expect(byName, same(first));
    expect(api.callsTo('pokemon/'), 1);
  });

  test('getSpecies caches by name and id', () async {
    final api = FakePokeApi();
    final repo = repoFor(api);

    final a = await repo.getSpecies('charizard');
    final b = await repo.getSpecies('charizard');
    expect(a.genus, 'Seed Pokémon');
    expect(b, same(a));
    expect(api.callsTo('pokemon-species/charizard'), 1);
  });

  group('getEvolutionChain', () {
    test('follows species -> chain, parses stages and caches', () async {
      final api = FakePokeApi();
      final repo = repoFor(api);

      final chain = await repo.getEvolutionChain('Charmander');
      expect(chain!.nodeStages, hasLength(3));
      expect(chain.nodeStages[1].single.requirement, 'Lv. 16');
      await repo.getEvolutionChain('charmander');
      expect(api.callsTo('evolution-chain'), 1);
      expect(api.callsTo('pokemon-species/charmander'), 1);
    });

    test('species without chain -> null', () async {
      final repo = repoWith(
        (_) async => http.Response('{"name": "ditto"}', 200),
      );
      expect(await repo.getEvolutionChain('ditto'), isNull);
    });

    test('unknown species -> NotFoundException', () {
      final repo = repoFor(FakePokeApi());
      expect(repo.getEvolutionChain('missingno'), throwsA(isA<NotFoundException>()));
    });
  });

  test('getAbilityDescription prefers short effect, caches', () async {
    final api = FakePokeApi();
    final repo = repoFor(api);
    expect(
      await repo.getAbilityDescription('overgrow'),
      'Powers up Grass moves in a pinch.',
    );
    await repo.getAbilityDescription('overgrow');
    expect(api.callsTo('ability'), 1);
  });

  test('getAbilityDescription falls back to flavor text, then default',
      () async {
    final flavor = repoWith((_) async => http.Response(
          '{"flavor_text_entries":[{"flavor_text":"Old\\ntext","language":{"name":"en"}}]}',
          200,
        ));
    expect(await flavor.getAbilityDescription('x'), 'Old text');

    final none = repoWith((_) async => http.Response('{}', 200));
    expect(await none.getAbilityDescription('y'), 'No description available.');
  });

  test('getMove parses and caches', () async {
    final api = FakePokeApi();
    final repo = repoFor(api);
    final move = await repo.getMove('ember');
    expect(move.type, 'fire');
    expect(move.power, 40);
    await repo.getMove('ember');
    expect(api.callsTo('move'), 1);
  });

  group('errors', () {
    test('404 -> NotFoundException', () {
      final repo = repoWith((_) async => http.Response('', 404));
      expect(repo.getPokemon('nope'), throwsA(isA<NotFoundException>()));
    });

    test('500 -> ServerException', () {
      final repo = repoWith((_) async => http.Response('', 500));
      expect(
        repo.getPokemon('1'),
        throwsA(
          isA<ServerException>().having((e) => e.statusCode, 'status', 500),
        ),
      );
    });

    test('connection failure -> NetworkException', () {
      final repo =
          repoWith((_) async => throw http.ClientException('offline'));
      expect(repo.getPokemon('1'), throwsA(isA<NetworkException>()));
    });

    test('invalid JSON -> ParsingException', () {
      final repo = repoWith((_) async => http.Response('<html>', 200));
      expect(repo.getPokemon('1'), throwsA(isA<ParsingException>()));
    });

    test('wrong shape -> ParsingException', () {
      final repo = repoWith((_) async => http.Response('{"name":"x"}', 200));
      expect(repo.getPokemon('1'), throwsA(isA<ParsingException>()));
    });
  });
}
