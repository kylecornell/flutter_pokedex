import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/evolution_chain.dart';
import '../../../../shared/models/pokemon.dart';
import '../../../../shared/providers/pokemon_providers.dart';

/// Full data for one Pokémon. Argument is a Pokédex number or name.
final pokemonDetailProvider = FutureProvider.family<Pokemon, String>(
  (ref, idOrName) =>
      ref.watch(pokemonRepositoryProvider).getPokemon(idOrName),
  retry: (_, _) => null,
);

/// Evolution family, keyed by species name. Loaded separately so a failure
/// here never blocks the rest of the details page.
final evolutionChainProvider = FutureProvider.family<EvolutionChain?, String>(
  (ref, speciesName) =>
      ref.watch(pokemonRepositoryProvider).getEvolutionChain(speciesName),
  retry: (_, _) => null,
);

/// Short effect text of an ability (`overgrow`).
final abilityDescriptionProvider = FutureProvider.family<String, String>(
  (ref, name) =>
      ref.watch(pokemonRepositoryProvider).getAbilityDescription(name),
  retry: (_, _) => null,
);
