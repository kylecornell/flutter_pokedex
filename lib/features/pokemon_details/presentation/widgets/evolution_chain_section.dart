import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/widgets/pokemon_artwork.dart';
import '../providers/pokemon_detail_provider.dart';

/// Evolution family shown as rows (one per stage) joined by arrows.
class EvolutionChainSection extends ConsumerWidget {
  const EvolutionChainSection({
    super.key,
    required this.speciesName,
    required this.currentId,
  });

  final String speciesName;
  final int currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chain = ref.watch(evolutionChainProvider(speciesName));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evolution', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            chain.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(evolutionChainProvider(speciesName)),
                  child: const Text('Could not load evolutions. Tap to retry.'),
                ),
              ),
              data: (chain) {
                final stages = chain?.stages ?? const [];
                if (stages.length < 2) {
                  return const Text('This Pokémon does not evolve.');
                }
                return Column(
                  children: [
                    for (var i = 0; i < stages.length; i++) ...[
                      if (i > 0)
                        const Icon(Icons.arrow_downward, color: Colors.grey),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final p in stages[i])
                            _EvolutionTile(
                              pokemon: p,
                              isCurrent: p.id == currentId,
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolutionTile extends StatelessWidget {
  const _EvolutionTile({required this.pokemon, required this.isCurrent});

  final PokemonSummary pokemon;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      // Tapping the Pokémon already shown would just stack the same page.
      onTap: isCurrent ? null : () => context.push('/pokemon/${pokemon.id}'),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            PokemonArtwork(url: pokemon.artworkUrl, size: 72),
            Text(
              formatPokemonName(pokemon.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
