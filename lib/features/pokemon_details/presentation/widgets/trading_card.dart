import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../shared/widgets/pokeball_outline.dart';
import '../../../../shared/widgets/type_badge.dart';
import '../../../../shared/widgets/type_icon.dart';
import '../../domain/card_view_model.dart';

/// Pokémon-card sized widget (63:88) with flip, tilt and holographic light.
///
/// The card has no network code: the picture window content is passed in as
/// [viewer], so the same card shows artwork, a GIF sprite or a 3D model.
class TradingCard extends StatefulWidget {
  const TradingCard({
    super.key,
    required this.data,
    required this.viewer,
    required this.flipped,
    required this.onFlip,
    required this.onTypeTap,
    this.effects = true,
    this.animations = true,
    this.tiltEnabled = true,
    this.viewerOverlay,
    this.width = 296,
  });

  final CardViewModel data;

  /// Content of the picture window (artwork, sprite or 3D model).
  final Widget viewer;
  final bool flipped;
  final VoidCallback onFlip;
  final ValueChanged<String> onTypeTap;

  /// Settings > Card effects: tilt and holographic light.
  final bool effects;
  final bool animations;

  /// False while a 3D model is shown on the front so dragging rotates the
  /// model instead of the card.
  final bool tiltEnabled;

  /// Widgets drawn over the picture window (full-screen button, hints).
  final Widget? viewerOverlay;
  final double width;

  @override
  State<TradingCard> createState() => _TradingCardState();
}

class _TradingCardState extends State<TradingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  Offset? _pointer; // 0..1 inside the card, null when idle

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: widget.flipped ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(TradingCard old) {
    super.didUpdateWidget(old);
    if (old.flipped != widget.flipped) {
      if (widget.animations) {
        widget.flipped ? _flip.forward() : _flip.reverse();
      } else {
        _flip.value = widget.flipped ? 1 : 0;
      }
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _track(PointerEvent e, Size size) {
    if (!widget.effects || (!widget.tiltEnabled && !widget.flipped)) return;
    setState(() {
      _pointer = Offset(
        (e.localPosition.dx / size.width).clamp(0.0, 1.0),
        (e.localPosition.dy / size.height).clamp(0.0, 1.0),
      );
    });
  }

  void _release() {
    if (_pointer != null) setState(() => _pointer = null);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width * 88 / 63;
    final size = Size(width, height);
    final pointer = _pointer;

    var tilt = Matrix4.identity()..setEntry(3, 2, 0.0011);
    if (pointer != null) {
      final sign = widget.flipped ? -1.0 : 1.0;
      tilt = tilt
        ..rotateX((0.5 - pointer.dy) * 16 * math.pi / 180)
        ..rotateY((pointer.dx - 0.5) * 18 * sign * math.pi / 180);
    }

    return Listener(
      onPointerDown: (e) => _track(e, size),
      onPointerMove: (e) => _track(e, size),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedContainer(
        duration: Duration(milliseconds: pointer == null ? 600 : 80),
        curve: pointer == null ? const Cubic(0.16, 1, 0.3, 1) : Curves.linear,
        transform: tilt,
        transformAlignment: Alignment.center,
        width: width,
        height: height,
        child: AnimatedBuilder(
          animation: CurvedAnimation(
            parent: _flip,
            curve: const Cubic(0.16, 1, 0.3, 1),
          ),
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(_flip.value);
            final angle = t * math.pi;
            final showBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _CardBack(
                        data: widget.data,
                        pointer: widget.effects ? pointer : null,
                        onTap: widget.onFlip,
                      ),
                    )
                  : _CardFront(
                      data: widget.data,
                      viewer: widget.viewer,
                      viewerOverlay: widget.viewerOverlay,
                      pointer: widget.effects ? pointer : null,
                      onTypeTap: widget.onTypeTap,
                      onViewerTap: widget.onFlip,
                    ),
            );
          },
        ),
      ),
    );
  }
}

LinearGradient _foilGradient(CardFoil foil) {
  const begin = Alignment.topLeft;
  const end = Alignment.bottomRight;
  switch (foil) {
    case CardFoil.legendary:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFFFDE68A),
          Color(0xFFF472B6),
          Color(0xFF60A5FA),
          Color(0xFF34D399),
          Color(0xFFFACC15),
          Color(0xFFFDE68A),
        ],
        stops: [0, 0.2, 0.4, 0.6, 0.8, 1],
      );
    case CardFoil.mythical:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFFFBCFE8),
          Color(0xFFC084FC),
          Color(0xFFFDF4FF),
          Color(0xFFF472B6),
          Color(0xFFFBCFE8),
        ],
        stops: [0, 0.25, 0.5, 0.75, 1],
      );
    case CardFoil.mega:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFF1E1B4B),
          Color(0xFFA855F7),
          Color(0xFFF0ABFC),
          Color(0xFF6D28D9),
          Color(0xFF1E1B4B),
        ],
        stops: [0, 0.3, 0.5, 0.7, 1],
      );
    case CardFoil.gmax:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFF450A0A),
          Color(0xFFEF4444),
          Color(0xFFFECACA),
          Color(0xFFB91C1C),
          Color(0xFF450A0A),
        ],
        stops: [0, 0.3, 0.5, 0.7, 1],
      );
    case CardFoil.silver:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFFF4F4F5),
          Color(0xFFA1A1AA),
          Color(0xFFFFFFFF),
          Color(0xFF8E8E96),
          Color(0xFFE4E4E7),
        ],
        stops: [0, 0.28, 0.5, 0.72, 1],
      );
    case CardFoil.gold:
    case CardFoil.teal:
      return const LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Color(0xFFEFE3B0),
          Color(0xFFC8A24C),
          Color(0xFFFFF4C9),
          Color(0xFFB48A34),
          Color(0xFFEFE0A2),
        ],
        stops: [0, 0.28, 0.5, 0.72, 1],
      );
  }
}

Color _ribbonInk(CardViewModel d) {
  if (d.ribbon.isEmpty) return const Color(0xFFFDE68A);
  switch (d.foil) {
    case CardFoil.mega:
      return const Color(0xFFF0ABFC);
    case CardFoil.gmax:
      return const Color(0xFFFECACA);
    case CardFoil.mythical:
      return const Color(0xFFF9A8D4);
    case CardFoil.legendary:
      return const Color(0xFFFDE68A);
    default:
      return d.ribbon.endsWith('form') && d.ribbon.split(' ').length == 2
          ? const Color(0xFFBBF7D0)
          : const Color(0xFFFEF08A);
  }
}

/// Foil frame (7px) around the card face.
class _Foil extends StatelessWidget {
  const _Foil({required this.foil, required this.child, this.onTap});

  final CardFoil foil;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: _foilGradient(foil),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 44,
              spreadRadius: -14,
              offset: Offset(0, 22),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}

/// Rainbow + spotlight following the pointer, blended over the face.
class _Holo extends StatelessWidget {
  const _Holo({required this.pointer, required this.child});

  final Offset? pointer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = pointer;
    if (p == null) return child;
    final hx = p.dx;
    final y = p.dy;

    return ShaderMask(
      blendMode: BlendMode.overlay,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        transform: GradientRotation((110 + hx * 50 - 135) * math.pi / 180),
        colors: const [
          Color(0x00FFFFFF),
          Color(0x59FF00AA),
          Color(0x6100DCFF),
          Color(0x52FFF000),
          Color(0x00FFFFFF),
        ],
        stops: [
          0.10 + hx * 0.2,
          0.28 + hx * 0.2,
          0.42 + hx * 0.2,
          0.56 + hx * 0.2,
          (0.74 + hx * 0.2).clamp(0.0, 1.0),
        ],
      ).createShader(rect),
      child: ShaderMask(
        blendMode: BlendMode.overlay,
        shaderCallback: (rect) => RadialGradient(
          center: Alignment(hx * 2 - 1, y * 2 - 1),
          radius: 0.8,
          colors: const [Color(0xBFFFFFFF), Color(0x00FFFFFF)],
          stops: const [0, 1],
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.data,
    required this.viewer,
    required this.viewerOverlay,
    required this.pointer,
    required this.onTypeTap,
    required this.onViewerTap,
  });

  final CardViewModel data;
  final Widget viewer;
  final Widget? viewerOverlay;
  final Offset? pointer;
  final ValueChanged<String> onTypeTap;
  final VoidCallback onViewerTap;

  @override
  Widget build(BuildContext context) {
    final c1 = data.color1;
    final c2 = data.color2;
    const white = Colors.white;
    final ink = data.ink;
    final hasRibbon = data.ribbon.isNotEmpty;

    final face = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.45, -1),
          end: const Alignment(0.45, 1),
          colors: [
            Color.lerp(c1, white, 0.2)!,
            c1,
            Color.lerp(c2, Colors.black, 0.28)!,
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, hasRibbon ? 20 : 10, 12, 10),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(
                        21,
                        weight: FontWeight.w700,
                        color: ink,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    'HP ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  Text(
                    data.hp,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Opacity(
                opacity: 0.85,
                child: Text(
                  '${data.number} · ${data.genus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onViewerTap,
                  child: _ViewerWindow(
                    overlay: viewerOverlay,
                    child: viewer,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in data.types)
                    GestureDetector(
                      onTap: () => onTypeTap(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor(t),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIconData(t), size: 12, color: typeInk(t)),
                            const SizedBox(width: 4),
                            Text(
                              formatPokemonName(t),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: typeInk(t),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _Measure('Height', data.height),
                    _Measure('Weight', data.weight),
                    _Measure('Base exp', data.baseExp),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: ink.withValues(alpha: 0.85),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${data.generationLabel} · ${data.region}'),
                    Flexible(
                      child: Text(
                        data.abilityLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasRibbon)
            Positioned(
              top: -20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF18181B),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(9),
                    ),
                  ),
                  child: Text(
                    data.ribbon.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: _ribbonInk(data),
                    ),
                  ),
                ),
              ),
            ),
          // Soft diagonal shine.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      white.withValues(alpha: 0),
                      white.withValues(alpha: 0.2),
                      white.withValues(alpha: 0),
                    ],
                    stops: const [0.28, 0.44, 0.58],
                  ),
                ),
              ),
            ),
          ),
          if (data.isSpecial)
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _TexturePainter())),
            ),
        ],
      ),
    );

    return _Foil(
      foil: data.foil,
      // Tapping anywhere on the card face flips it (type badges and the
      // full-screen button handle their own taps first).
      onTap: onViewerTap,
      child: _Holo(pointer: pointer, child: face),
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF52525B),
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded picture window with a faint Pokéball and soft inner light.
class _ViewerWindow extends StatelessWidget {
  const _ViewerWindow({required this.child, this.overlay});

  final Widget child;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
        gradient: RadialGradient(
          center: const Alignment(0, -0.16),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.75),
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
          ],
          stops: const [0, 0.62, 1],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -40,
            right: -40,
            top: -40,
            bottom: -40,
            child: FittedBox(
              fit: BoxFit.cover,
              child: PokeballOutline(
                size: 300,
                strokeWidth: 0.8,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          child,
          ?overlay,
        ],
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  const _TexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    // Diagonal foil lines (115deg-ish), 12px period.
    for (var x = -size.height; x < size.width + size.height; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height * 0.47, size.height), paint);
    }
    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.44, -0.64),
        radius: 0.6,
        colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_TexturePainter old) => false;
}

class _BackStatRow extends StatelessWidget {
  const _BackStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: monoStyle(11.5, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (value / 180).clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(color, Colors.white, 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.data,
    required this.pointer,
    required this.onTap,
  });

  final CardViewModel data;
  final Offset? pointer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFF4F4F5);

    final face = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.17, -1),
              end: Alignment(0.17, 1),
              colors: [Color(0xFF1C2236), Color(0xFF0B0F1A)],
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1),
                radius: 1.0,
                colors: [
                  data.color1.withValues(alpha: 0.65),
                  Colors.transparent,
                ],
                stops: const [0, 0.7],
              ),
            ),
          ),
        ),
        Positioned(
          right: -90,
          bottom: -90,
          child: PokeballOutline(
            size: 330,
            strokeWidth: 0.6,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTextStyle(
            style: const TextStyle(color: light),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: 0.8,
                        child: const Text(
                          'POKÉDEX ENTRY · TAP TO FLIP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: 0.8,
                      child: Text(data.number, style: monoStyle(11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Flavor text + base stats. Scales down instead of
                // overflowing when a Pokédex entry is very long.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 250,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.flavor,
                            style: const TextStyle(fontSize: 13.5, height: 1.45),
                          ),
                          if (data.stats.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Opacity(
                              opacity: 0.65,
                              child: const Text(
                                'BASE STATS',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (final (label, value) in data.stats)
                              _BackStatRow(
                                label: label,
                                value: value,
                                color: data.color1,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ),
                  child: Wrap(
                    runSpacing: 10,
                    children: [
                      for (final (k, v) in data.backFacts)
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.65,
                                child: Text(
                                  k.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Text(
                                v,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in data.types)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor(t),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          formatPokemonName(t),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: typeInk(t),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return _Foil(
      foil: data.foil,
      onTap: onTap,
      child: _Holo(pointer: pointer, child: face),
    );
  }
}
