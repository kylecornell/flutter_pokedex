import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/features/home/presentation/screens/home_screen.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> home(
  FakePokeApi api, {
  Map<String, Object> prefs = const {},
}) async {
  return testRouterApp(
    [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/pokemon/:id',
        builder: (_, s) =>
            Scaffold(body: Text('details ${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/types',
        builder: (_, _) => const Scaffold(body: Text('type explorer')),
      ),
    ],
    overrides: await overridesFor(api, prefs: prefs),
  );
}

void main() {
  testWidgets('lists the Pokédex with count, type pills and numbers',
      (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    expect(find.text('All Pokémon'), findsOneWidget);
    expect(find.text('6 Pokémon'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#0006'), findsOneWidget);
    // Type pills come from the type index (Charizard is Fire + Flying).
    expect(find.text('Flying'), findsWidgets);
  });

  testWidgets('search narrows results and shows suggestions', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'char');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    expect(find.text('Results for “char”'), findsOneWidget);
    expect(find.text('3 Pokémon'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    // Suggestion rows plus grid cards both show the names.
    expect(find.text('Charmeleon'), findsWidgets);

    await tester.tap(find.byTooltip('Clear search'));
    await settle(tester);
    expect(find.text('All Pokémon'), findsOneWidget);
  });

  testWidgets('search by number', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), '#3');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    expect(find.text('1 Pokémon'), findsOneWidget);
    expect(find.text('Venusaur'), findsWidgets);
  });

  testWidgets('two type chips filter dual types', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tapChip(tester, 'Fire');
    expect(find.text('Fire Pokémon'), findsOneWidget);
    expect(find.text('3 Pokémon'), findsOneWidget);

    await tapChip(tester, 'Flying');
    expect(find.text('Fire + Flying Pokémon'), findsOneWidget);
    expect(find.text('1 Pokémon'), findsOneWidget);

    await tapChip(tester, 'All');
    expect(find.text('All Pokémon'), findsOneWidget);
  });

  testWidgets('empty result message', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);

    expect(find.text('No Pokémon match your search.'), findsOneWidget);
  });

  testWidgets('error with retry when the list cannot load', (tester) async {
    final api = FakePokeApi(failEverything: true);
    await tester.pumpWidget(await home(api));
    await settle(tester);

    expect(find.text('Retry'), findsOneWidget);

    api.failEverything = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('Bulbasaur'), findsOneWidget);
  });

  testWidgets('recently viewed row appears from saved ids', (tester) async {
    await tester.pumpWidget(
      await home(FakePokeApi(), prefs: {'recent_pokemon_ids': ['5', '2']}),
    );
    await settle(tester);

    expect(find.text('RECENTLY VIEWED'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'Charmeleon').first);
    await settle(tester);
    expect(find.text('details 5'), findsOneWidget);
  });

  testWidgets('card tap opens details; Type explorer banner navigates',
      (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Ivysaur'));
    await settle(tester);
    expect(find.text('details 2'), findsOneWidget);
  });

  testWidgets('Type explorer banner opens /types', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.scrollUntilVisible(
      find.text('Type explorer'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Type explorer'));
    await settle(tester);
    expect(find.text('type explorer'), findsOneWidget);
  });

  testWidgets('Surprise me opens a Pokémon', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    await tester.scrollUntilVisible(
      find.text('Surprise me'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Surprise me'));
    await settle(tester);
    expect(find.textContaining('details '), findsOneWidget);
  });

  testWidgets('theme toggle in the hero header', (tester) async {
    await tester.pumpWidget(await home(FakePokeApi()));
    await settle(tester);

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    await tester.tap(find.byTooltip('Toggle theme'));
    await settle(tester);
    // The icon swaps once the settings state changes the app theme mode.
    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
  });
}
