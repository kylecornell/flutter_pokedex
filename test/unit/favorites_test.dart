import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/shared/datasources/favorites_local_datasource.dart';
import 'package:pokedex_app/shared/providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/prefs.dart';

void main() {
  group('FavoritesLocalDataSource', () {
    test('round-trips ids in order', () async {
      SharedPreferences.setMockInitialValues({});
      final ds = FavoritesLocalDataSource(await SharedPreferences.getInstance());
      expect(ds.load(), isEmpty);

      await ds.save([25, 1, 150]);
      expect(ds.load(), [25, 1, 150]);
    });

    test('skips corrupt entries', () async {
      SharedPreferences.setMockInitialValues({
        'favorite_pokemon_ids': ['25', 'oops', '', '7'],
      });
      final ds = FavoritesLocalDataSource(await SharedPreferences.getInstance());
      expect(ds.load(), [25, 7]);
    });
  });

  group('FavoritesNotifier', () {
    test('starts from stored ids', () async {
      final c = ProviderContainer(overrides: [
        await prefsOverride({
          'favorite_pokemon_ids': ['4', '25'],
        }),
      ]);
      addTearDown(c.dispose);
      expect(c.read(favoritesProvider), [4, 25]);
    });

    test('toggle adds newest first, removes, and persists', () async {
      final c = ProviderContainer(overrides: [await prefsOverride()]);
      addTearDown(c.dispose);
      final notifier = c.read(favoritesProvider.notifier);

      await notifier.toggle(4);
      await notifier.toggle(25);
      expect(c.read(favoritesProvider), [25, 4]);
      expect(c.read(isFavoriteProvider(25)), isTrue);
      expect(c.read(isFavoriteProvider(1)), isFalse);

      await notifier.toggle(25);
      expect(c.read(favoritesProvider), [4]);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('favorite_pokemon_ids'), ['4']);
    });
  });
}
