/// The four balls. `multiplier` scales the catch chance.
enum BallKind {
  poke('Poké Ball', 1),
  great('Great Ball', 1.5),
  ultra('Ultra Ball', 2),
  master('Master Ball', 255);

  const BallKind(this.label, this.multiplier);

  final String label;
  final double multiplier;
}

/// Bonus for throwing while the shrinking ring is small.
/// [ringScale] is 1 (ring wide) down to 0.3 (ring tight).
({String label, double bonus}) ringBonus(double ringScale) {
  if (ringScale < 0.45) return (label: 'Excellent!', bonus: 0.3);
  if (ringScale < 0.7) return (label: 'Great!', bonus: 0.18);
  if (ringScale < 0.9) return (label: 'Nice!', bonus: 0.08);
  return (label: '', bonus: 0);
}

/// Chance (0..1) that a thrown ball catches the Pokémon.
///
/// [captureRate] is the species' `capture_rate` (3 = very hard, 255 = easy).
double captureProbability({
  required int captureRate,
  required BallKind ball,
  double bonus = 0,
}) {
  if (ball == BallKind.master) return 1;
  final base = (captureRate * ball.multiplier / 255) * 0.7 + 0.12 + bonus;
  return base.clamp(0.0, 0.97);
}

/// Result of a flick, before animating it.
class ThrowOutcome {
  const ThrowOutcome({
    required this.hit,
    required this.endX,
    required this.endY,
    required this.reach,
    required this.tooShort,
  });

  final bool hit;
  final double endX;
  final double endY;

  /// 0..1.3: how far the flick carries relative to the Pokémon.
  final double reach;
  final bool tooShort;
}

/// Works out where a flick ends and whether it hits.
///
/// Positions are logical pixels relative to the ball's resting position.
/// [dx]/[dy] is how far the finger dragged, [vx]/[vy] the release velocity in
/// pixels per millisecond (negative [vy] = upwards), and
/// ([monX], [monY]) the Pokémon's center.
ThrowOutcome resolveThrow({
  required double dx,
  required double dy,
  required double vx,
  required double vy,
  required double monX,
  required double monY,
}) {
  final reach = (-vy / 1.4).clamp(double.negativeInfinity, 1.3);
  final targetX = dx + vx * 300;
  final targetY = monY * reach + 20;
  final hit = (targetX - monX).abs() < 62 && reach > 0.8 && reach < 1.28;
  return ThrowOutcome(
    hit: hit,
    endX: hit ? monX : targetX,
    endY: hit ? monY - 18 : targetY,
    reach: reach,
    tooShort: reach <= 0.8,
  );
}

/// A flick counts as a throw when it is fast and goes up.
bool isThrow({required double dy, required double vy}) => vy < -0.45 && dy < -20;
