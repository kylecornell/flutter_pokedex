import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/app/app.dart';
import 'package:pokedex_app/shared/widgets/pokedex_header.dart';

import '../helpers/fake_api.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('each accent paints its own gradient and shows title/subtitle',
      (tester) async {
    for (final accent in HeaderAccent.values) {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: PokedexHeader(
              accent: accent,
              title: 'Title ${accent.name}',
              subtitle: 'Sub ${accent.name}',
            ),
          ),
          overrides: await overridesFor(FakePokeApi()),
        ),
      );
      await tester.pump();

      expect(find.text('Title ${accent.name}'), findsOneWidget);
      expect(find.text('Sub ${accent.name}'), findsOneWidget);

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PokedexHeader),
              matching: find.byType(Container),
            )
            .first,
      );
      final gradient = (box.decoration! as BoxDecoration).gradient!
          as LinearGradient;
      expect(gradient.colors, [accent.top, accent.bottom]);
    }
  });

  test('accent colors are distinct and yellow uses dark ink', () {
    final tops = HeaderAccent.values.map((a) => a.top).toSet();
    expect(tops, hasLength(4));
    expect(HeaderAccent.yellow.ink, isNot(Colors.white));
    expect(HeaderAccent.red.ink, Colors.white);
  });

  testWidgets('back button and actions render and fire', (tester) async {
    var backs = 0;
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: PokedexHeader(
            accent: HeaderAccent.blue,
            title: 'Details',
            onBack: () => backs++,
            actions: [
              HeaderIconButton(
                accent: HeaderAccent.blue,
                tooltip: 'Do it',
                icon: Icons.star,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
        overrides: await overridesFor(FakePokeApi()),
      ),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.tap(find.byTooltip('Do it'));
    expect(backs, 1);
    expect(taps, 1);
  });

  testWidgets('every tab header uses its own color: red, green, yellow, blue',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: await overridesFor(FakePokeApi()),
        child: const PokedexApp(),
      ),
    );
    await settle(tester);

    HeaderAccent current() =>
        tester.widget<PokedexHeader>(find.byType(PokedexHeader).first).accent;

    expect(current(), HeaderAccent.red); // Home

    await tester.tap(find.text('Pokédex').last);
    await settle(tester);
    expect(current(), HeaderAccent.green);

    await tester.tap(find.text('Favorites').last);
    await settle(tester);
    expect(current(), HeaderAccent.yellow);

    await tester.tap(find.text('Settings').last);
    await settle(tester);
    expect(current(), HeaderAccent.blue);
  });
}
