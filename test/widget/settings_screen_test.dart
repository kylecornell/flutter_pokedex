import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/app/theme/app_theme.dart';
import 'package:pokedex_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:pokedex_app/shared/models/app_settings.dart';
import 'package:pokedex_app/shared/models/pokemon_summary.dart';
import 'package:pokedex_app/shared/providers/settings_provider.dart';
import 'package:pokedex_app/shared/providers/type_providers.dart';
import 'package:pokedex_app/shared/widgets/pokemon_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

ThemeData _realTheme() => AppTheme.light(animations: false);

Future<(Widget, ProviderContainer)> _themedSettings({
  Map<String, Object> prefs = const {},
  FakePokeApi? api,
}) async {
  final container = ProviderContainer(
    overrides: await overridesFor(api ?? FakePokeApi(), prefs: prefs),
  );
  addTearDown(container.dispose);
  return (
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _realTheme(),
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
    container,
  );
}

void main() {
  testWidgets('segments and switches change and persist settings',
      (tester) async {
    final (app, container) = await _themedSettings();
    await tester.pumpWidget(app);
    await settle(tester);

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

    await tester.tap(find.text('Small'));
    await tester.pump();
    expect(container.read(settingsProvider).gridDensity, GridDensity.compact);

    await tester.tap(find.text('3D'));
    await tester.pump();
    expect(container.read(settingsProvider).viewerMode, ViewerMode.model3d);

    // Animations starts off in tests; Card effects starts on.
    final switches = find.byType(Switch);
    expect(tester.widget<Switch>(switches.at(0)).value, isFalse);
    expect(tester.widget<Switch>(switches.at(1)).value, isTrue);
    await tester.tap(switches.at(0));
    await tester.tap(switches.at(1));
    await tester.pump();
    expect(container.read(settingsProvider).animationsEnabled, isTrue);
    expect(container.read(settingsProvider).cardEffects, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings_theme_mode'), 'dark');
    expect(prefs.getString('settings_grid_density'), 'compact');
    expect(prefs.getString('settings_viewer_mode'), 'model3d');
    expect(prefs.getBool('settings_card_effects'), isFalse);
  });

  testWidgets('shows saved values', (tester) async {
    final (app, _) = await _themedSettings(
      prefs: {'settings_viewer_mode': 'animated', 'settings_card_effects': false},
    );
    await tester.pumpWidget(app);
    await settle(tester);

    expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);
    expect(find.text('Animated'), findsOneWidget);
  });

  testWidgets('cached data: shows index size and clears it', (tester) async {
    final api = FakePokeApi();
    final (app, container) = await _themedSettings(api: api);
    await tester.pumpWidget(app);
    await container.read(typeIndexProvider.future);
    await settle(tester);

    expect(find.text('Type index for 6 Pokémon.'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(typeIndexPrefsKey), isNotNull);

    await tester.ensureVisible(find.text('Clear'));
    await tester.pump();
    await tester.tap(find.text('Clear'));
    await settle(tester);

    expect(find.text('Cached data cleared'), findsOneWidget);
    // The index is rebuilt right away because this screen shows its size.
    final rebuilt = await container.read(typeIndexProvider.future);
    expect(rebuilt, hasLength(6));
  });

  testWidgets('about section credits PokéAPI and the fan-model caveat',
      (tester) async {
    final (app, _) = await _themedSettings();
    await tester.pumpWidget(app);
    await settle(tester);

    await tester.scrollUntilVisible(find.textContaining('Unofficial fan project'), 200);
    expect(find.textContaining('PokéAPI'), findsOneWidget);
    expect(find.textContaining('non-commercial'), findsOneWidget);
    expect(find.textContaining('Unofficial fan project'), findsOneWidget);
  });

  testWidgets('grid density changes card width', (tester) async {
    final container = ProviderContainer(
      overrides: await overridesFor(FakePokeApi()),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: _realTheme(),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPokemonGrid(
                  items: const [PokemonSummary(id: 1, name: 'bulbasaur')],
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);

    double maxExtent() => (tester
            .widget<SliverGrid>(find.byType(SliverGrid))
            .gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent)
        .maxCrossAxisExtent;

    expect(maxExtent(), GridDensity.comfortable.maxCardWidth);
    await container
        .read(settingsProvider.notifier)
        .setGridDensity(GridDensity.compact);
    await tester.pump();
    expect(maxExtent(), GridDensity.compact.maxCardWidth);
  });

  testWidgets('animations off removes the image fade', (tester) async {
    final container = ProviderContainer(
      overrides: await overridesFor(
        FakePokeApi(),
        prefs: {'settings_animations': true},
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: _realTheme(),
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPokemonGrid(
                  items: const [PokemonSummary(id: 1, name: 'bulbasaur')],
                  onTap: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    Duration fade() => tester
        .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .fadeInDuration;
    expect(fade(), isNot(Duration.zero));

    await container.read(settingsProvider.notifier).setAnimationsEnabled(false);
    await tester.pump();
    expect(fade(), Duration.zero);
  });
}
