import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/core/utils/text_format.dart';

void main() {
  test('formatPokemonName', () {
    expect(formatPokemonName('pikachu'), 'Pikachu');
    expect(formatPokemonName('mr-mime'), 'Mr Mime');
  });

  test('formatDexNumber', () {
    expect(formatDexNumber(25), '#0025');
    expect(formatDexNumber(1025), '#1025');
  });

  test('formatStatName', () {
    expect(formatStatName('hp'), 'HP');
    expect(formatStatName('special-attack'), 'Special Attack');
  });
}
