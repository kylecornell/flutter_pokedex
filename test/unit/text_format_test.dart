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
    expect(formatStatName('special-attack'), 'Sp. Atk');
    expect(formatStatName('special-defense'), 'Sp. Def');
    expect(formatStatName('speed'), 'Speed');
  });

  test('formatCount', () {
    expect(formatCount(7), '7');
    expect(formatCount(1025), '1,025');
    expect(formatCount(1234567), '1,234,567');
  });
}
