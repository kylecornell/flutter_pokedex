import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/widgets/pokemon_artwork.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({super.key, required this.pokemon, this.onTap});

  final PokemonSummary pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(child: PokemonArtwork(url: pokemon.artworkUrl)),
              const SizedBox(height: 4),
              Text(formatDexNumber(pokemon.id), style: textTheme.labelMedium),
              Text(
                formatPokemonName(pokemon.name),
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
