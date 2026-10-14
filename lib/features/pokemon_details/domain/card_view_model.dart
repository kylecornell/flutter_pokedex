import 'package:flutter/material.dart';

import '../../../core/utils/text_format.dart';
import '../../../shared/models/pokemon.dart';
import '../../../shared/models/pokemon_species.dart';
import '../../../shared/widgets/type_badge.dart';

/// Which special foil a card gets.
enum CardFoil { gold, silver, teal, legendary, mythical, mega, gmax }

/// Everything the trading card (front and back) and the Overview tab show,
/// computed once from API data. Pure Dart so it can be unit-tested.
class CardViewModel {
  const CardViewModel({
    required this.name,
    required this.number,
    required this.genus,
    required this.hp,
    required this.types,
    required this.primaryType,
    required this.secondaryType,
    required this.flavor,
    required this.height,
    required this.weight,
    required this.baseExp,
    required this.generationLabel,
    required this.region,
    required this.abilityLine,
    required this.ribbon,
    required this.foil,
    required this.isSpecial,
    required this.facts,
    required this.backFacts,
    required this.stats,
  });

  factory CardViewModel.build({
    required int pokemonId,
    required Pokemon pokemon,
    required PokemonSpecies species,
    PokemonForm? form,
  }) {
    final t1 = pokemon.types.isEmpty ? 'normal' : pokemon.types.first;
    final t2 = pokemon.types.length > 1 ? pokemon.types[1] : t1;
    final generation = species.generation;
    final speciesName = formatPokemonName(species.name);

    final hp = pokemon.stats
        .where((s) => s.name == 'hp')
        .map((s) => s.value.toString())
        .firstOrNull;

    final normal = [
      for (final a in pokemon.abilities)
        if (!a.isHidden) formatPokemonName(a.name),
    ];
    final hidden = [
      for (final a in pokemon.abilities)
        if (a.isHidden) formatPokemonName(a.name),
    ];

    final kind = form != null && !form.isDefault ? form.kind : null;
    final rare = species.rarity.isSpecial;

    final name = switch (kind) {
      FormKind.mega => 'Mega $speciesName${form!.label.substring(4)}',
      FormKind.gmax => 'G-Max $speciesName',
      FormKind.regional => '${form!.label.split(' ').first} $speciesName',
      FormKind.other => '$speciesName (${form!.label})',
      _ => speciesName,
    };

    String ribbon = '';
    CardFoil foil = CardFoil.gold;
    if (kind == FormKind.mega) {
      ribbon = 'Mega Evolution';
      foil = CardFoil.mega;
    } else if (kind == FormKind.gmax) {
      ribbon = 'Gigantamax';
      foil = CardFoil.gmax;
    } else if (rare) {
      ribbon = species.rarity.label;
      foil = species.rarity == PokemonRarity.mythical
          ? CardFoil.mythical
          : CardFoil.legendary;
    } else if (kind == FormKind.regional) {
      ribbon = '${form!.label.split(' ').first} form';
    } else if (kind == FormKind.other) {
      ribbon = '${form!.label} form';
    }

    final height = '${(pokemon.heightDm / 10).toStringAsFixed(1)} m';
    final weight = '${(pokemon.weightHg / 10).toStringAsFixed(1)} kg';
    final baseExp = pokemon.baseExperience?.toString() ?? '—';
    final habitat =
        species.habitat == null ? 'Unknown' : formatPokemonName(species.habitat!);

    return CardViewModel(
      name: name,
      number: formatDexNumber(pokemonId),
      genus: species.genus,
      hp: hp ?? '—',
      types: pokemon.types,
      primaryType: t1,
      secondaryType: t2,
      flavor: species.flavorText,
      height: height,
      weight: weight,
      baseExp: baseExp,
      generationLabel: generation.label,
      region: generation.region,
      abilityLine: normal.isEmpty ? '' : 'Ability · ${normal.first}',
      ribbon: ribbon,
      foil: foil,
      isSpecial: rare || kind == FormKind.mega || kind == FormKind.gmax,
      facts: [
        ('Species', species.genus),
        ('Generation', '${generation.label} · ${generation.region}'),
        ('Height', height),
        ('Weight', weight),
        ('Abilities', normal.isEmpty ? '—' : normal.join(', ')),
        ('Hidden ability', hidden.isEmpty ? 'None' : hidden.join(', ')),
        ('Base experience', baseExp),
        ('Types', pokemon.types.map(formatPokemonName).join(' / ')),
      ],
      stats: [
        for (final s in pokemon.stats) (formatStatName(s.name), s.value),
      ],
      backFacts: [
        ('Region', generation.region),
        ('Habitat', habitat),
        ('Species', species.genus),
        (
          'Capture rate',
          species.captureRate?.toString() ?? '—',
        ),
        ('Class', species.rarity.label),
        ('Generation', generation.label),
      ],
    );
  }

  final String name;
  final String number;
  final String genus;
  final String hp;
  final List<String> types;
  final String primaryType;
  final String secondaryType;
  final String flavor;
  final String height;
  final String weight;
  final String baseExp;
  final String generationLabel;
  final String region;
  final String abilityLine;

  /// Banner on top of the card (`Legendary`, `Mega Evolution`, ...), or empty.
  final String ribbon;
  final CardFoil foil;

  /// Legendary, Mythical, Mega or Gigantamax: gets texture + special foil.
  final bool isSpecial;

  /// Overview tab facts (label, value).
  final List<(String, String)> facts;

  /// Card back facts (label, value).
  final List<(String, String)> backFacts;

  /// Base stats (short label, value) shown as bars on the card back.
  final List<(String, int)> stats;

  Color get color1 => typeColor(primaryType);
  Color get color2 => typeColor(secondaryType);

  /// Text color that reads on [color1].
  Color get ink => typeInk(primaryType);
}
