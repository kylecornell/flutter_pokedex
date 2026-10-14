import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../domain/capture_logic.dart';
import '../providers/catch_provider.dart';

enum _Phase { appear, idle, flying, hit, caught, fled }

enum _CameraState { loading, on, denied, off }

/// Throw Poké Balls at a wild Pokémon. The camera feed is the background
/// when available; otherwise a practice field is drawn.
class CatchScreen extends ConsumerStatefulWidget {
  const CatchScreen({
    super.key,
    this.random,
    this.cameraTimeout = const Duration(seconds: 8),
  });

  /// Source of randomness (encounter, catch roll). Injectable for tests.
  final math.Random? random;

  /// How long camera start-up may take before the practice field is used.
  final Duration cameraTimeout;

  @override
  ConsumerState<CatchScreen> createState() => _CatchScreenState();
}

class _CatchScreenState extends ConsumerState<CatchScreen>
    with TickerProviderStateMixin {
  static const double _ballSize = 68;
  static const double _ballBottom = 92;

  late final math.Random _random = widget.random ?? math.Random();

  // Camera
  CameraController? _camera;
  _CameraState _cameraState = _CameraState.loading;

  // Encounter
  int _token = 0;
  int? _id;
  String _name = '';
  int _captureRate = 45;
  bool _gifFailed = false;
  _Phase _phase = _Phase.appear;
  String _message = '';
  BallKind _ball = BallKind.poke;

  // Animated values
  double _ballX = 0, _ballY = 0, _ballScale = 1, _ballRotation = 0;
  double _ballOpacity = 1;
  double _monOpacity = 0, _monScale = 0.3, _monDy = 0, _monBright = 1;

  late final AnimationController _ring;
  late final AnimationController _bob;

  // Drag tracking
  Offset? _dragOrigin;
  final List<(Offset, DateTime)> _points = [];

  // Stage size (set while building).
  Size _stage = Size.zero;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (ref.read(settingsProvider).animationsEnabled) _bob.repeat(reverse: true);

    _startCamera();
    _newEncounter();
  }

  @override
  void dispose() {
    _token++; // cancels in-flight sequences
    _ring.dispose();
    _bob.dispose();
    _camera?.dispose();
    super.dispose();
  }

  // ---- camera -----------------------------------------------------------

  Future<void> _startCamera() async {
    setState(() => _cameraState = _CameraState.loading);
    try {
      // Camera start-up can hang on some devices: give up after a while and
      // fall back to the practice field.
      final cameras =
          await availableCameras().timeout(widget.cameraTimeout);
      if (cameras.isEmpty) throw StateError('No camera');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize().timeout(widget.cameraTimeout);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _cameraState = _CameraState.on);
    } catch (_) {
      if (mounted) setState(() => _cameraState = _CameraState.denied);
    }
  }

  Future<void> _stopCamera() async {
    final controller = _camera;
    _camera = null;
    setState(() => _cameraState = _CameraState.off);
    await controller?.dispose();
  }

  // ---- animation helpers -------------------------------------------------

  /// Runs [apply] with t = 0..1 over [ms]. Returns false when the screen was
  /// closed or a new encounter started meanwhile.
  Future<bool> _tween(int ms, void Function(double t) apply) async {
    final token = _token;
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    controller.addListener(() {
      if (mounted && token == _token) setState(() => apply(controller.value));
    });
    try {
      await controller.forward();
    } catch (_) {
      // Ticker cancelled because the screen closed.
    } finally {
      controller.dispose();
    }
    return mounted && token == _token;
  }

  Future<bool> _wait(int ms) async {
    final token = _token;
    await Future<void>.delayed(Duration(milliseconds: ms));
    return mounted && token == _token;
  }

  void _flash(String text) {
    setState(() => _message = text);
    final token = _token;
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && token == _token) setState(() => _message = '');
    });
  }

  void _resetBall() {
    _ballX = 0;
    _ballY = 0;
    _ballScale = 1;
    _ballRotation = 0;
    _ballOpacity = 1;
  }

  // ---- encounter ---------------------------------------------------------

  Future<void> _newEncounter() async {
    final token = ++_token;
    setState(() {
      _phase = _Phase.appear;
      _message = '';
      _id = null;
      _gifFailed = false;
      _monOpacity = 0;
      _monScale = 0.3;
      _monDy = 0;
      _monBright = 3;
      _resetBall();
    });

    final repo = ref.read(pokemonRepositoryProvider);
    var id = 1 + _random.nextInt(1025);
    var name = 'Wild Pokémon';
    try {
      final index = await repo.getIndex();
      if (index.isNotEmpty) {
        final pick = index[_random.nextInt(index.length)];
        id = pick.id;
        name = formatPokemonName(pick.name);
      }
    } catch (_) {
      // Offline: keep the random id and generic name.
    }
    var capture = 45;
    try {
      capture = (await repo.getSpecies('$id')).captureRate ?? 45;
    } catch (_) {
      // Default capture rate.
    }
    if (!mounted || token != _token) return;

    setState(() {
      _id = id;
      _name = name;
      _captureRate = capture;
    });

    final ok = await _tween(480, (t) {
      final e = 1 - math.pow(1 - t, 3).toDouble();
      _monOpacity = e;
      _monScale = 0.3 + 0.7 * e;
      _monBright = 1 + 2 * (1 - e);
    });
    if (ok) setState(() => _phase = _Phase.idle);
  }

  // ---- throwing ----------------------------------------------------------

  void _onDragStart(DragStartDetails d) {
    if (_phase != _Phase.idle) return;
    _dragOrigin = d.globalPosition;
    _points
      ..clear()
      ..add((d.globalPosition, DateTime.now()));
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final origin = _dragOrigin;
    if (origin == null) return;
    final delta = d.globalPosition - origin;
    setState(() {
      _ballX = delta.dx;
      _ballY = delta.dy;
      _ballRotation = delta.dx * 0.4;
    });
    _points.add((d.globalPosition, DateTime.now()));
    if (_points.length > 10) _points.removeAt(0);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    final origin = _dragOrigin;
    if (origin == null) return;
    _dragOrigin = null;

    final v = d.velocity.pixelsPerSecond / 1000; // px per ms
    final dx = _ballX;
    final dy = _ballY;

    if (isThrow(dy: dy, vy: v.dy)) {
      await _throwBall(dx, dy, v.dx, v.dy);
    } else {
      final fromX = _ballX, fromY = _ballY, fromR = _ballRotation;
      await _tween(350, (t) {
        final e = Curves.easeOutCubic.transform(t);
        _ballX = fromX * (1 - e);
        _ballY = fromY * (1 - e);
        _ballRotation = fromR * (1 - e);
      });
    }
  }

  Future<void> _throwBall(double dx, double dy, double vx, double vy) async {
    final token = _token;
    final restCenterY = _stage.height - _ballBottom - _ballSize / 2;
    final monY = _stage.height * 0.42 - restCenterY;
    final ringScale = 1 - 0.7 * _ring.value;

    final outcome = resolveThrow(
      dx: dx,
      dy: dy,
      vx: vx,
      vy: vy,
      monX: 0,
      monY: monY,
    );
    final spin = (vx >= 0 ? 1 : -1) * 1080.0;
    final ex = outcome.endX, ey = outcome.endY;

    setState(() {
      _phase = _Phase.flying;
      _message = '';
    });
    final flew = await _tween(outcome.hit ? 640 : 700, (t) {
      _ballX = dx + (ex - dx) * t;
      _ballY = dy + (ey - dy) * t - 170 * 4 * t * (1 - t);
      _ballScale = 1 - 0.56 * t;
      _ballRotation = spin * t;
    });
    if (!flew) return;

    if (!outcome.hit) {
      final sx = _ballX, sy = _ballY;
      if (!await _tween(280, (t) {
        _ballX = sx + vx * 120 * t;
        _ballY = sy + 70 * t * t;
        _ballOpacity = 1 - t;
      })) {
        return;
      }
      _flash(outcome.tooShort ? 'Too short' : 'Missed');
      if (!await _wait(250)) return;
      setState(() {
        _resetBall();
        _phase = _Phase.idle;
      });
      return;
    }

    final bonus = ringBonus(ringScale);
    setState(() => _phase = _Phase.hit);
    if (bonus.label.isNotEmpty) _flash(bonus.label);

    if (!await _tween(200, (t) {
      _ballY = ey - 28 * math.sin(t * math.pi / 2);
    })) {
      return;
    }
    // Pokémon is sucked into the ball.
    if (!await _tween(360, (t) {
      _monOpacity = 1 - t;
      _monDy = -30 * t;
      _monScale = 1 - 0.92 * t;
      _monBright = 1 + 5 * t;
    })) {
      return;
    }
    final groundY = monY + 48;
    final y1 = ey - 28;
    if (!await _tween(300, (t) => _ballY = y1 + (groundY - y1) * t * t)) return;
    if (!await _tween(170, (t) => _ballY = groundY - 14 * math.sin(t * math.pi))) {
      return;
    }

    final usedMaster = _ball == BallKind.master;
    if (usedMaster) {
      await ref.read(catchProvider.notifier).useMasterBall();
      if (!mounted || token != _token) return;
    }
    final chance = captureProbability(
      captureRate: _captureRate,
      ball: _ball,
      bonus: bonus.bonus,
    );
    final caught = _random.nextDouble() < chance;
    final breakAt = caught ? 4 : 1 + _random.nextInt(3);

    for (var i = 1; i <= 3; i++) {
      if (i == breakAt) break;
      if (!await _wait(360)) return;
      if (!await _tween(540, (t) {
        _ballRotation = spin + math.sin(t * math.pi * 2) * 26;
      })) {
        return;
      }
    }

    if (usedMaster && ref.read(catchProvider).masterBalls <= 0) {
      setState(() => _ball = BallKind.ultra);
    }
    if (!mounted || token != _token) return;

    if (caught) {
      if (!await _wait(300)) return;
      final id = _id;
      if (id != null) {
        await ref.read(catchProvider.notifier).recordCatch(id);
        if (!ref.read(favoritesProvider).contains(id)) {
          await ref.read(favoritesProvider.notifier).toggle(id);
        }
      }
      if (mounted && token == _token) setState(() => _phase = _Phase.caught);
      return;
    }

    // Broke free.
    if (!await _wait(220)) return;
    setState(() => _ballOpacity = 0);
    if (!await _tween(320, (t) {
      _monOpacity = t;
      _monScale = 0.3 + 0.7 * t;
      _monDy = 0;
      _monBright = 1 + 3 * (1 - t);
    })) {
      return;
    }
    if (_random.nextDouble() < 0.12) {
      if (!await _wait(300)) return;
      if (!await _tween(420, (t) {
        _monOpacity = 1 - t;
        _monDy = -30 * t;
        _monScale = 1 - 0.3 * t;
      })) {
        return;
      }
      setState(() => _phase = _Phase.fled);
      return;
    }
    _flash('It broke free!');
    if (!await _wait(400)) return;
    setState(() {
      _resetBall();
      _phase = _Phase.idle;
    });
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final catchState = ref.watch(catchProvider);
    final id = _id;
    final animations =
        ref.watch(settingsProvider.select((s) => s.animationsEnabled));
    final ringColor = _captureRate >= 120
        ? const Color(0xFF22C55E)
        : _captureRate >= 45
            ? const Color(0xFFEAB308)
            : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _stage = constraints.biggest;
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final monTop = h * 0.42;

          return Stack(
              fit: StackFit.expand,
              children: [
                _background(),
                // Name tag above the Pokémon.
                if (id != null && _phase != _Phase.caught && _phase != _Phase.fled)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: monTop - 132,
                    child: Center(
                      child: _Pill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatDexNumber(id),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // The Pokémon.
                Positioned(
                  left: w / 2 - 110,
                  top: monTop - 110,
                  width: 220,
                  height: 220,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _monOpacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _monDy),
                        child: Transform.scale(
                          scale: _monScale,
                          child: _MonsterView(
                            id: id,
                            bright: _monBright,
                            bob: animations ? _bob : null,
                            ring: _phase == _Phase.idle ? _ring : null,
                            ringColor: ringColor,
                            gifFailed: _gifFailed,
                            onGifError: () {
                              if (!_gifFailed) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _gifFailed = true);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_message.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: h * 0.58,
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0x59000000), offset: Offset(0, 2)),
                          Shadow(color: Color(0x59000000), blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                if (_phase == _Phase.idle && _message.isEmpty && _id != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 180,
                    child: Center(
                      child: _Pill(
                        child: Text(
                          'Flick the ${_ball.label} up at $_name',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Ball.
                Positioned(
                  left: (w - _ballSize) / 2,
                  bottom: _ballBottom,
                  width: _ballSize,
                  height: _ballSize,
                  child: GestureDetector(
                    onPanStart: _onDragStart,
                    onPanUpdate: _onDragUpdate,
                    onPanEnd: _onDragEnd,
                    child: Opacity(
                      opacity: _ballOpacity.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(_ballX, _ballY),
                        child: Transform.rotate(
                          angle: _ballRotation * math.pi / 180,
                          child: Transform.scale(
                            scale: _ballScale,
                            child: Semantics(
                              label: '${_ball.label}. Flick up to throw.',
                              child: _BallView(kind: _ball, size: _ballSize),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _topBar(),
                _bottomBar(catchState),
                if (_phase == _Phase.caught || _phase == _Phase.fled)
                  _result(p),
              ],
          );
        },
      ),
    );
  }

  Widget _background() {
    final camera = _camera;
    if (_cameraState == _CameraState.on &&
        camera != null &&
        camera.value.isInitialized) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: camera.value.previewSize?.height ?? 1,
            height: camera.value.previewSize?.width ?? 1,
            child: CameraPreview(camera),
          ),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF7CC6EE),
            Color(0xFFBFE6FB),
            Color(0xFFA6D77F),
            Color(0xFF78B956),
            Color(0xFF5C9E40),
          ],
          stops: [0, 0.46, 0.463, 0.72, 1],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, 0.12),
        child: Container(
          width: 300,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(150),
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final label = switch (_cameraState) {
      _CameraState.on => 'AR camera',
      _CameraState.loading => 'Starting camera…',
      _ => 'Practice field',
    };
    final dot = _cameraState == _CameraState.on
        ? const Color(0xFFEF4444)
        : const Color(0xFFA1A1AA);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                _RoundButton(
                  tooltip: 'Close camera',
                  icon: Icons.close,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
                Expanded(
                  child: Center(
                    child: _Pill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _RoundButton(
                  tooltip: 'Toggle camera',
                  icon: Icons.photo_camera_outlined,
                  onTap: () => _cameraState == _CameraState.on
                      ? _stopCamera()
                      : _startCamera(),
                ),
              ],
            ),
            if (_cameraState == _CameraState.denied)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Camera unavailable. Showing practice field.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(CatchState catchState) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 20,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Pill(
              height: 36,
              child: Text(
                '${catchState.caught.length} caught',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0x8C09090B),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  for (final kind in BallKind.values)
                    _BallChoice(
                      kind: kind,
                      selected: kind == _ball,
                      disabled:
                          kind == BallKind.master && catchState.masterBalls <= 0,
                      count: kind == BallKind.master
                          ? catchState.masterBalls
                          : null,
                      onTap: () {
                        if (kind == BallKind.master &&
                            catchState.masterBalls <= 0) {
                          _flash('No Master Ball left');
                          return;
                        }
                        if (_phase == _Phase.idle || _phase == _Phase.appear) {
                          setState(() {
                            _ball = kind;
                            _resetBall();
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
            _RoundButton(
              tooltip: 'New encounter',
              icon: Icons.shuffle,
              onTap: _newEncounter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _result(AppPalette p) {
    final caught = _phase == _Phase.caught;
    final id = _id;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: p.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (id != null)
                      Image.network(
                        Pokemon.artworkUrlForId(id),
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(width: 72),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caught ? 'GOTCHA!' : 'IT GOT AWAY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: caught ? p.success : p.mutedForeground,
                            ),
                          ),
                          Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            caught
                                ? 'Added to your collection.'
                                : 'It fled before you could catch it.',
                            style: TextStyle(
                              fontSize: 13,
                              color: p.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (caught && id != null)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () => context.pushReplacement('/pokemon/$id'),
                          child: const Text('View details'),
                        ),
                      ),
                    if (caught && id != null) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: _newEncounter,
                        child: const Text('Find another'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child, this.height = 32});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x99090B09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x8C09090B),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MonsterView extends StatelessWidget {
  const _MonsterView({
    required this.id,
    required this.bright,
    required this.bob,
    required this.ring,
    required this.ringColor,
    required this.gifFailed,
    required this.onGifError,
  });

  final int? id;
  final double bright;
  final AnimationController? bob;
  final AnimationController? ring;
  final Color ringColor;
  final bool gifFailed;
  final VoidCallback onGifError;

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    // Brightness via a color matrix (1 = unchanged).
    final b = bright;
    final filter = ColorFilter.matrix([
      b, 0, 0, 0, 0, //
      0, b, 0, 0, 0,
      0, 0, b, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 18,
          child: Container(
            width: 120,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(60),
            ),
          ),
        ),
        if (ring != null)
          AnimatedBuilder(
            animation: ring!,
            builder: (context, _) {
              final scale = 1 - 0.7 * ring!.value;
              return Transform.translate(
                offset: const Offset(0, 8),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ringColor, width: 4),
                    ),
                  ),
                ),
              );
            },
          ),
        if (id != null)
          AnimatedBuilder(
            animation: bob ?? kAlwaysCompleteAnimation,
            builder: (context, child) {
              final dy = bob == null
                  ? 0.0
                  : -7 * Curves.easeInOut.transform(bob!.value);
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: ColorFiltered(
              colorFilter: filter,
              child: Image.network(
                gifFailed
                    ? Pokemon.artworkUrlForId(id)
                    : Pokemon.animatedSpriteUrlForId(id),
                key: ValueKey('$id-$gifFailed'),
                height: gifFailed ? 170 : 120,
                fit: BoxFit.contain,
                filterQuality:
                    gifFailed ? FilterQuality.medium : FilterQuality.none,
                errorBuilder: (context, error, stack) {
                  if (!gifFailed) onGifError();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _BallChoice extends StatelessWidget {
  const _BallChoice({
    required this.kind,
    required this.selected,
    required this.disabled,
    required this.onTap,
    this.count,
  });

  final BallKind kind;
  final bool selected;
  final bool disabled;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: kind.label,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _BallView(kind: kind, size: 32, mini: true)),
                if (count != null)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18181B),
                        ),
                      ),
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

class _BallView extends StatelessWidget {
  const _BallView({required this.kind, required this.size, this.mini = false});

  final BallKind kind;
  final double size;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BallPainter(kind, mini),
    );
  }
}

class _BallPainter extends CustomPainter {
  _BallPainter(this.kind, this.mini);

  final BallKind kind;
  final bool mini;

  Color get _top => switch (kind) {
        BallKind.poke => const Color(0xFFEF4444),
        BallKind.great => const Color(0xFF2563EB),
        BallKind.ultra => const Color(0xFF27272A),
        BallKind.master => const Color(0xFF7E22CE),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final border = mini ? 2.0 : 3.0;
    const ink = Color(0xFF18181B);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * 0.45), Paint()..color = _top);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.45, size.width, h * 0.1),
      Paint()..color = ink,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.55, size.width, h * 0.45),
      Paint()..color = const Color(0xFFF4F4F5),
    );

    // Markings on the top half.
    final mark = Paint();
    switch (kind) {
      case BallKind.poke:
        break;
      case BallKind.great:
        mark.color = const Color(0xFFEF4444);
        canvas.drawCircle(Offset(size.width * 0.2, h * 0.34), r * 0.3, mark);
        canvas.drawCircle(Offset(size.width * 0.8, h * 0.34), r * 0.3, mark);
      case BallKind.ultra:
        mark.color = const Color(0xFFFACC15);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.24, 0, size.width * 0.12, h * 0.45),
          mark,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.64, 0, size.width * 0.12, h * 0.45),
          mark,
        );
      case BallKind.master:
        mark.color = const Color(0xFFF472B6);
        canvas.drawCircle(Offset(size.width * 0.24, h * 0.28), r * 0.26, mark);
        canvas.drawCircle(Offset(size.width * 0.76, h * 0.28), r * 0.26, mark);
    }
    canvas.restore();

    canvas.drawCircle(
      c,
      r - border / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border
        ..color = ink,
    );
    // Center button.
    final button = r * (mini ? 0.32 : 0.33);
    canvas.drawCircle(c, button, Paint()..color = const Color(0xFFFAFAFA));
    canvas.drawCircle(
      c,
      button,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = border
        ..color = ink,
    );
    // Glint.
    canvas.drawOval(
      Rect.fromLTWH(r * 0.42, r * 0.28, r * 0.42, r * 0.24),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_BallPainter old) => old.kind != kind || old.mini != mini;
}
