import 'package:flutter/material.dart';

import '../../core/utils/text_format.dart';
import 'type_icon.dart';

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

/// Types whose color is dark enough to need white text.
const _lightInkTypes = {'fighting', 'poison', 'ghost', 'dragon', 'dark'};

/// Brand color of a Pokémon type; grey for unknown types.
Color typeColor(String type) => _typeColors[type] ?? const Color(0xFF9E9E9E);

/// Readable text/icon color on top of [typeColor].
Color typeInk(String type) =>
    _lightInkTypes.contains(type) ? Colors.white : const Color(0xFF18181B);

/// Colored pill with the type name. Pass [onTap] to make it tappable and
/// [showIcon] to prefix the type icon.
class TypeBadge extends StatelessWidget {
  const TypeBadge({
    super.key,
    required this.type,
    this.onTap,
    this.showIcon = false,
  });

  final String type;
  final VoidCallback? onTap;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final ink = typeInk(type);
    return Semantics(
      button: onTap != null,
      label: '${formatPokemonName(type)} type',
      child: Material(
        color: typeColor(type),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Icon(typeIconData(type), size: 13, color: ink),
                  const SizedBox(width: 4),
                ],
                Text(
                  formatPokemonName(type),
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
