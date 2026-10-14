import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon_summary.dart';
import '../providers/settings_provider.dart';
import 'pokemon_card.dart';

/// Scrollable grid of [PokemonCard]s with an optional [footer]
/// (spinner / retry) shown below the last row.
class PokemonGrid extends ConsumerWidget {
  const PokemonGrid({
    super.key,
    required this.items,
    this.controller,
    this.footer,
    this.onTap,
  });

  final List<PokemonSummary> items;
  final ScrollController? controller;
  final Widget? footer;
  final void Function(PokemonSummary pokemon)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density =
        ref.watch(settingsProvider.select((s) => s.gridDensity));

    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: density.maxCardWidth,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final pokemon = items[index];
              return PokemonCard(
                pokemon: pokemon,
                onTap: onTap == null ? null : () => onTap!(pokemon),
              );
            },
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
      ],
    );
  }
}
