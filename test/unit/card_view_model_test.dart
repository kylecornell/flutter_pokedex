import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/pokemon_details/domain/card_view_model.dart';
import 'package:pokedex_app/shared/models/pokemon.dart';
import 'package:pokedex_app/shared/models/pokemon_species.dart';

import '../helpers/fake_api.dart';

CardViewModel build(
  int id, {
  PokemonForm? form,
  Map<String, dynamic>? speciesOverride,
}) {
  final species = PokemonSpecies.fromJson({
    ...speciesJson(id),
    ...?speciesOverride,
  });
  return CardViewModel.build(
    pokemonId: id,
    pokemon: Pokemon.fromJson(pokemonJson(id)),
    species: species,
    form: form,
  );
}

void main() {
  test('plain Pokémon: facts, number, HP, no ribbon', () {
    final card = build(4);
    expect(card.name, 'Charmander');
    expect(card.number, '#0004');
    expect(card.hp, '44');
    expect(card.types, ['fire']);
    expect(card.primaryType, 'fire');
    expect(card.secondaryType, 'fire'); // single type repeats for gradients
    expect(card.height, '1.4 m');
    expect(card.weight, '10.4 kg');
    expect(card.baseExp, '64');
    expect(card.generationLabel, 'Gen I');
    expect(card.region, 'Kanto');
    expect(card.abilityLine, 'Ability · Overgrow');
    expect(card.stats, [('HP', 44), ('Attack', 54), ('Sp. Atk', 64)]);
    expect(card.ribbon, isEmpty);
    expect(card.foil, CardFoil.gold);
    expect(card.isSpecial, isFalse);

    final facts = {for (final (k, v) in card.facts) k: v};
    expect(facts['Abilities'], 'Overgrow');
    expect(facts['Hidden ability'], 'Chlorophyll');
    expect(facts['Generation'], 'Gen I · Kanto');
    expect(facts['Types'], 'Fire');

    final back = {for (final (k, v) in card.backFacts) k: v};
    expect(back['Habitat'], 'Grassland');
    expect(back['Capture rate'], '45');
    expect(back['Class'], 'Standard');
  });

  test('dual type uses both colors', () {
    final card = build(6);
    expect(card.types, ['fire', 'flying']);
    expect(card.color1, isNot(card.color2));
  });

  test('legendary and mythical get a ribbon and special foil', () {
    final legendary = build(4, speciesOverride: {'is_legendary': true});
    expect(legendary.ribbon, 'Legendary');
    expect(legendary.foil, CardFoil.legendary);
    expect(legendary.isSpecial, isTrue);

    final mythical = build(4, speciesOverride: {'is_mythical': true});
    expect(mythical.ribbon, 'Mythical');
    expect(mythical.foil, CardFoil.mythical);
  });

  test('mega, gmax and regional forms rename the card', () {
    PokemonForm form(String api) => PokemonForm.fromVariety(
          apiName: api,
          speciesName: 'charizard',
          id: 10034,
          isDefault: false,
        );

    final mega = build(6, form: form('charizard-mega-x'));
    expect(mega.name, 'Mega Charizard X');
    expect(mega.ribbon, 'Mega Evolution');
    expect(mega.foil, CardFoil.mega);

    final gmax = build(6, form: form('charizard-gmax'));
    expect(gmax.name, 'G-Max Charizard');
    expect(gmax.foil, CardFoil.gmax);

    final alola = build(6, form: form('charizard-alola'));
    expect(alola.name, 'Alolan Charizard');
    expect(alola.ribbon, 'Alolan form');

    final other = build(6, form: form('charizard-cosplay'));
    expect(other.name, 'Charizard (Cosplay)');
  });

  test('missing data shows dashes, not made-up values', () {
    final species = PokemonSpecies.fromJson({'name': 'unknownmon'});
    final card = CardViewModel.build(
      pokemonId: 999,
      pokemon: Pokemon.fromJson({'id': 999}),
      species: species,
    );
    expect(card.hp, '—');
    expect(card.baseExp, '—');
    expect(card.abilityLine, isEmpty);
    expect(card.primaryType, 'normal');
    final back = {for (final (k, v) in card.backFacts) k: v};
    expect(back['Habitat'], 'Unknown');
    expect(back['Capture rate'], '—');
  });
}
