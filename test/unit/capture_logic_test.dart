import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/features/catch/domain/capture_logic.dart';

void main() {
  group('captureProbability', () {
    test('master ball always catches', () {
      expect(
        captureProbability(captureRate: 3, ball: BallKind.master),
        1,
      );
    });

    test('easier Pokémon and better balls raise the chance', () {
      final hard = captureProbability(captureRate: 3, ball: BallKind.poke);
      final easy = captureProbability(captureRate: 255, ball: BallKind.poke);
      final ultra = captureProbability(captureRate: 45, ball: BallKind.ultra);
      final poke = captureProbability(captureRate: 45, ball: BallKind.poke);
      expect(easy, greaterThan(hard));
      expect(ultra, greaterThan(poke));
    });

    test('formula matches the design', () {
      // (45 * 1 / 255) * 0.7 + 0.12 = 0.2435...
      expect(
        captureProbability(captureRate: 45, ball: BallKind.poke),
        closeTo(0.2435, 0.001),
      );
    });

    test('never above 0.97 for normal balls', () {
      expect(
        captureProbability(
          captureRate: 255,
          ball: BallKind.ultra,
          bonus: 0.3,
        ),
        0.97,
      );
    });
  });

  test('ringBonus rewards a tight ring', () {
    expect(ringBonus(0.35).label, 'Excellent!');
    expect(ringBonus(0.35).bonus, 0.3);
    expect(ringBonus(0.6).label, 'Great!');
    expect(ringBonus(0.8).label, 'Nice!');
    expect(ringBonus(1).bonus, 0);
    expect(ringBonus(1).label, isEmpty);
  });

  group('throws', () {
    test('only fast upward flicks are throws', () {
      expect(isThrow(dy: -100, vy: -1.0), isTrue);
      expect(isThrow(dy: -100, vy: -0.2), isFalse); // too slow
      expect(isThrow(dy: -10, vy: -1.0), isFalse); // too short
      expect(isThrow(dy: 50, vy: 1.0), isFalse); // downwards
    });

    test('a straight, well-timed flick hits', () {
      // Pokémon 300px above the ball; velocity chosen so reach ~1.0.
      final o = resolveThrow(
        dx: 0,
        dy: -200,
        vx: 0,
        vy: -1.4,
        monX: 0,
        monY: -300,
      );
      expect(o.hit, isTrue);
      expect(o.endX, 0);
      expect(o.endY, -318);
    });

    test('too weak a flick falls short', () {
      final o = resolveThrow(
        dx: 0,
        dy: -60,
        vx: 0,
        vy: -0.6,
        monX: 0,
        monY: -300,
      );
      expect(o.hit, isFalse);
      expect(o.tooShort, isTrue);
    });

    test('sideways flick misses', () {
      final o = resolveThrow(
        dx: 120,
        dy: -150,
        vx: 0.5,
        vy: -1.4,
        monX: 0,
        monY: -300,
      );
      expect(o.hit, isFalse);
      expect(o.tooShort, isFalse);
    });

    test('too hard a flick overshoots', () {
      final o = resolveThrow(
        dx: 0,
        dy: -300,
        vx: 0,
        vy: -3,
        monX: 0,
        monY: -300,
      );
      expect(o.hit, isFalse);
    });
  });
}
