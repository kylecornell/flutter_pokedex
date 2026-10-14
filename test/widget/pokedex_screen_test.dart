import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/pokedex/presentation/screens/pokedex_screen.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';
import 'package:pokedex_app/shared/repositories/type_repository.dart';

const _fireJson = '''
{"name":"fire","damage_relations":{},"pokemon":[
  {"slot":1,"pokemon":{"name":"ivysaur","url":"https://pokeapi.co/api/v2/pokemon/2/"}},
  {"slot":1,"pokemon":{"name":"ivysaur-mega","url":"https://pokeapi.co/api/v2/pokemon/10001/"}}]}''';

const _listJson = '''
{"count":2,"next":null,"results":[
  {"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"},
  {"name":"ivysaur","url":"https://pokeapi.co/api/v2/pokemon/2/"}]}''';

Future<http.Response> _withTypes(http.Request req) async => req.url.path.contains('/type/')
    ? http.Response(_fireJson, 200)
    : http.Response(_listJson, 200);

Widget _app(Future<http.Response> Function(http.Request) handler) {
  final dataSource = PokeApiDataSource(ApiClient(client: MockClient(handler)));
  return ProviderScope(
    overrides: [
      pokemonRepositoryProvider
          .overrideWithValue(PokemonRepository(dataSource)),
      typeRepositoryProvider.overrideWithValue(TypeRepository(dataSource)),
    ],
    child: const MaterialApp(home: PokedexScreen()),
  );
}

void main() {
  testWidgets('shows loaded Pokémon and filters by search', (tester) async {
    await tester.pumpWidget(_app((_) async => http.Response(_listJson, 200)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), 'ivy');
    await tester.pump();
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('shows error with retry when first load fails', (tester) async {
    var fail = true;
    await tester.pumpWidget(_app((_) async {
      return fail ? http.Response('', 500) : http.Response(_listJson, 200);
    }));
    await tester.pump();
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('tapping a card opens /pokemon/:id', (tester) async {
    final repo = PokemonRepository(
      PokeApiDataSource(
        ApiClient(
          client: MockClient((_) async => http.Response(_listJson, 200)),
        ),
      ),
    );
    final router = GoRouter(
      initialLocation: '/pokedex',
      routes: [
        GoRoute(path: '/pokedex', builder: (_, _) => const PokedexScreen()),
        GoRoute(
          path: '/pokemon/:id',
          builder: (_, state) =>
              Scaffold(body: Text('details ${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pokemonRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Ivysaur'));
    await tester.pumpAndSettle();

    expect(find.text('details 2'), findsOneWidget);
  });

  testWidgets('type chip filters list to that type, forms excluded',
      (tester) async {
    await tester.pumpWidget(_app(_withTypes));
    await tester.pump();
    await tester.pump();
    expect(find.text('Bulbasaur'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Fire'));
    // type request -> pokemonOfTypeProvider -> results provider
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Ivysaur Mega'), findsNothing);

    // Tapping the selected chip clears the filter.
    await tester.tap(find.widgetWithText(FilterChip, 'Fire'));
    await tester.pump();
    expect(find.text('Bulbasaur'), findsOneWidget);
  });
}
