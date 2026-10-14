import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/catch/presentation/providers/catch_provider.dart';
import 'package:pokedex_app/shared/providers/recent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/prefs.dart';

void main() {
  group('catchProvider', () {
    test('starts with one Master Ball and nothing caught', () async {
      final c = ProviderContainer(overrides: [await prefsOverride()]);
      addTearDown(c.dispose);
      final state = c.read(catchProvider);
      expect(state.caught, isEmpty);
      expect(state.masterBalls, 1);
    });

    test('records catches and spends Master Balls, persisted', () async {
      final c = ProviderContainer(overrides: [await prefsOverride()]);
      addTearDown(c.dispose);
      final n = c.read(catchProvider.notifier);

      await n.recordCatch(25);
      await n.recordCatch(25);
      await n.recordCatch(4);
      await n.useMasterBall();
      await n.useMasterBall(); // never below zero

      final state = c.read(catchProvider);
      expect(state.caught, {25, 4});
      expect(state.masterBalls, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('catch_master_balls'), 0);
      expect(prefs.getStringList('catch_caught_ids'), ['25', '4']);
    });

    test('loads saved state', () async {
      final c = ProviderContainer(
        overrides: [
          await prefsOverride({
            'catch_caught_ids': ['1', 'bad', '7'],
            'catch_master_balls': 3,
          }),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(catchProvider).caught, {1, 7});
      expect(c.read(catchProvider).masterBalls, 3);
    });
  });

  group('recentProvider', () {
    test('newest first, no duplicates, max ten, persisted', () async {
      final c = ProviderContainer(overrides: [await prefsOverride()]);
      addTearDown(c.dispose);
      final n = c.read(recentProvider.notifier);

      for (final id in [1, 2, 3, 2]) {
        await n.add(id);
      }
      expect(c.read(recentProvider), [2, 3, 1]);

      for (var id = 10; id < 22; id++) {
        await n.add(id);
      }
      expect(c.read(recentProvider), hasLength(10));
      expect(c.read(recentProvider).first, 21);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('recent_pokemon_ids')!.first, '21');
    });
  });
}
