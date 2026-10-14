import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_typography.dart';
import 'pokeball_outline.dart';

/// The four Pokédex-device colors used for page headers. Home is red,
/// Pokédex green, Favorites yellow, Settings blue.
enum HeaderAccent {
  red(
    top: Color(0xFFE3350D),
    bottom: Color(0xFFC8280A),
    ink: Colors.white,
  ),
  green(
    top: Color(0xFF3FBF3A),
    bottom: Color(0xFF2A8F27),
    ink: Colors.white,
  ),
  yellow(
    top: Color(0xFFFFCB05),
    bottom: Color(0xFFE0A800),
    ink: Color(0xFF3A2D00),
  ),
  blue(
    top: Color(0xFF3B9BEA),
    bottom: Color(0xFF1D5FB0),
    ink: Colors.white,
  );

  const HeaderAccent({
    required this.top,
    required this.bottom,
    required this.ink,
  });

  final Color top;
  final Color bottom;

  /// Readable text/icon color on the gradient.
  final Color ink;

  bool get _darkInk => this == HeaderAccent.yellow;
}

const _lensBlue = Color(0xFF3B9BEA);
const _lightRed = Color(0xFFFF3B1F);
const _lightYellow = Color(0xFFFFCB05);
const _lightGreen = Color(0xFF3FBF3A);

/// Page header from the Home design: colored gradient with rounded bottom
/// corners, a Pokéball outline watermark, the blue lens with three lights,
/// then a Fredoka title and subtitle.
///
/// It reaches under the status bar by itself, so pages should not wrap it
/// in a top `SafeArea`.
class PokedexHeader extends StatelessWidget {
  const PokedexHeader({
    super.key,
    required this.title,
    required this.accent,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.large = false,
  });

  final String title;
  final String? subtitle;
  final HeaderAccent accent;

  /// Shows a back button when set.
  final VoidCallback? onBack;

  /// Widgets at the right end of the top row (theme toggle, heart, ...).
  final List<Widget> actions;

  /// Home size: bigger lens, lights and title.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final ink = accent.ink;
    final lens = large ? 44.0 : 32.0;
    final light = large ? 12.0 : 10.0;
    final titleSize = large ? 34.0 : 26.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: accent._darkInk
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          onBack == null ? 18 : 6,
          top + 6,
          12,
          large ? 22 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.top, accent.bottom],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -52,
              top: -46,
              child: PokeballOutline(
                size: large ? 190 : 150,
                strokeWidth: 1.2,
                color: ink.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        tooltip: 'Back',
                        color: ink,
                        icon: const Icon(Icons.chevron_left, size: 30),
                        onPressed: onBack,
                      ),
                    _Lens(size: lens, glow: accent == HeaderAccent.blue),
                    SizedBox(width: large ? 10 : 8),
                    _Light(
                      color: _lightRed,
                      size: light,
                      glow: accent == HeaderAccent.red,
                    ),
                    SizedBox(width: large ? 10 : 8),
                    _Light(
                      color: _lightYellow,
                      size: light,
                      glow: accent == HeaderAccent.yellow,
                    ),
                    SizedBox(width: large ? 10 : 8),
                    _Light(
                      color: _lightGreen,
                      size: light,
                      glow: accent == HeaderAccent.green,
                    ),
                    const Spacer(),
                    ...actions,
                  ],
                ),
                SizedBox(height: large ? 14 : 8),
                Padding(
                  padding: EdgeInsets.only(left: onBack == null ? 0 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            titleSize,
                            weight: FontWeight.w700,
                            color: ink,
                            height: 1,
                            letterSpacing: 0.3,
                          ).copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(
                                  alpha: accent._darkInk ? 0.08 : 0.18,
                                ),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: large ? 14 : 13,
                            fontWeight: FontWeight.w600,
                            color: ink.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Round header button (theme toggle, ...) in the Home style.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.accent,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final HeaderAccent accent;

  @override
  Widget build(BuildContext context) {
    final ink = accent.ink;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ink.withValues(alpha: 0.35), width: 2),
          ),
          child: Icon(icon, color: ink, size: 20),
        ),
      ),
    );
  }
}

class _Lens extends StatelessWidget {
  const _Lens({required this.size, required this.glow});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.77;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          const BoxShadow(color: Color(0x33000000), offset: Offset(0, 2)),
          if (glow)
            BoxShadow(
              color: _lensBlue.withValues(alpha: 0.7),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0F3A75), width: 2),
          gradient: const RadialGradient(
            center: Alignment(-0.32, -0.4),
            colors: [
              Color(0xFFBFE3FF),
              Color(0xFF3B9BEA),
              Color(0xFF1D5FB0),
              Color(0xFF0F3A75),
            ],
            stops: [0.14, 0.3, 0.75, 1],
          ),
        ),
      ),
    );
  }
}

class _Light extends StatelessWidget {
  const _Light({required this.color, required this.size, required this.glow});

  final Color color;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          const BoxShadow(color: Color(0x40000000), spreadRadius: 2),
          if (glow)
            BoxShadow(
              color: color.withValues(alpha: 0.9),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}
