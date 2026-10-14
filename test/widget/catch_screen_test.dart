import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/features/catch/presentation/screens/catch_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

/// Deterministic randomness: always picks index 0 and rolls [roll].
class _FixedRandom implements Random {
  _FixedRandom(this.roll);

  final double roll;

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => roll;
  @override
  int nextInt(int max) => 0;
}

Future<Widget> catchApp(
  FakePokeApi api, {
  Random? random,
  Map<String, Object> prefs = const {},
}) async {
  return testRouterApp(
    [
      GoRoute(
        path: '/',
        builder: (_, _) => CatchScreen(
          random: random,
          // Camera plugin is absent in tests: fail over to the field fast
          // and leave no pending timer behind.
          cameraTimeout: const Duration(milliseconds: 1),
        ),
      ),
      GoRoute(
        path: '/pokemon/:id',
        builder: (_, s) =>
            Scaffold(body: Text('details ${s.pathParameters['id']}')),
      ),
    ],
    overrides: await overridesFor(api, prefs: prefs),
  );
}

void main() {
  testWidgets('starts an encounter with a name tag and practice field',
      (tester) async {
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    // No camera plugin in tests: start-up times out -> practice field.
    expect(find.text('Practice field'), findsOneWidget);
    expect(
      find.text('Camera unavailable. Showing practice field.'),
      findsOneWidget,
    );
    // _FixedRandom(0) picks the first index entry.
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('0 caught'), findsOneWidget);
    expect(find.text('Flick the Poké Ball up at Bulbasaur'), findsOneWidget);
  });

  testWidgets('ball selection and Master Ball count', (tester) async {
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    expect(find.text('1'), findsOneWidget); // one Master Ball to start with
    await tester.tap(find.bySemanticsLabel('Ultra Ball'));
    await tester.pump();
    expect(find.text('Flick the Ultra Ball up at Bulbasaur'), findsOneWidget);
  });

  testWidgets('no Master Ball left shows a message', (tester) async {
    await tester.pumpWidget(
      await catchApp(
        FakePokeApi(),
        random: _FixedRandom(0),
        prefs: {'catch_master_balls': 0},
      ),
    );
    await settle(tester, rounds: 20);

    await tester.tap(find.bySemanticsLabel(RegExp('^Master Ball')));
    await tester.pump();
    expect(find.text('No Master Ball left'), findsOneWidget);
    // The hint comes back once the message fades.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Flick the Poké Ball up at Bulbasaur'), findsOneWidget);
  });

  testWidgets('a short flick falls short and the ball resets', (tester) async {
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    final ball = find.bySemanticsLabel(RegExp('Poké Ball. Flick up'));
    await tester.fling(ball, const Offset(0, -60), 700);
    await pumpUntilFound(tester, find.text('Too short'));

    expect(find.text('Too short'), findsOneWidget);
    // Back to idle: hint visible once the message clears.
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Flick the'), findsOneWidget);
  });

  testWidgets('a good throw catches, saves the catch and favorites it',
      (tester) async {
    // Roll 0 always beats the catch chance.
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    final ball = find.bySemanticsLabel(RegExp('Poké Ball. Flick up'));
    await tester.fling(ball, const Offset(0, -200), 1400);
    await pumpUntilFound(tester, find.text('GOTCHA!'), maxSteps: 400);

    expect(find.text('GOTCHA!'), findsOneWidget);
    expect(find.text('Added to your collection.'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('catch_caught_ids'), ['1']);
    expect(prefs.getStringList('favorite_pokemon_ids'), ['1']);

    await tester.tap(find.text('View details'));
    await settle(tester);
    expect(find.text('details 1'), findsOneWidget);
  });

  testWidgets('a good throw can fail: the Pokémon breaks free',
      (tester) async {
    // Roll 0.99 is above the 0.97 cap: never caught.
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0.99)));
    await settle(tester, rounds: 20);

    final ball = find.bySemanticsLabel(RegExp('Poké Ball. Flick up'));
    await tester.fling(ball, const Offset(0, -200), 1400);
    await pumpUntilFound(tester, find.text('It broke free!'), maxSteps: 400);

    expect(find.text('It broke free!'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('catch_caught_ids'), isNull);

    // Let the game's own delays finish so no timer outlives the test.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a slow drag springs back without throwing', (tester) async {
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    final ball = find.bySemanticsLabel(RegExp('Poké Ball. Flick up'));
    await tester.drag(ball, const Offset(30, -40));
    await settle(tester, rounds: 20);
    expect(find.textContaining('Flick the'), findsOneWidget);
  });

  testWidgets('new encounter button restarts', (tester) async {
    await tester.pumpWidget(await catchApp(FakePokeApi(), random: _FixedRandom(0)));
    await settle(tester, rounds: 20);

    await tester.tap(find.byTooltip('New encounter'));
    await settle(tester, rounds: 20);
    expect(find.textContaining('Flick the'), findsOneWidget);
  });

  testWidgets('works offline with a generic name', (tester) async {
    await tester.pumpWidget(
      await catchApp(FakePokeApi(failEverything: true), random: _FixedRandom(0)),
    );
    await settle(tester, rounds: 20);
    expect(find.text('Wild Pokémon'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
