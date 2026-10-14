import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../providers/pokemon_detail_provider.dart';
import '../widgets/base_stats_card.dart';
import '../widgets/evolution_chain_section.dart';
import '../widgets/pokemon_header.dart';

/// Arranges the details page. [pokemonId] is a Pokédex number from the route.
class PokemonDetailScreen extends ConsumerWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  final String pokemonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(pokemonDetailProvider(pokemonId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail.maybeWhen(
            data: (p) => formatPokemonName(p.name),
            orElse: () => 'Pokémon',
          ),
        ),
        actions: [
          if (detail.value case final pokemon?)
            FavoriteButton(pokemonId: pokemon.id),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(pokemonDetailProvider(pokemonId)),
        ),
        data: (pokemon) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PokemonHeader(pokemon: pokemon),
            const SizedBox(height: 16),
            BaseStatsCard(stats: pokemon.stats),
            const SizedBox(height: 16),
            EvolutionChainSection(
              speciesName: pokemon.speciesName,
              currentId: pokemon.id,
            ),
          ],
        ),
      ),
    );
  }
}
