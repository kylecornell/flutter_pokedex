import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/features/pokemon_details/presentation/screens/pokemon_detail_screen.dart';
import 'package:pokedex_app/shared/widgets/chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> detail(
  FakePokeApi api, {
  String id = '4',
  Map<String, Object> prefs = const {},
}) async {
  return testRouterApp(
    [
      GoRoute(
        path: '/',
        builder: (_, _) => PokemonDetailScreen(pokemonId: id),
      ),
      GoRoute(
        path: '/pokemon/:id',
        builder: (_, s) => PokemonDetailScreen(pokemonId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/types/:name',
        builder: (_, s) =>
            Scaffold(body: Text('type ${s.pathParameters['name']}')),
      ),
    ],
    overrides: await overridesFor(api, prefs: prefs),
  );
}

Future<void> openTab(WidgetTester tester, String label) async {
  final tab = find.text(label);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await settle(tester);
}

void main() {
  testWidgets('shows the trading card front', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    expect(find.text('Charmander'), findsWidgets); // top bar + card
    expect(find.text('#0004'), findsWidgets);
    expect(find.text('HP '), findsOneWidget);
    expect(find.text('44'), findsOneWidget);
    expect(find.textContaining('Seed Pokémon'), findsWidgets);
    expect(find.text('Fire'), findsWidgets);
    expect(find.text('HEIGHT'), findsWidgets); // card + Overview tab
    expect(find.text('1.4 m'), findsWidgets);
    expect(find.text('Gen I · Kanto'), findsWidgets);
    expect(find.text('Ability · Overgrow'), findsOneWidget);
    // Display mode switch and tabs.
    for (final label in ['Artwork', 'Animated', '3D']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Overview'), findsOneWidget);
  });

  testWidgets('tapping the picture flips the card to the Pokédex entry',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    expect(find.textContaining('POKÉDEX ENTRY'), findsNothing);
    await tester.tap(find.text('Tap to flip'));
    await settle(tester, rounds: 20);

    expect(find.textContaining('POKÉDEX ENTRY'), findsOneWidget);
    expect(
      find.text('A strange seed was planted on its back.'),
      findsWidgets, // card back + overview tab
    );
    expect(find.text('HABITAT'), findsOneWidget);

    await tester.tap(find.textContaining('POKÉDEX ENTRY'));
    await settle(tester, rounds: 20);
    expect(find.textContaining('POKÉDEX ENTRY'), findsNothing);
  });

  testWidgets('Flip card button flips to the back with base stats, then back',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    expect(find.text('Flip card'), findsOneWidget);
    await tester.tap(find.text('Flip card'));
    await settle(tester, rounds: 20);

    // Back face: Pokédex entry, base stats and facts.
    expect(find.textContaining('POKÉDEX ENTRY'), findsOneWidget);
    expect(find.text('BASE STATS'), findsOneWidget);
    expect(find.text('Sp. Atk'), findsOneWidget);
    expect(find.text('64'), findsWidgets); // special-attack (+ base exp 64)
    expect(find.text('REGION'), findsOneWidget);
    expect(find.text('Show front'), findsOneWidget);

    await tester.tap(find.text('Show front'));
    await settle(tester, rounds: 20);
    expect(find.textContaining('POKÉDEX ENTRY'), findsNothing);
    expect(find.text('Flip card'), findsOneWidget);
  });

  testWidgets('tapping the card face (not just the picture) flips it',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    // The measures panel is part of the face but not the picture window.
    await tester.tap(find.text('BASE EXP'));
    await settle(tester, rounds: 20);
    expect(find.textContaining('POKÉDEX ENTRY'), findsOneWidget);
  });

  testWidgets('overview tab lists facts', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    expect(find.text('HIDDEN ABILITY'), findsOneWidget);
    expect(find.text('Chlorophyll'), findsOneWidget);
    expect(find.text('BASE EXPERIENCE'), findsOneWidget);
  });

  testWidgets('stats tab shows bars labels and total', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);
    await openTab(tester, 'Stats');

    expect(find.text('HP'), findsOneWidget);
    expect(find.text('Attack'), findsOneWidget);
    expect(find.text('Sp. Atk'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('${44 + 54 + 64}'), findsOneWidget);
    expect(find.text('Bars scaled to 180'), findsOneWidget);
  });

  testWidgets('evolution tab shows stages and requirements', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);
    await openTab(tester, 'Evolution');

    expect(find.text('Charmeleon'), findsOneWidget);
    expect(find.text('Lv. 16'), findsOneWidget);
    expect(find.text('Lv. 36'), findsOneWidget);
    expect(find.text('Tap a stage to open it.'), findsOneWidget);

    await tester.tap(find.text('Charmeleon'));
    await settle(tester);
    expect(find.text('#0005'), findsWidgets);
  });

  testWidgets('moves tab loads details and filters by method',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);
    await openTab(tester, 'Moves');
    await settle(tester);

    expect(
      find.textContaining('Learnset from Scarlet / Violet (2 moves)'),
      findsOneWidget,
    );
    expect(find.text('Tackle'), findsOneWidget);
    expect(find.text('Ember'), findsOneWidget);
    expect(find.text('Lv 1'), findsOneWidget);
    expect(find.text('Pwr 40'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(PillChip, 'TM'));
    await settle(tester);
    expect(find.text('Ember'), findsOneWidget);
    expect(find.text('Tackle'), findsNothing);

    await tester.tap(find.widgetWithText(PillChip, 'All').first);
    await settle(tester);
    expect(find.text('Tackle'), findsOneWidget);
    expect(find.text('Ember'), findsOneWidget);
  });

  testWidgets('moves tab filters by move type', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);
    await openTab(tester, 'Moves');
    await settle(tester);

    // Only types that actually occur are offered: Normal (Tackle), Fire (Ember).
    final scroller = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.widgetWithText(PillChip, 'Fire'),
      80,
      scrollable: scroller,
      maxScrolls: 5,
    );
    expect(find.widgetWithText(PillChip, 'Water'), findsNothing);
  });

  testWidgets('abilities tab shows descriptions and hidden badge',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);
    await openTab(tester, 'Abilities');

    expect(find.text('Overgrow'), findsOneWidget);
    expect(find.text('Chlorophyll'), findsOneWidget);
    expect(find.text('Hidden'), findsOneWidget);
    expect(
      find.text('Powers up Grass moves in a pinch.'),
      findsNWidgets(2),
    );
  });

  testWidgets('forms: Mega form renames the card and adds a ribbon',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi(), id: '6'));
    await settle(tester);

    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Mega X'), findsOneWidget);

    await tester.tap(find.text('Mega X'));
    await settle(tester);
    expect(find.text('Mega Charizard X'), findsWidgets);
    expect(find.text('MEGA EVOLUTION'), findsOneWidget);
    // Mega X is Fire / Dragon in the fake data.
    expect(find.text('Dragon'), findsOneWidget);

    await tester.tap(find.text('Base'));
    await settle(tester);
    expect(find.text('MEGA EVOLUTION'), findsNothing);
  });

  testWidgets('mode switch: 3D falls back with a way back to artwork',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('3D'));
    await settle(tester);
    expect(find.text('3D model not available for this Pokémon.'), findsOneWidget);

    await tester.tap(find.text('Show artwork'));
    await settle(tester);
    expect(find.text('3D model not available for this Pokémon.'), findsNothing);
    expect(find.text('Tap to flip'), findsOneWidget);
  });

  testWidgets('animated mode keeps the card usable when the sprite is missing',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Animated'));
    await settle(tester);
    expect(find.text('Charmander'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preferred display mode from settings is used on open',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(
      await detail(
        FakePokeApi(),
        prefs: {'settings_viewer_mode': 'model3d'},
      ),
    );
    await settle(tester);
    expect(find.text('3D model not available for this Pokémon.'), findsOneWidget);
  });

  testWidgets('heart toggles favorite and persists', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_pokemon_ids'), ['4']);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pump();
    expect(prefs.getStringList('favorite_pokemon_ids'), isEmpty);
  });

  testWidgets('opening records the Pokémon as recently viewed',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi(), id: '5'));
    await settle(tester);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('recent_pokemon_ids'), ['5']);
  });

  testWidgets('type badge opens the Type Explorer for that type',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    // The card's type badge (first "Fire"; the Overview tab lists it too).
    await tester.tap(find.text('Fire').first);
    await settle(tester);
    expect(find.text('type fire'), findsOneWidget);
  });

  testWidgets('full screen shows the card in an overlay and closes',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Full screen'));
    await settle(tester);
    expect(find.byTooltip('Close full screen'), findsOneWidget);

    await tester.tap(find.byTooltip('Close full screen'));
    await settle(tester);
    expect(find.byTooltip('Close full screen'), findsNothing);
  });

  testWidgets('card tilts under a finger and settles back', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi()));
    await settle(tester);

    final center = tester.getCenter(find.text('HP '));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(40, 20));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await gesture.up();
    await settle(tester);
    expect(find.text('HP '), findsOneWidget);
  });

  testWidgets('error with retry', (tester) async {
    useTallScreen(tester);
    final api = FakePokeApi(failEverything: true);
    await tester.pumpWidget(await detail(api));
    await settle(tester);
    expect(find.text('Retry'), findsOneWidget);

    api.failEverything = false;
    await tester.tap(find.text('Retry'));
    await settle(tester);
    expect(find.text('HP '), findsOneWidget);
  });

  testWidgets('unknown Pokémon shows an error, not a crash', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await detail(FakePokeApi(), id: '9999'));
    await settle(tester);
    expect(find.text('Not found.'), findsOneWidget);
  });
}
