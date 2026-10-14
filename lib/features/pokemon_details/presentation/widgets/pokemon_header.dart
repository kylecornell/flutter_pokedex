import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon.dart';
import '../../../../shared/widgets/pokemon_artwork.dart';
import '../../../../shared/widgets/type_badge.dart';

/// Artwork on a type-tinted background, name, number, types, size.
class PokemonHeader extends StatelessWidget {
  const PokemonHeader({super.key, required this.pokemon});

  final Pokemon pokemon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = pokemon.types.isEmpty
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : typeColor(pokemon.types.first).withValues(alpha: 0.25);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: PokemonArtwork(url: pokemon.artworkUrl, size: 240),
        ),
        const SizedBox(height: 12),
        Text(formatDexNumber(pokemon.id), style: textTheme.labelLarge),
        Text(formatPokemonName(pokemon.name), style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            // Tapping a type opens the Type Explorer for it.
            for (final t in pokemon.types)
              TypeBadge(type: t, onTap: () => context.push('/types/$t')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Measure(label: 'Height', value: '${pokemon.heightMeters} m'),
            const SizedBox(width: 32),
            _Measure(label: 'Weight', value: '${pokemon.weightKg} kg'),
          ],
        ),
      ],
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.titleMedium),
        Text(label, style: textTheme.labelMedium),
      ],
    );
  }
}
