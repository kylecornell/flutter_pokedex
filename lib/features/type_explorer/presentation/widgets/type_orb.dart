import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/widgets/type_badge.dart';

/// Round, type-colored button used in the Type Explorer grid.
class TypeOrb extends StatelessWidget {
  const TypeOrb({super.key, required this.type, required this.onTap});

  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(type);
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Color.lerp(color, Colors.white, 0.45)!, color],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          formatPokemonName(type),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
          ),
        ),
      ),
    );
  }
}
