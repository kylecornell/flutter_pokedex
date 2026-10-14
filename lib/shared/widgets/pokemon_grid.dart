import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon_summary.dart';
import '../providers/settings_provider.dart';
import 'pokemon_card.dart';
import 'rise_in.dart';

/// Sliver grid of [PokemonCard]s. Column count follows Settings > Grid size.
class SliverPokemonGrid extends ConsumerWidget {
  const SliverPokemonGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<PokemonSummary> items;
  final void Function(PokemonSummary pokemon) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(settingsProvider.select((s) => s.gridDensity));

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: density.maxCardWidth,
        mainAxisExtent: PokemonCard.height,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final pokemon = items[index];
        return RiseIn(
          delay: Duration(milliseconds: (index % 20) * 35),
          child: PokemonCard(pokemon: pokemon, onTap: () => onTap(pokemon)),
        );
      },
    );
  }
}
