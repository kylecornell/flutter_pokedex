import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/errors/app_exception.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();

PokemonRepository repoWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final client = ApiClient(client: MockClient(handler));
  return PokemonRepository(PokeApiDataSource(client));
}

void main() {
  test('getPokemon parses and caches by id and name', () async {
    var calls = 0;
    final repo = repoWith((req) async {
      calls++;
      expect(req.url.path, '/api/v2/pokemon/pikachu');
      return http.Response(fixtureText('pokemon_pikachu.json'), 200);
    });

    final first = await repo.getPokemon('Pikachu');
    final byId = await repo.getPokemon('25');
    final byName = await repo.getPokemon('pikachu');

    expect(first.id, 25);
    expect(byId, same(first));
    expect(byName, same(first));
    expect(calls, 1);
  });

  test('getPage sends limit and offset', () async {
    final repo = repoWith((req) async {
      expect(req.url.queryParameters, {'limit': '2', 'offset': '4'});
      return http.Response(fixtureText('pokemon_list.json'), 200);
    });

    final page = await repo.getPage(limit: 2, offset: 4);
    expect(page.items, hasLength(2));
  });

  test('404 -> NotFoundException', () {
    final repo = repoWith((_) async => http.Response('', 404));
    expect(repo.getPokemon('nope'), throwsA(isA<NotFoundException>()));
  });

  test('500 -> ServerException', () {
    final repo = repoWith((_) async => http.Response('', 500));
    expect(
      repo.getPokemon('1'),
      throwsA(isA<ServerException>().having((e) => e.statusCode, 'status', 500)),
    );
  });

  test('connection failure -> NetworkException', () {
    final repo = repoWith((_) async => throw http.ClientException('offline'));
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
}
