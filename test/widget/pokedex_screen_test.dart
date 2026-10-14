import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/features/pokedex/presentation/screens/pokedex_screen.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> dex(FakePokeApi api) async => testRouterApp(
      [
        GoRoute(path: '/', builder: (_, _) => const PokedexScreen()),
        GoRoute(
          path: '/pokemon/:id',
          builder: (_, s) =>
              Scaffold(body: Text('details ${s.pathParameters['id']}')),
        ),
      ],
      overrides: await overridesFor(api),
    );

/// Names of the Pokémon cards in on-screen order (top to bottom, left to
/// right).
List<String> shownNames(WidgetTester tester) {
  const names = [
    'Bulbasaur',
    'Ivysaur',
    'Venusaur',
    'Charmander',
    'Charmeleon',
    'Charizard',
  ];
  final found = <(Offset, String)>[];
  for (final n in names) {
    for (final e in find.text(n).evaluate()) {
      found.add((tester.getTopLeft(find.byWidget(e.widget)), n));
    }
  }
  found.sort((a, b) {
    final dy = a.$1.dy.compareTo(b.$1.dy);
    return dy != 0 ? dy : a.$1.dx.compareTo(b.$1.dx);
  });
  return [for (final f in found) f.$2];
}

void main() {
  testWidgets('shows count, generation chips and all Pokémon', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    expect(find.text('6 of 6 · National Dex'), findsOneWidget);
    expect(find.text('All gens'), findsOneWidget);
    expect(find.text('I · Kanto'), findsOneWidget);
    expect(find.text('II · Johto'), findsOneWidget);
    expect(shownNames(tester), hasLength(6));
  });

  testWidgets('generation filter, then empty state', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('I · Kanto'));
    await settle(tester);
    expect(find.text('6 of 6 · National Dex'), findsOneWidget);

    await tester.tap(find.text('II · Johto'));
    await settle(tester);
    expect(find.text('0 of 6 · National Dex'), findsOneWidget);
    expect(find.text('No Pokémon match these filters.'), findsOneWidget);

    await tester.tap(find.text('All gens'));
    await settle(tester);
    expect(find.text('6 of 6 · National Dex'), findsOneWidget);
  });

  testWidgets('sort A–Z changes the order', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    expect(shownNames(tester).first, 'Bulbasaur');
    await tester.tap(find.text('A–Z'));
    await settle(tester);
    // Charizard sorts before Charmander.
    final names = shownNames(tester);
    expect(names.indexOf('Charizard'), lessThan(names.indexOf('Charmander')));

    await tester.tap(find.text('No.'));
    await settle(tester);
    expect(shownNames(tester).first, 'Bulbasaur');
  });

  testWidgets('type chips combine to a dual-type filter', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    await tapChip(tester, 'Grass');
    expect(find.text('3 of 6 · National Dex'), findsOneWidget);

    await tapChip(tester, 'Poison');
    expect(find.text('3 of 6 · National Dex'), findsOneWidget);

    // A third pick drops the oldest (Grass), leaving Poison + Fire = none.
    await tapChip(tester, 'Fire');
    expect(find.text('0 of 6 · National Dex'), findsOneWidget);
  });

  testWidgets('tapping a card opens /pokemon/:id', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Charizard'));
    await settle(tester);
    expect(find.text('details 6'), findsOneWidget);
  });

  testWidgets('heart on a card saves the favorite', (tester) async {
    await tester.pumpWidget(await dex(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.byTooltip('Add to favorites').first);
    await tester.pump();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });

  testWidgets('error with retry', (tester) async {
    final api = FakePokeApi(failEverything: true);
    await tester.pumpWidget(await dex(api));
    await settle(tester);
    expect(find.text('Retry'), findsOneWidget);

    api.failEverything = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('6 of 6 · National Dex'), findsOneWidget);
  });
}
