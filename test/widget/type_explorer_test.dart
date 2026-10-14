import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/type_explorer/presentation/screens/type_detail_screen.dart';
import 'package:pokedex_app/features/type_explorer/presentation/screens/type_explorer_screen.dart';
import 'package:pokedex_app/features/type_explorer/presentation/screens/type_matchup_screen.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/type_repository.dart';

String _fixture(String n) => File('test/fixtures/$n').readAsStringSync();

Future<http.Response> _api(http.Request req) async => switch (req.url.path) {
      '/api/v2/type/fire' => http.Response(_fixture('type_fire.json'), 200),
      '/api/v2/type/ghost' => http.Response(_fixture('type_ghost.json'), 200),
      _ => http.Response('', 404),
    };

Widget _app(Widget home, {Future<http.Response> Function(http.Request)? api}) {
  final repo = TypeRepository(
    PokeApiDataSource(ApiClient(client: MockClient(api ?? _api))),
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(path: '/types/matchup', builder: (_, _) => const TypeMatchupScreen()),
      GoRoute(
        path: '/types/:name',
        builder: (_, s) => TypeDetailScreen(typeName: s.pathParameters['name']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [typeRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

void main() {
  testWidgets('explorer shows type orbs and opens a type', (tester) async {
    await tester.pumpWidget(_app(const TypeExplorerScreen()));
    await tester.pump();

    expect(find.text('Fire'), findsOneWidget);
    expect(find.text('Matchup calculator'), findsOneWidget);

    await tester.tap(find.text('Fire'));
    await tester.pumpAndSettle();
    await _settle(tester);

    expect(find.text('Fire type'), findsOneWidget);
    expect(find.text('When attacking'), findsOneWidget);
  });

  testWidgets('type detail groups attack and defense multipliers',
      (tester) async {
    await tester.pumpWidget(_app(const TypeDetailScreen(typeName: 'fire')));
    await _settle(tester);

    expect(find.text('When attacking'), findsOneWidget);
    expect(find.text('2×'), findsNWidgets(2)); // attack + defense sections
    expect(find.text('½×'), findsNWidgets(2));
    // Fire resists/is weak to listed types appear as badges.
    expect(find.text('Grass'), findsWidgets);
  });

  testWidgets('type detail shows retry on failure', (tester) async {
    await tester.pumpWidget(
      _app(
        const TypeDetailScreen(typeName: 'fire'),
        api: (_) async => http.Response('', 500),
      ),
    );
    await _settle(tester);

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('matchup screen computes attacker vs dual defender',
      (tester) async {
    await tester.pumpWidget(_app(const TypeMatchupScreen()));
    await tester.pump();

    expect(find.text('Select a defender type to see matchups.'), findsOneWidget);

    // Same labels appear in attacker and defender pickers: first = attacker.
    await tester.tap(find.text('Ghost').first);
    await tester.pump();
    await tester.tap(find.text('Ghost').last);
    await tester.pump();
    await tester.tap(find.text('Fire').last);
    await _settle(tester);

    expect(find.text('Ghost attacking Ghost/Fire'), findsOneWidget);
    expect(find.text('2×'), findsWidgets);
    expect(find.text('Damage taken by Ghost/Fire'), findsOneWidget);
  });
}
