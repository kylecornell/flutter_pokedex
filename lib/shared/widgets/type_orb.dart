import 'package:flutter/material.dart';

import 'type_badge.dart';
import 'type_icon.dart';

/// Glossy round type button from the design: radial color, highlight, icon.
///
/// Meaning is never color-only: pass a visible label next to it, and the
/// widget exposes the type name to screen readers.
class TypeOrb extends StatelessWidget {
  const TypeOrb({
    super.key,
    required this.type,
    this.size = 76,
    this.iconSize,
    this.selected = false,
  });

  final String type;
  final double size;
  final double? iconSize;

  /// Adds the double ring + glow used for the chosen type.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(type);
    final ink = typeInk(type);
    final background = Theme.of(context).scaffoldBackgroundColor;
    final light = Color.lerp(color, Colors.white, 0.5)!;
    final dark = Color.lerp(color, Colors.black, 0.3)!;

    return Semantics(
      label: '$type type',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.36, -0.44),
            radius: 1.1,
            colors: [light, color, dark],
            stops: const [0, 0.5, 1],
          ),
          boxShadow: [
            if (selected) ...[
              BoxShadow(color: background, spreadRadius: 3),
              BoxShadow(color: color, spreadRadius: 6),
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 26,
                spreadRadius: 6,
              ),
            ],
            BoxShadow(
              color: color.withValues(alpha: 0.7),
              blurRadius: 16,
              spreadRadius: -6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glossy highlight (top ellipse) and sparkle.
            Positioned(
              left: size * 0.15,
              top: size * 0.05,
              width: size * 0.7,
              height: size * 0.46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: size * 0.24,
              top: size * 0.15,
              width: size * 0.13,
              height: size * 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
            Icon(
              typeIconData(type),
              size: iconSize ?? size * 0.42,
              color: ink,
              shadows: const [Shadow(blurRadius: 2, color: Color(0x59000000))],
            ),
          ],
        ),
      ),
    );
  }
}
