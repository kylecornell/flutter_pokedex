import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/pokemon_details/presentation/screens/pokemon_detail_screen.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/pokemon_repository.dart';

import '../helpers/prefs.dart';


late Override _prefs;

String _fixture(String name) =>
    File('test/fixtures/$name').readAsStringSync();

Widget _app(Future<http.Response> Function(http.Request) handler) {
  final repo = PokemonRepository(
    PokeApiDataSource(ApiClient(client: MockClient(handler))),
  );
  return ProviderScope(
    overrides: [_prefs, pokemonRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: PokemonDetailScreen(pokemonId: '4')),
  );
}

Future<http.Response> _happyPath(http.Request req) async {
  return switch (req.url.path) {
    '/api/v2/pokemon/4' =>
      http.Response(_fixture('pokemon_charmander.json'), 200),
    '/api/v2/pokemon-species/charmander' =>
      http.Response(_fixture('pokemon_species_charmander.json'), 200),
    '/api/v2/evolution-chain/2' =>
      http.Response(_fixture('evolution_chain_charmander.json'), 200),
    _ => http.Response('', 404),
  };
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  setUp(() async => _prefs = await prefsOverride());

  testWidgets('shows profile, stats and evolution stages', (tester) async {
    await tester.pumpWidget(_app(_happyPath));
    await _settle(tester);

    expect(find.text('Charmander'), findsWidgets); // app bar, header, chain
    expect(find.text('#0004'), findsOneWidget);
    expect(find.text('Fire'), findsOneWidget);
    expect(find.text('0.6 m'), findsOneWidget);
    expect(find.text('8.5 kg'), findsOneWidget);
    expect(find.text('HP'), findsOneWidget);
    expect(find.text('Special Attack'), findsOneWidget);
    expect(find.text('99'), findsOneWidget); // total 39 + 60

    await tester.scrollUntilVisible(find.text('Charizard'), 200);
    expect(find.text('Charmeleon'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
  });

  testWidgets('evolution failure does not hide the rest of the page',
      (tester) async {
    await tester.pumpWidget(_app((req) async {
      if (req.url.path.contains('pokemon-species')) {
        return http.Response('', 500);
      }
      return _happyPath(req);
    }));
    await _settle(tester);

    expect(find.text('Base stats'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Could not load evolutions'),
      200,
    );
    expect(find.textContaining('Could not load evolutions'), findsOneWidget);
  });

  testWidgets('shows error with retry when pokemon fails to load',
      (tester) async {
    var fail = true;
    await tester.pumpWidget(_app((req) async {
      return fail ? http.Response('', 404) : _happyPath(req);
    }));
    await _settle(tester);

    expect(find.text('Not found.'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(find.text('#0004'), findsOneWidget);
  });

  testWidgets('heart in app bar toggles favorite and persists',
      (tester) async {
    await tester.pumpWidget(_app(_happyPath));
    await _settle(tester);

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_pokemon_ids'), ['4']);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(prefs.getStringList('favorite_pokemon_ids'), isEmpty);
  });
}
