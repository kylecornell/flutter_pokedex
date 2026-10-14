import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/errors/app_exception.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/type_explorer/presentation/providers/matchup_provider.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/type_providers.dart';
import 'package:pokedex_app/shared/repositories/type_repository.dart';

import '../helpers/fake_api.dart';
import '../helpers/prefs.dart';

TypeRepository repoFor(FakePokeApi api) => TypeRepository(
      PokeApiDataSource(ApiClient(client: MockClient(api.call))),
    );

Future<ProviderContainer> containerFor(
  FakePokeApi api, {
  Map<String, Object> prefs = const {},
}) async {
  final c = ProviderContainer(overrides: await testOverrides(api, prefs: prefs));
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TypeRepository', () {
    test('getType caches by name', () async {
      final api = FakePokeApi();
      final repo = repoFor(api);
      final a = await repo.getType('Fire');
      final b = await repo.getType('fire');
      expect(b, same(a));
      expect(api.callsTo('type/fire'), 1);
    });

    test('404 -> NotFoundException, bad shape -> ParsingException', () {
      final api = FakePokeApi();
      expect(repoFor(api).getType('zzz-not-a-type').then((_) {}),
          completes); // fake api answers any type name
      final notFound = TypeRepository(
        PokeApiDataSource(
          ApiClient(client: MockClient((_) async => http.Response('', 404))),
        ),
      );
      expect(notFound.getType('fire'), throwsA(isA<NotFoundException>()));

      final bad = TypeRepository(
        PokeApiDataSource(
          ApiClient(
            client: MockClient(
              (_) async => http.Response('{"damage_relations": 5}', 200),
            ),
          ),
        ),
      );
      expect(bad.getType('fire'), throwsA(isA<ParsingException>()));
    });

    test('getTypeIndex orders types by slot and drops alternate forms',
        () async {
      final api = FakePokeApi();
      final index = await repoFor(api).getTypeIndex();

      expect(index[6], ['fire', 'flying']);
      expect(index[1], ['grass', 'poison']);
      expect(index[4], ['fire']);
      expect(index.containsKey(10034), isFalse);
      expect(api.callsTo('type/'), 18);
    });
  });

  group('typeIndexProvider', () {
    test('fetches once, then reads the cache from preferences', () async {
      final api = FakePokeApi();
      final c = await containerFor(api);
      final index = await c.read(typeIndexProvider.future);
      expect(index[6], ['fire', 'flying']);
      expect(api.callsTo('type/'), 18);

      // The cache is only trusted when it looks complete (>= 900 entries).
      final prefs = await prefsOverrideValue();
      expect(prefs.getString(typeIndexPrefsKey), isNotNull);
    });

    test('uses a complete cache without any request', () async {
      final api = FakePokeApi();
      final cached = {for (var i = 1; i <= 1000; i++) '$i': ['normal']};
      final c = await containerFor(
        api,
        prefs: {typeIndexPrefsKey: jsonEncode(cached)},
      );
      final index = await c.read(typeIndexProvider.future);
      expect(index[500], ['normal']);
      expect(api.calls, isEmpty);
    });

    test('rebuilds an incomplete or corrupt cache', () async {
      final api = FakePokeApi();
      final c = await containerFor(
        api,
        prefs: {typeIndexPrefsKey: '{"1":["grass"]}'},
      );
      await c.read(typeIndexProvider.future);
      expect(api.callsTo('type/'), 18);

      final api2 = FakePokeApi();
      final c2 = await containerFor(api2, prefs: {typeIndexPrefsKey: 'not json'});
      await c2.read(typeIndexProvider.future);
      expect(api2.callsTo('type/'), 18);
    });
  });

  group('MatchupSelectionNotifier', () {
    test('toggles attacker', () async {
      final c = await containerFor(FakePokeApi());
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleAttacker('fire');
      expect(c.read(matchupSelectionProvider).attacker, 'fire');
      n.toggleAttacker('fire');
      expect(c.read(matchupSelectionProvider).attacker, isNull);
    });

    test('keeps max two defenders, dropping the oldest', () async {
      final c = await containerFor(FakePokeApi());
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleDefender('fire');
      n.toggleDefender('ghost');
      n.toggleDefender('water');
      expect(c.read(matchupSelectionProvider).defenders, ['ghost', 'water']);
      n.toggleDefender('water');
      expect(c.read(matchupSelectionProvider).defenders, ['ghost']);
    });

    test('result is null without defenders', () async {
      final c = await containerFor(FakePokeApi());
      expect(await c.read(matchupResultProvider.future), isNull);
    });

    test('result combines attack multiplier and defense chart', () async {
      final c = await containerFor(FakePokeApi());
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleAttacker('ghost');
      n.toggleDefender('ghost');
      n.toggleDefender('fire');

      final result = (await c.read(matchupResultProvider.future))!;
      expect(result.attackMultiplier, 2); // ghost->ghost 2 * ghost->fire 1
      expect(result.defenseChart['water'], 2); // fire weak to water
      expect(result.defenseChart['normal'], 0); // ghost immune to normal
    });
  });
}
