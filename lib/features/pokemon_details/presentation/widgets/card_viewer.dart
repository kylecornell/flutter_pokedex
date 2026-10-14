import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../shared/models/app_settings.dart';
import '../../../../shared/models/pokemon.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/widgets/pokemon_artwork.dart';

/// Short hint pinned to the bottom-left of the picture window.
String viewerHint(ViewerMode mode, {bool spriteFailed = false}) {
  switch (mode) {
    case ViewerMode.art:
      return 'Tap to flip';
    case ViewerMode.animated:
      return spriteFailed ? 'Static sprite · tap to flip' : 'Tap to flip';
    case ViewerMode.model3d:
      return 'Drag to rotate';
  }
}

/// Content of the card's picture window: artwork, animated sprite or 3D.
///
/// Every mode has a fallback, so the card always shows something.
class CardViewer extends ConsumerWidget {
  const CardViewer({
    super.key,
    required this.pokemonId,
    required this.name,
    required this.mode,
    required this.onShowArtwork,
  });

  /// Pokédex number of the shown form (assets are keyed by it).
  final int pokemonId;
  final String name;
  final ViewerMode mode;
  final VoidCallback onShowArtwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (mode) {
      case ViewerMode.art:
        return _FloatingArtwork(pokemonId: pokemonId, name: name);
      case ViewerMode.animated:
        return _AnimatedSprite(pokemonId: pokemonId, name: name);
      case ViewerMode.model3d:
        return _Model3d(
          pokemonId: pokemonId,
          name: name,
          onShowArtwork: onShowArtwork,
        );
    }
  }
}

class _FloatingArtwork extends ConsumerStatefulWidget {
  const _FloatingArtwork({required this.pokemonId, required this.name});

  final int pokemonId;
  final String name;

  @override
  ConsumerState<_FloatingArtwork> createState() => _FloatingArtworkState();
}

class _FloatingArtworkState extends ConsumerState<_FloatingArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (ref.read(settingsProvider).animationsEnabled) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final inset = c.maxHeight * 0.06;
        return AnimatedBuilder(
          animation: _float,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -7 * Curves.easeInOut.transform(_float.value)),
            child: child,
          ),
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: Semantics(
              image: true,
              label: widget.name,
              child: PokemonArtwork(url: Pokemon.artworkUrlForId(widget.pokemonId)),
            ),
          ),
        );
      },
    );
  }
}

/// Showdown GIF -> static sprite -> artwork, whichever loads first.
class _AnimatedSprite extends StatefulWidget {
  const _AnimatedSprite({required this.pokemonId, required this.name});

  final int pokemonId;
  final String name;

  @override
  State<_AnimatedSprite> createState() => _AnimatedSpriteState();
}

class _AnimatedSpriteState extends State<_AnimatedSprite> {
  int _failures = 0;

  @override
  void didUpdateWidget(_AnimatedSprite old) {
    super.didUpdateWidget(old);
    if (old.pokemonId != widget.pokemonId) _failures = 0;
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.pokemonId;
    final urls = [
      Pokemon.animatedSpriteUrlForId(id),
      Pokemon.spriteUrlForId(id),
      Pokemon.artworkUrlForId(id),
    ];
    final step = _failures.clamp(0, 2);
    final fractions = [0.58, 0.72, 0.8];

    return LayoutBuilder(
      builder: (context, c) => Center(
        child: Semantics(
          image: true,
          label: widget.name,
          child: Image.network(
            urls[step],
            key: ValueKey('${widget.pokemonId}-$step'),
            height: c.maxHeight * fractions[step],
            fit: BoxFit.contain,
            filterQuality: step < 2 ? FilterQuality.none : FilterQuality.medium,
            errorBuilder: (context, error, stack) {
              if (_failures < 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _failures++);
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _Model3d extends ConsumerWidget {
  const _Model3d({
    required this.pokemonId,
    required this.name,
    required this.onShowArtwork,
  });

  final int pokemonId;
  final String name;
  final VoidCallback onShowArtwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(model3dUrlProvider(pokemonId));

    return model.when(
      loading: () => const _Pill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Finding 3D model…'),
          ],
        ),
      ),
      error: (_, _) => _Unavailable(onShowArtwork: onShowArtwork),
      data: (url) {
        if (url == null) return _Unavailable(onShowArtwork: onShowArtwork);
        return ModelViewer(
          key: ValueKey(url),
          src: url,
          alt: '3D model of $name',
          autoPlay: true,
          cameraControls: true,
          disableZoom: false,
          backgroundColor: Colors.transparent,
          cameraOrbit: '20deg 75deg auto',
          interactionPrompt: InteractionPrompt.none,
        );
      },
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onShowArtwork});

  final VoidCallback onShowArtwork;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle(
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF18181B)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_in_ar, size: 26),
              const SizedBox(height: 8),
              const Text(
                '3D model not available for this Pokémon.',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                "The community model library doesn't include this one yet.",
                style: TextStyle(fontSize: 11, color: Color(0xFF52525B)),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  minimumSize: const Size(0, 32),
                ),
                onPressed: onShowArtwork,
                child: const Text('Show artwork'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18181B),
          ),
          child: child,
        ),
      ),
    );
  }
}
