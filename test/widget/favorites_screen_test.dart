import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/shared/widgets/chips.dart';
import 'package:pokedex_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> favorites(
  FakePokeApi api, {
  List<String> saved = const [],
}) async {
  return testRouterApp(
    [
      GoRoute(path: '/', builder: (_, _) => const FavoritesScreen()),
      GoRoute(
        path: '/pokedex',
        builder: (_, _) => const Scaffold(body: Text('pokedex tab')),
      ),
      GoRoute(
        path: '/pokemon/:id',
        builder: (_, s) =>
            Scaffold(body: Text('details ${s.pathParameters['id']}')),
      ),
    ],
    overrides: await overridesFor(
      api,
      prefs: {if (saved.isNotEmpty) 'favorite_pokemon_ids': saved},
    ),
  );
}

void main() {
  testWidgets('empty state offers to browse', (tester) async {
    await tester.pumpWidget(await favorites(FakePokeApi()));
    await settle(tester);

    expect(find.text('My collection'), findsOneWidget);
    expect(find.text('0 of 6 collected'), findsOneWidget);
    expect(find.text('No favorites yet'), findsOneWidget);

    await tester.tap(find.text('Browse Pokémon'));
    await settle(tester);
    expect(find.text('pokedex tab'), findsOneWidget);
  });

  testWidgets('lists saved Pokémon, newest first, with collection count',
      (tester) async {
    await tester.pumpWidget(
      await favorites(FakePokeApi(), saved: ['6', '1']),
    );
    await settle(tester);

    expect(find.text('2 of 6 collected'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);

    final first = tester.getTopLeft(find.text('Charizard'));
    final second = tester.getTopLeft(find.text('Bulbasaur'));
    expect(first.dx, lessThan(second.dx));
  });

  testWidgets('search and type chips filter the collection', (tester) async {
    await tester.pumpWidget(
      await favorites(FakePokeApi(), saved: ['6', '1', '4']),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'char');
    await settle(tester);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Charizard'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await settle(tester);
    expect(
      find.text('No saved Pokémon match your filters.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '');
    await settle(tester);
    // Only types that appear in the collection are offered.
    expect(find.widgetWithText(PillChip, 'Fire'), findsOneWidget);
    expect(find.widgetWithText(PillChip, 'Water'), findsNothing);
    await tester.tap(find.widgetWithText(PillChip, 'Fire'));
    await settle(tester);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Charmander'), findsOneWidget);
  });

  testWidgets('un-favoriting removes the card and persists', (tester) async {
    await tester.pumpWidget(
      await favorites(FakePokeApi(), saved: ['6', '1']),
    );
    await settle(tester);

    await tester.tap(find.byTooltip('Remove from favorites').first);
    await tester.pump();

    expect(find.text('Charizard'), findsNothing);
    expect(find.text('Bulbasaur'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_pokemon_ids'), ['1']);
  });

  testWidgets('tapping a card opens details', (tester) async {
    await tester.pumpWidget(await favorites(FakePokeApi(), saved: ['5']));
    await settle(tester);

    await tester.tap(find.text('Charmeleon'));
    await settle(tester);
    expect(find.text('details 5'), findsOneWidget);
  });

  testWidgets('error with retry when the list cannot load', (tester) async {
    final api = FakePokeApi(failEverything: true);
    await tester.pumpWidget(await favorites(api, saved: ['1']));
    await settle(tester);
    expect(find.text('Retry'), findsOneWidget);

    api.failEverything = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });
}
