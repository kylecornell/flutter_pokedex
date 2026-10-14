import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/features/type_explorer/presentation/screens/type_explorer_screen.dart';
import 'package:pokedex_app/features/type_explorer/presentation/screens/type_matchup_screen.dart';
import 'package:pokedex_app/features/type_explorer/presentation/widgets/orbit_view.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> explorer(FakePokeApi api, {String? initial}) async {
  return testRouterApp(
    [
      GoRoute(
        path: '/',
        builder: (_, _) => TypeExplorerScreen(initialType: initial),
      ),
      GoRoute(
        path: '/types/matchup',
        builder: (_, _) => const TypeMatchupScreen(),
      ),
    ],
    overrides: await overridesFor(api),
  );
}

void main() {
  testWidgets('grid shows all 18 types, selecting one opens its header',
      (tester) async {
    useTallScreen(tester);
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi()));
    await settle(tester);

    expect(find.text('18 types · tap one to explore'), findsOneWidget);
    expect(find.text('ALL 18 TYPES · TAP TO EXPLORE'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);

    await tester.tap(find.text('Fire'));
    await settle(tester);

    expect(find.text('Fire type'), findsOneWidget);
    expect(
      find.textContaining('powerful flame-based attacks'),
      findsOneWidget,
    );
    expect(find.text('FIRE ATTACKING · TAP A TYPE'), findsOneWidget);
    expect(find.text('Damage Fire moves deal to each type.'), findsOneWidget);
    // Orbit view is the default.
    expect(find.byType(OrbitView), findsOneWidget);
  });

  testWidgets('attack grid badges show multipliers; neutral types dim',
      (tester) async {
    useTallScreen(tester);
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'fire'));
    await settle(tester);

    // Fire is 2x vs Grass and 0.5x vs Water; badges appear on the grid.
    expect(find.text('2×'), findsWidgets);
    expect(find.text('0.5×'), findsWidgets);
  });

  testWidgets('defense mode flips the meaning', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'fire'));
    await settle(tester);

    await tester.tap(find.text('Defense'));
    await settle(tester);
    expect(find.text('FIRE DEFENDING · TAP A TYPE'), findsOneWidget);
    expect(
      find.text('Damage a Fire Pokémon takes from each type.'),
      findsOneWidget,
    );
    expect(find.text('Weakness'), findsOneWidget); // legend
  });

  testWidgets('list view groups types by multiplier', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'fire'));
    await settle(tester);

    await tester.tap(find.byTooltip('List view'));
    await settle(tester);

    expect(find.text('Super effective'), findsOneWidget);
    expect(find.text('Not very effective'), findsOneWidget);
    expect(find.text('No effect'), findsOneWidget);
    expect(find.text('Normal damage'), findsOneWidget);
    expect(find.text('None'), findsOneWidget); // fire has no immunities to hit
    expect(find.text('4 types'), findsWidgets); // grass, bug, ice, steel
  });

  testWidgets('orbit: focusing an orb explains the matchup and Open selects it',
      (tester) async {
    useTallScreen(tester);
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'fire'));
    await settle(tester);

    expect(find.text('Tap an outer orb to see the matchup.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Grass, Super effective')));
    await settle(tester);
    expect(
      find.text('Fire attacks deal 2× damage to Grass Pokémon.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open'));
    await settle(tester);
    expect(find.text('Grass type'), findsOneWidget);
  });

  testWidgets('Clear returns to the full grid', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'ghost'));
    await settle(tester);
    expect(find.text('Ghost type'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await settle(tester);
    expect(find.text('Ghost type'), findsNothing);
    expect(find.text('ALL 18 TYPES · TAP TO EXPLORE'), findsOneWidget);
  });

  testWidgets('unknown initial type is ignored', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi(), initial: 'cosmic'));
    await settle(tester);
    expect(find.text('ALL 18 TYPES · TAP TO EXPLORE'), findsOneWidget);
  });

  testWidgets('shows an error when the type cannot load', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      await explorer(FakePokeApi(failEverything: true), initial: 'fire'),
    );
    await settle(tester);
    expect(find.textContaining('Server error'), findsOneWidget);
  });

  testWidgets('matchup calculator link opens the matchup screen',
      (tester) async {
    useTallScreen(tester);
    useTallScreen(tester);
    await tester.pumpWidget(await explorer(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Matchup calculator'));
    await settle(tester);
    expect(find.text('Type Matchup'), findsOneWidget);
  });

  group('matchup screen', () {
    Future<Widget> matchup(FakePokeApi api) async => testApp(
          const TypeMatchupScreen(),
          overrides: await overridesFor(api),
        );

    testWidgets('computes attacker vs a dual-type defender', (tester) async {
    useTallScreen(tester);
      await tester.pumpWidget(await matchup(FakePokeApi()));
      await settle(tester);

      expect(
        find.text('Select a defender type to see matchups.'),
        findsOneWidget,
      );

      // Same labels appear in both pickers: first = attacker, last = defender.
      await tester.tap(find.text('Ghost').first);
      await tester.pump();
      await tester.tap(find.text('Ghost').last);
      await tester.pump();
      await tester.tap(find.text('Fire').last);
      await settle(tester);

      expect(find.text('Ghost attacking Ghost/Fire'), findsOneWidget);
      expect(find.text('2×'), findsWidgets);
      expect(find.text('Damage taken by Ghost/Fire'), findsOneWidget);
    });

    testWidgets('clear resets the selection', (tester) async {
    useTallScreen(tester);
      await tester.pumpWidget(await matchup(FakePokeApi()));
      await settle(tester);

      await tester.tap(find.text('Fire').last);
      await settle(tester);
      expect(find.text('Damage taken by Fire'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear'));
      await settle(tester);
      expect(
        find.text('Select a defender type to see matchups.'),
        findsOneWidget,
      );
    });
  });
}
