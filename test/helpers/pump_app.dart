import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pokedex_app/app/theme/app_theme.dart';
import 'package:pokedex_app/shared/widgets/chips.dart';

import 'fake_api.dart';

/// Preferences used by widget tests: animations off, so nothing loops or
/// waits on delayed entrances.
const testPrefs = <String, Object>{'settings_animations': false};

/// Wraps [home] with the real theme and the given provider [overrides].
Widget testApp(Widget home, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: AppTheme.light(animations: false), home: home),
  );
}

/// Same, but navigable: [routes] are real `GoRoute`s.
Widget testRouterApp(
  List<RouteBase> routes, {
  required List<Override> overrides,
  String initialLocation = '/',
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.light(animations: false),
      routerConfig: GoRouter(initialLocation: initialLocation, routes: routes),
    ),
  );
}

/// Convenience: overrides for a fake API with test preferences merged in.
Future<List<Override>> overridesFor(
  FakePokeApi api, {
  Map<String, Object> prefs = const {},
}) {
  return testOverrides(api, prefs: {...testPrefs, ...prefs});
}

/// Lets async providers (HTTP mock, cache writes) finish and the UI rebuild.
/// `pumpAndSettle` is avoided because spinners animate forever.
Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

/// Scrolls the type chip row until the chip labelled [label] is built,
/// then taps it. Chip rows are lazy lists, so chips far to the right do not
/// exist until scrolled to.
Future<void> tapChip(WidgetTester tester, String label) async {
  final scrollable = find
      .descendant(
        of: find.byType(TypeChipRow).first,
        matching: find.byType(Scrollable),
      )
      .first;
  final chip = find.widgetWithText(PillChip, label);
  // Start from the left edge so scrolling right always finds the chip.
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(chip, 120, scrollable: scrollable);
  await tester.ensureVisible(chip); // fully on screen, not under the fade
  await tester.pump();
  await tester.tap(chip);
  await settle(tester);
}

/// Makes the test screen tall so lazily built lists show everything at once.
void useTallScreen(WidgetTester tester, {double height = 3200}) {
  tester.view.physicalSize = Size(800, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps in small steps until [finder] matches (or [maxSteps] is reached).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxSteps = 80,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < maxSteps && finder.evaluate().isEmpty; i++) {
    await tester.pump(step);
  }
}
