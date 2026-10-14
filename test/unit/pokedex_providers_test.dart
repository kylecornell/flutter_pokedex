import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/errors/app_exception.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/pokedex/presentation/providers/pokedex_list_provider.dart';
import 'package:pokedex_app/features/pokedex/presentation/providers/pokedex_search_provider.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';

String pageJson(int offset, int count, {required bool hasNext}) {
  final results = [
    for (var i = 0; i < count; i++)
      '{"name":"mon${offset + i + 1}","url":"https://pokeapi.co/api/v2/pokemon/${offset + i + 1}/"}',
  ].join(',');
  return '{"count":30,"next":${hasNext ? '"x"' : 'null'},"results":[$results]}';
}

ProviderContainer containerWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final repo = PokemonRepository(
    PokeApiDataSource(ApiClient(client: MockClient(handler))),
  );
  final container = ProviderContainer(
    overrides: [pokemonRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PokedexListNotifier', () {
    test('loads first page, then appends next, then stops', () async {
      final container = containerWith((req) async {
        final offset = int.parse(req.url.queryParameters['offset']!);
        return http.Response(
          offset == 0
              ? pageJson(0, 20, hasNext: true)
              : pageJson(20, 10, hasNext: false),
          200,
        );
      });
      container.listen(pokedexListProvider, (_, _) {});

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      var state = container.read(pokedexListProvider);
      expect(state.items, hasLength(20));
      expect(state.hasMore, isTrue);

      await container.read(pokedexListProvider.notifier).loadNextPage();
      state = container.read(pokedexListProvider);
      expect(state.items, hasLength(30));
      expect(state.items.last.id, 30);
      expect(state.hasMore, isFalse);
    });

    test('keeps items on error and recovers on retry', () async {
      var fail = false;
      final container = containerWith((req) async {
        if (fail) return http.Response('', 500);
        return http.Response(pageJson(0, 20, hasNext: true), 200);
      });
      container.listen(pokedexListProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      fail = true;
      final notifier = container.read(pokedexListProvider.notifier);
      await notifier.loadNextPage();
      var state = container.read(pokedexListProvider);
      expect(state.items, hasLength(20));
      expect(state.error, isA<ServerException>());

      fail = false;
      await notifier.loadNextPage();
      state = container.read(pokedexListProvider);
      expect(state.error, isNull);
      expect(state.items, hasLength(40));
    });
  });

  group('filterPokemon', () {
    const all = [
      PokemonSummary(id: 25, name: 'pikachu'),
      PokemonSummary(id: 26, name: 'raichu'),
      PokemonSummary(id: 250, name: 'ho-oh'),
    ];

    test('empty query returns all', () {
      expect(filterPokemon(all, '  '), all);
    });

    test('matches name substring, case-insensitive', () {
      expect(filterPokemon(all, 'CHU').map((p) => p.id), [25, 26]);
    });

    test('matches exact number, with or without #', () {
      expect(filterPokemon(all, '25').map((p) => p.id), [25]);
      expect(filterPokemon(all, '#250').map((p) => p.id), [250]);
    });
  });

  test('repository getIndex is fetched once', () async {
    var calls = 0;
    final repo = PokemonRepository(
      PokeApiDataSource(
        ApiClient(
          client: MockClient((req) async {
            calls++;
            expect(req.url.queryParameters['limit'], '3000');
            return http.Response(pageJson(0, 3, hasNext: false), 200);
          }),
        ),
      ),
    );
    expect(await repo.getIndex(), hasLength(3));
    expect(await repo.getIndex(), hasLength(3));
    expect(calls, 1);
  });
}
