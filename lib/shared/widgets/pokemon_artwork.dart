import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Pokémon image with disk + memory cache, spinner and error fallback.
class PokemonArtwork extends StatelessWidget {
  const PokemonArtwork({super.key, required this.url, this.size});

  final String url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: (context, _) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, _, _) =>
          const Center(child: Icon(Icons.catching_pokemon, size: 40)),
    );
  }
}
