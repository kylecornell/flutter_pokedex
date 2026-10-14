import 'generation.dart';
import 'pokemon_summary.dart';

enum PokemonRarity {
  standard('Standard'),
  legendary('Legendary'),
  mythical('Mythical');

  const PokemonRarity(this.label);

  final String label;

  bool get isSpecial => this != standard;
}

enum FormKind { base, mega, gmax, regional, other }

/// One variety of a species (base form, Mega, Alolan, ...).
class PokemonForm {
  const PokemonForm({
    required this.id,
    required this.label,
    required this.kind,
    required this.isDefault,
  });

  /// Builds a form from a `varieties` entry. [apiName] is the form's Pokémon
  /// name (`charizard-mega-x`), [speciesName] the species (`charizard`).
  factory PokemonForm.fromVariety({
    required String apiName,
    required String speciesName,
    required int id,
    required bool isDefault,
  }) {
    var rest = apiName.startsWith(speciesName)
        ? apiName.substring(speciesName.length).replaceFirst(RegExp('^-'), '')
        : apiName;

    if (isDefault || rest.isEmpty) {
      return PokemonForm(
        id: id,
        label: 'Base',
        kind: FormKind.base,
        isDefault: isDefault,
      );
    }
    String nice(String s) => s
        .split('-')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');

    if (rest.startsWith('mega')) {
      return PokemonForm(
        id: id,
        label: nice(rest),
        kind: FormKind.mega,
        isDefault: isDefault,
      );
    }
    if (rest == 'gmax') {
      return PokemonForm(
        id: id,
        label: 'Gigantamax',
        kind: FormKind.gmax,
        isDefault: isDefault,
      );
    }
    const regions = {
      'alola': 'Alolan',
      'galar': 'Galarian',
      'hisui': 'Hisuian',
      'paldea': 'Paldean',
    };
    final parts = rest.split('-');
    for (final entry in regions.entries) {
      if (parts.contains(entry.key)) {
        final others = parts.where((p) => p != entry.key).join('-');
        return PokemonForm(
          id: id,
          label: entry.value + (others.isEmpty ? '' : ' ${nice(others)}'),
          kind: FormKind.regional,
          isDefault: isDefault,
        );
      }
    }
    return PokemonForm(
      id: id,
      label: nice(rest),
      kind: FormKind.other,
      isDefault: isDefault,
    );
  }

  final int id;
  final String label;
  final FormKind kind;
  final bool isDefault;
}

/// Species-level data from `GET /pokemon-species/{name}`.
class PokemonSpecies {
  const PokemonSpecies({
    required this.name,
    required this.flavorText,
    required this.genus,
    required this.generationIndex,
    required this.habitat,
    required this.captureRate,
    required this.rarity,
    required this.forms,
    required this.evolutionChainUrl,
  });

  factory PokemonSpecies.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'unknown';

    List<Map<String, dynamic>> english(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .where(
              (e) => (e['language'] as Map<String, dynamic>?)?['name'] == 'en',
            )
            .toList();

    final flavors = english('flavor_text_entries');
    final flavor = flavors.isEmpty
        ? 'No Pokédex entry available.'
        : (flavors.last['flavor_text'] as String? ?? '')
            .replaceAll(RegExp('[\n\f­\r]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    final genera = english('genera');
    final genus =
        genera.isEmpty ? 'Pokémon' : genera.first['genus'] as String? ?? 'Pokémon';

    final forms = <PokemonForm>[];
    for (final v in (json['varieties'] as List<dynamic>? ?? const [])) {
      final variety = v as Map<String, dynamic>;
      final pokemon = variety['pokemon'] as Map<String, dynamic>;
      forms.add(
        PokemonForm.fromVariety(
          apiName: pokemon['name'] as String,
          speciesName: name,
          id: idFromUrl(pokemon['url'] as String),
          isDefault: variety['is_default'] as bool? ?? false,
        ),
      );
    }

    return PokemonSpecies(
      name: name,
      flavorText: flavor.isEmpty ? 'No Pokédex entry available.' : flavor,
      genus: genus,
      generationIndex: generationIndexFromApiName(
        (json['generation'] as Map<String, dynamic>?)?['name'] as String?,
      ),
      habitat: (json['habitat'] as Map<String, dynamic>?)?['name'] as String?,
      captureRate: json['capture_rate'] as int?,
      rarity: json['is_mythical'] == true
          ? PokemonRarity.mythical
          : json['is_legendary'] == true
              ? PokemonRarity.legendary
              : PokemonRarity.standard,
      forms: forms,
      evolutionChainUrl:
          (json['evolution_chain'] as Map<String, dynamic>?)?['url'] as String?,
    );
  }

  final String name;
  final String flavorText;
  final String genus;
  final int generationIndex;
  final String? habitat;
  final int? captureRate;
  final PokemonRarity rarity;
  final List<PokemonForm> forms;
  final String? evolutionChainUrl;

  Generation get generation => pokemonGenerations[generationIndex];
}
