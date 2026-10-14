import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../shared/widgets/type_badge.dart';
import '../../../../shared/widgets/type_orb.dart';
import '../../domain/type_explorer_logic.dart';

/// The selected type in the middle, the other 17 around it. Each line is
/// colored by the multiplier and every orb carries a text badge, so the
/// meaning never relies on color alone.
class OrbitView extends StatelessWidget {
  const OrbitView({
    super.key,
    required this.selected,
    required this.chart,
    required this.mode,
    required this.focus,
    required this.onFocus,
    this.animations = true,
  });

  final String selected;

  /// Multiplier of each type relative to [selected].
  final Map<String, double> chart;
  final MatchupMode mode;
  final String? focus;
  final ValueChanged<String?> onFocus;
  final bool animations;

  static const double _size = 344;
  static const double _radius = 140;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final center = const Offset(_size / 2, _size / 2);
    final ring = orbitOrder(selected, chart);
    final duration =
        animations ? const Duration(milliseconds: 600) : Duration.zero;
    const curve = Cubic(0.16, 1, 0.3, 1);

    Offset position(String type) => ringPosition(
          index: ring.indexOf(type),
          count: ring.length,
          radius: _radius,
          center: center,
        );

    return Center(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.card.withValues(alpha: 0.7),
                      p.card.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.46, 0.47],
                  ),
                ),
              ),
            ),
            // Connection lines.
            Positioned.fill(
              child: CustomPaint(
                painter: _LinesPainter(
                  center: center,
                  targets: {for (final t in ring) t: position(t)},
                  colors: {
                    for (final t in ring)
                      t: relationColor(chart[t] ?? 1, mode),
                  },
                  neutral: {for (final t in ring) t: (chart[t] ?? 1) == 1},
                  focus: focus,
                  glow: typeColor(selected),
                ),
              ),
            ),
            for (final t in ring) _node(t, position(t), p, duration, curve),
            // Selected type in the middle (2.1x of 40).
            Positioned(
              left: center.dx - 42,
              top: center.dy - 42,
              child: TypeOrb(type: selected, size: 84, iconSize: 38, selected: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _node(
    String type,
    Offset pos,
    AppPalette p,
    Duration duration,
    Curve curve,
  ) {
    final m = chart[type] ?? 1;
    final isFocus = focus == type;
    final neutral = m == 1;
    return AnimatedPositioned(
      key: ValueKey(type),
      duration: duration,
      curve: curve,
      left: pos.dx - 24,
      top: pos.dy - 24,
      width: 48,
      height: 48,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: neutral && !isFocus ? 0.5 : 1,
        child: AnimatedScale(
          duration: duration,
          scale: isFocus ? 1.25 : 1,
          child: Semantics(
            button: true,
            label:
                '${formatPokemonName(type)}, ${legendLabel(m, mode)} ${formatMultiplier(m)}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onFocus(isFocus ? null : type),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TypeOrb(
                        type: type,
                        size: 40,
                        iconSize: 18,
                        selected: isFocus,
                      ),
                      if (!neutral)
                        Positioned(
                          right: -9,
                          bottom: -5,
                          child: _Badge(
                            text: formatMultiplier(m),
                            color: relationColor(m, mode),
                            ring: p.background,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.ring});

  final String text;
  final Color color;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 15,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: ring, spreadRadius: 1.5)],
      ),
      child: Text(
        text,
        style: monoStyle(8.5, weight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter({
    required this.center,
    required this.targets,
    required this.colors,
    required this.neutral,
    required this.focus,
    required this.glow,
  });

  final Offset center;
  final Map<String, Offset> targets;
  final Map<String, Color> colors;
  final Map<String, bool> neutral;
  final String? focus;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft glow behind the middle orb.
    canvas.drawCircle(
      center,
      75,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: 0.55), Colors.transparent],
          stops: const [0, 0.65],
        ).createShader(Rect.fromCircle(center: center, radius: 75)),
    );

    for (final entry in targets.entries) {
      final type = entry.key;
      final isFocus = focus == type;
      final isNeutral = neutral[type] ?? true;
      final width = isNeutral ? 1.5 : (isFocus ? 5.0 : 3.0);
      final opacity = isNeutral
          ? (isFocus ? 0.8 : 0.35)
          : (focus != null && !isFocus ? 0.45 : 1.0);

      final direction = (entry.value - center);
      final unit = direction / direction.distance;
      final from = center + unit * 48;
      final to = entry.value - unit * 22;

      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = colors[type]!.withValues(alpha: opacity)
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.center != center ||
      old.targets != targets ||
      old.colors != colors ||
      old.focus != focus ||
      old.glow != glow;
}
