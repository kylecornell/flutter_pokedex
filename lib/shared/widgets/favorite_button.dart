import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../providers/favorites_provider.dart';

/// Heart toggle for one Pokémon, with a small pop when it is added.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.pokemonId,
    this.compact = false,
    this.inactiveColor,
  });

  final int pokemonId;

  /// Smaller hit area for use inside cards.
  final bool compact;

  /// Heart color when not a favorite (defaults to the muted palette color).
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(pokemonId));
    final p = context.palette;
    const red = Color(0xFFEF4444);

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      visualDensity: compact ? VisualDensity.compact : null,
      constraints: compact
          ? const BoxConstraints.tightFor(width: 36, height: 36)
          : null,
      padding: compact ? EdgeInsets.zero : null,
      icon: AnimatedScale(
        scale: isFavorite ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: compact ? 20 : 24,
          color: isFavorite ? red : (inactiveColor ?? p.mutedForeground),
        ),
      ),
      onPressed: () => ref.read(favoritesProvider.notifier).toggle(pokemonId),
    );
  }
}
