import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/app/app.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

Future<Widget> app(FakePokeApi api, {Map<String, Object> prefs = const {}}) async {
  return ProviderScope(
    overrides: await overridesFor(api, prefs: prefs),
    child: const PokedexApp(),
  );
}

void main() {
  testWidgets('boots to Home with the hero header and bottom navigation',
      (tester) async {
    await tester.pumpWidget(await app(FakePokeApi()));
    await settle(tester);

    expect(find.text('Pokédex'), findsWidgets);
    expect(find.text('Discover the world of Pokémon'), findsOneWidget);
    for (final label in ['Home', 'Pokédex', 'Catch', 'Favorites', 'Settings']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
  });

  testWidgets('tabs switch and keep their own state', (tester) async {
    await tester.pumpWidget(await app(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Pokédex').last);
    await settle(tester);
    expect(find.textContaining('National Dex'), findsOneWidget);

    await tester.tap(find.text('Favorites').last);
    await settle(tester);
    expect(find.text('My collection'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await settle(tester);
    expect(find.text('Preferred display mode'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(find.text('Discover the world of Pokémon'), findsOneWidget);
  });

  testWidgets('saved theme mode is applied at startup', (tester) async {
    await tester.pumpWidget(
      await app(FakePokeApi(), prefs: {'settings_theme_mode': 'dark'}),
    );
    await settle(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('opening a Pokémon from Home shows its card, back returns',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(await app(FakePokeApi()));
    await settle(tester);

    await tester.tap(find.text('Charmander').first);
    await settle(tester);
    expect(find.text('HP '), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('Discover the world of Pokémon'), findsOneWidget);
  });
}
