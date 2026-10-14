import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pokedex_app/app/app.dart';

void main() {
  testWidgets('App boots to the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokedexApp()));
    await tester.pumpAndSettle();

    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Welcome, Trainer!'), findsOneWidget);
  });
}
