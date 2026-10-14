import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:pokedex_app/shared/models/app_settings.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';
import 'package:pokedex_app/shared/providers/settings_provider.dart';
import 'package:pokedex_app/shared/widgets/pokemon_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/prefs.dart';

void main() {
  testWidgets('segments and switch change and persist settings',
      (tester) async {
    final container = ProviderContainer(overrides: [await prefsOverride()]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

    await tester.tap(find.text('Compact'));
    await tester.pump();
    expect(container.read(settingsProvider).gridDensity, GridDensity.compact);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(container.read(settingsProvider).animationsEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_theme_mode'), 'dark');
    expect(prefs.getBool('settings_animations'), isFalse);
  });

  testWidgets('grid density changes card width', (tester) async {
    final container = ProviderContainer(overrides: [await prefsOverride()]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PokemonGrid(
              items: [PokemonSummary(id: 1, name: 'bulbasaur')],
            ),
          ),
        ),
      ),
    );

    double maxExtent() => (tester
            .widget<SliverGrid>(find.byType(SliverGrid))
            .gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent)
        .maxCrossAxisExtent;

    expect(maxExtent(), 180);

    await container
        .read(settingsProvider.notifier)
        .setGridDensity(GridDensity.compact);
    await tester.pump();
    expect(maxExtent(), 130);
  });

  testWidgets('animations off removes image fade', (tester) async {
    final container = ProviderContainer(overrides: [await prefsOverride()]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PokemonGrid(
              items: [PokemonSummary(id: 1, name: 'bulbasaur')],
            ),
          ),
        ),
      ),
    );

    Duration fade() =>
        tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .fadeInDuration;
    expect(fade(), isNot(Duration.zero));

    await container.read(settingsProvider.notifier).setAnimationsEnabled(false);
    await tester.pump();
    expect(fade(), Duration.zero);
  });
}
