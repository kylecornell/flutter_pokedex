import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/pokedex/presentation/screens/pokedex_screen.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';

const _listJson = '''
{"count":2,"next":null,"results":[
  {"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"},
  {"name":"ivysaur","url":"https://pokeapi.co/api/v2/pokemon/2/"}]}''';

Widget _app(Future<http.Response> Function(http.Request) handler) {
  final repo = PokemonRepository(
    PokeApiDataSource(ApiClient(client: MockClient(handler))),
  );
  return ProviderScope(
    overrides: [pokemonRepositoryProvider.overrideWithValue(repo)],
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
}
