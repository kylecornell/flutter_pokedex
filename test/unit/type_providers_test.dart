import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pokedex_app/core/errors/app_exception.dart';
import 'package:pokedex_app/core/network/api_client.dart';
import 'package:pokedex_app/features/pokedex/presentation/providers/pokedex_search_provider.dart';
import 'package:pokedex_app/features/type_explorer/presentation/providers/matchup_provider.dart';
import 'package:pokedex_app/shared/datasources/pokeapi_datasource.dart';
import 'package:pokedex_app/shared/providers/pokemon_providers.dart';
import 'package:pokedex_app/shared/repositories/type_repository.dart';

String fixtureText(String name) =>
    File('test/fixtures/$name').readAsStringSync();

TypeRepository repoWith(
  Future<http.Response> Function(http.Request) handler,
) =>
    TypeRepository(PokeApiDataSource(ApiClient(client: MockClient(handler))));

Future<http.Response> byType(http.Request req) async {
  return switch (req.url.path) {
    '/api/v2/type/fire' => http.Response(fixtureText('type_fire.json'), 200),
    '/api/v2/type/ghost' => http.Response(fixtureText('type_ghost.json'), 200),
    _ => http.Response('', 404),
  };
}

ProviderContainer container(TypeRepository repo) {
  final c = ProviderContainer(
    overrides: [typeRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TypeRepository', () {
    test('caches by name', () async {
      var calls = 0;
      final repo = repoWith((req) {
        calls++;
        return byType(req);
      });
      final a = await repo.getType('Fire');
      final b = await repo.getType('fire');
      expect(b, same(a));
      expect(calls, 1);
    });

    test('404 -> NotFoundException, bad shape -> ParsingException', () {
      expect(repoWith(byType).getType('zzz'), throwsA(isA<NotFoundException>()));
      final bad = repoWith(
        (_) async => http.Response('{"damage_relations": 5}', 200),
      );
      expect(bad.getType('fire'), throwsA(isA<ParsingException>()));
    });
  });

  group('MatchupSelectionNotifier', () {
    test('toggles attacker', () {
      final c = container(repoWith(byType));
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleAttacker('fire');
      expect(c.read(matchupSelectionProvider).attacker, 'fire');
      n.toggleAttacker('fire');
      expect(c.read(matchupSelectionProvider).attacker, isNull);
    });

    test('keeps max two defenders, dropping the oldest', () {
      final c = container(repoWith(byType));
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleDefender('fire');
      n.toggleDefender('ghost');
      n.toggleDefender('water');
      expect(c.read(matchupSelectionProvider).defenders, ['ghost', 'water']);
      n.toggleDefender('water');
      expect(c.read(matchupSelectionProvider).defenders, ['ghost']);
    });

    test('result is null without defenders', () async {
      final c = container(repoWith(byType));
      expect(await c.read(matchupResultProvider.future), isNull);
    });

    test('result combines attack multiplier and defense chart', () async {
      final c = container(repoWith(byType));
      final n = c.read(matchupSelectionProvider.notifier);
      n.toggleAttacker('ghost');
      n.toggleDefender('ghost');
      n.toggleDefender('fire');

      final result = (await c.read(matchupResultProvider.future))!;
      expect(result.attackMultiplier, 2); // ghost->ghost 2 * ghost->fire 1
      expect(result.defenseChart['water'], 2 * 1);
      expect(result.defenseChart['normal'], 0); // ghost immune
    });
  });

  test('pokemonOfTypeProvider drops forms and sorts by id', () async {
    final c = container(repoWith(byType));
    final list = await c.read(pokemonOfTypeProvider('fire').future);
    expect(list.map((p) => p.id), [4, 6]);
  });
}
