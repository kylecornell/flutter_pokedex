import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/prefs.dart';

const _listJson = '''
{"count":3,"next":null,"results":[
  {"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"},
  {"name":"ivysaur","url":"https://pokeapi.co/api/v2/pokemon/2/"},
  {"name":"venusaur","url":"https://pokeapi.co/api/v2/pokemon/3/"}]}''';

Future<Widget> _app({
  List<String> saved = const [],
  Future<http.Response> Function(http.Request)? api,
}) async {
  final repo = PokemonRepository(
    PokeApiDataSource(
      ApiClient(
        client: MockClient(api ?? (_) async => http.Response(_listJson, 200)),
      ),
    ),
  );
  return ProviderScope(
    overrides: [
      await prefsOverride({
        if (saved.isNotEmpty) 'favorite_pokemon_ids': saved,
      }),
      pokemonRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: FavoritesScreen()),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(await _app());
    await tester.pump();

    expect(find.textContaining('No favorites yet'), findsOneWidget);
  });

  testWidgets('lists saved Pokémon, newest first', (tester) async {
    await tester.pumpWidget(await _app(saved: ['3', '1']));
    await _settle(tester);

    expect(find.text('Venusaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);

    final venusaurX = tester.getTopLeft(find.text('Venusaur')).dx;
    final bulbasaurX = tester.getTopLeft(find.text('Bulbasaur')).dx;
    expect(venusaurX, lessThan(bulbasaurX));
  });

  testWidgets('un-favoriting removes the card and persists', (tester) async {
    await tester.pumpWidget(await _app(saved: ['3', '1']));
    await _settle(tester);

    await tester.tap(find.byTooltip('Remove from favorites').first);
    await tester.pump();

    expect(find.text('Venusaur'), findsNothing);
    expect(find.text('Bulbasaur'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_pokemon_ids'), ['1']);
  });

  testWidgets('shows error with retry when index fails', (tester) async {
    await tester.pumpWidget(
      await _app(saved: ['1'], api: (_) async => http.Response('', 500)),
    );
    await _settle(tester);

    expect(find.text('Retry'), findsOneWidget);
  });
}
