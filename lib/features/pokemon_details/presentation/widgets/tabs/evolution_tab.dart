import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/text_format.dart';
import '../../../../../shared/models/evolution_chain.dart';
import '../../../../../shared/widgets/pokemon_artwork.dart';
import '../../providers/pokemon_detail_provider.dart';

/// Evolution family: one column per stage, arrows between stages.
class EvolutionTab extends ConsumerWidget {
  const EvolutionTab({
    super.key,
    required this.speciesName,
    required this.currentId,
    required this.highlight,
  });

  final String speciesName;
  final int currentId;
  final Color highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final chain = ref.watch(evolutionChainProvider(speciesName));

    return chain.when(
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
      ),
      error: (e, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(evolutionChainProvider(speciesName)),
          child: const Text('Could not load evolutions. Tap to retry.'),
        ),
      ),
      data: (chain) {
        final stages = chain?.nodeStages ?? const <List<EvolutionNode>>[];
        if (stages.length < 2) {
          return Text(
            'This Pokémon does not evolve.',
            style: TextStyle(fontSize: 14, color: p.mutedForeground),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final (i, stage) in stages.indexed) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: p.mutedForeground,
                        ),
                      ),
                    Column(
                      children: [
                        for (final node in stage)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _EvolutionNodeTile(
                              node: node,
                              isCurrent: node.species.id == currentId,
                              highlight: highlight,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a stage to open it.',
              style: TextStyle(fontSize: 12, color: p.mutedForeground),
            ),
          ],
        );
      },
    );
  }
}

class _EvolutionNodeTile extends StatelessWidget {
  const _EvolutionNodeTile({
    required this.node,
    required this.isCurrent,
    required this.highlight,
  });

  final EvolutionNode node;
  final bool isCurrent;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final species = node.species;
    return Semantics(
      button: !isCurrent,
      label: formatPokemonName(species.name),
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isCurrent ? highlight : p.border,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isCurrent
              ? null
              : () => context.pushReplacement('/pokemon/${species.id}'),
          child: SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
              child: Column(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: PokemonArtwork(url: species.artworkUrl),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatPokemonName(species.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    formatDexNumber(species.id),
                    style: monoStyle(
                      10.5,
                      weight: FontWeight.w500,
                      color: p.mutedForeground,
                    ),
                  ),
                  if (node.requirement.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: p.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        node.requirement,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: p.accentForeground,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
