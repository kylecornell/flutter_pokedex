import 'package:flutter/material.dart';

import '../../../../shared/models/pokemon_summary.dart';
import 'pokemon_card.dart';

/// Scrollable grid of [PokemonCard]s with an optional [footer]
/// (spinner / retry) shown below the last row.
class PokemonGrid extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
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
