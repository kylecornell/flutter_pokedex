import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';

/// Heart toggle for one Pokémon.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.pokemonId,
    this.compact = false,
  });

  final int pokemonId;

  /// Smaller hit area for use inside cards.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(pokemonId));

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      visualDensity: compact ? VisualDensity.compact : null,
      iconSize: compact ? 20 : null,
      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
      color: isFavorite ? Colors.redAccent : null,
      onPressed: () =>
          ref.read(favoritesProvider.notifier).toggle(pokemonId),
    );
  }
}
