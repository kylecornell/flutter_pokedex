import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Pokémon image with disk + memory cache, spinner and error fallback.
class PokemonArtwork extends ConsumerWidget {
  const PokemonArtwork({super.key, required this.url, this.size});

  final String url;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animate =
        ref.watch(settingsProvider.select((s) => s.animationsEnabled));
    final fade = animate ? const Duration(milliseconds: 300) : Duration.zero;

    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fadeInDuration: fade,
      fadeOutDuration: fade,
      placeholder: (context, _) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, _, _) =>
          const Center(child: Icon(Icons.catching_pokemon, size: 40)),
    );
  }
}
