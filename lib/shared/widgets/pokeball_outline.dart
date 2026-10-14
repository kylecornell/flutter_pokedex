import 'package:flutter/material.dart';

/// Faint Pokéball line art used as a card/header decoration.
class PokeballOutline extends StatelessWidget {
  const PokeballOutline({
    super.key,
    required this.size,
    required this.color,
    this.strokeWidth = 1.4,
  });

  final double size;
  final Color color;

  /// Stroke width in the 24-unit design grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PokeballPainter(color, strokeWidth),
    );
  }
}

class _PokeballPainter extends CustomPainter {
  _PokeballPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * unit
      ..strokeCap = StrokeCap.round;
    final c = Offset(12 * unit, 12 * unit);
    canvas.drawCircle(c, 10 * unit, paint);
    canvas.drawCircle(c, 3 * unit, paint);
    canvas.drawLine(Offset(2 * unit, 12 * unit), Offset(9 * unit, 12 * unit), paint);
    canvas.drawLine(Offset(15 * unit, 12 * unit), Offset(22 * unit, 12 * unit), paint);
  }

  @override
  bool shouldRepaint(_PokeballPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
