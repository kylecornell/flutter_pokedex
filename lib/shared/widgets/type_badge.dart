import 'package:flutter/material.dart';

import '../../core/utils/text_format.dart';

const _typeColors = <String, Color>{
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFEE8130),
  'water': Color(0xFF6390F0),
  'electric': Color(0xFFF7D02C),
  'grass': Color(0xFF7AC74C),
  'ice': Color(0xFF96D9D6),
  'fighting': Color(0xFFC22E28),
  'poison': Color(0xFFA33EA1),
  'ground': Color(0xFFE2BF65),
  'flying': Color(0xFFA98FF3),
  'psychic': Color(0xFFF95587),
  'bug': Color(0xFFA6B91A),
  'rock': Color(0xFFB6A136),
  'ghost': Color(0xFF735797),
  'dragon': Color(0xFF6F35FC),
  'dark': Color(0xFF705746),
  'steel': Color(0xFFB7B7CE),
  'fairy': Color(0xFFD685AD),
};

/// Brand color of a Pokémon type; grey for unknown types.
Color typeColor(String type) => _typeColors[type] ?? const Color(0xFF9E9E9E);

/// Colored pill with the type name. Pass [onTap] to make it tappable.
class TypeBadge extends StatelessWidget {
  const TypeBadge({super.key, required this.type, this.onTap});

  final String type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: typeColor(type),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            formatPokemonName(type),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 2, color: Colors.black38)],
            ),
          ),
        ),
      ),
    );
  }
}
