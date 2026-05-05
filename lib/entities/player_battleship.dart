import 'dart:math' as math;
import 'dart:ui';

import '../config/game_constants.dart';
import '../gameplay/weapon_side.dart';

class PlayerBattleship {
  PlayerBattleship({
    required double startX,
    required double startY,
  }) : _position = Offset(startX, startY);

  static const Size _size = Size(148, 44);

  Offset _position;
  double _movementDirection = 0;
  double _invulnerabilityRemaining = 0;

  Offset get position => _position;
  bool get isInvulnerable => _invulnerabilityRemaining > 0;

  Rect get bounds => Rect.fromCenter(
        center: Offset(_position.dx, _position.dy + 4),
        width: _size.width * 0.8,
        height: _size.height * 0.58,
      );

  void setMovementDirection(double direction) {
    _movementDirection = direction.clamp(-1.0, 1.0);
  }

  void stop() {
    _movementDirection = 0;
  }

  void triggerInvulnerability() {
    _invulnerabilityRemaining = GameConstants.playerInvulnerabilitySeconds;
  }

  Offset dropPointFor(WeaponSide side) {
    final double offset = side == WeaponSide.left
        ? -GameConstants.depthChargeOffsetX
        : GameConstants.depthChargeOffsetX;
    return Offset(_position.dx + offset, _position.dy + 8);
  }

  void update(double dt, {required double minX, required double maxX}) {
    if (_invulnerabilityRemaining > 0) {
      _invulnerabilityRemaining = math.max(0, _invulnerabilityRemaining - dt);
    }

    final double nextX = (_position.dx + (_movementDirection * GameConstants.playerSpeed * dt))
        .clamp(minX + (_size.width / 2), maxX - (_size.width / 2))
        .toDouble();
    _position = Offset(nextX, _position.dy);
  }

  void render(Canvas canvas) {
    final double blinkAlpha = isInvulnerable
        ? ((_invulnerabilityRemaining * 12).floor().isEven ? 0.4 : 0.9)
        : 1.0;

    final Rect hullRect = Rect.fromCenter(
      center: _position.translate(0, 8),
      width: _size.width,
      height: 28,
    );
    final Path hullPath = Path()
      ..moveTo(hullRect.left + 10, hullRect.top + 5)
      ..lineTo(hullRect.right - 28, hullRect.top + 5)
      ..quadraticBezierTo(hullRect.right + 5, hullRect.top + 13, hullRect.right - 8, hullRect.bottom - 5)
      ..lineTo(hullRect.left + 28, hullRect.bottom - 3)
      ..quadraticBezierTo(hullRect.left - 5, hullRect.bottom - 10, hullRect.left + 10, hullRect.top + 5)
      ..close();

    final Paint shadowPaint = Paint()
      ..color = const Color(0x66000000).withOpacity(0.42 * blinkAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(hullPath.shift(const Offset(0, 8)), shadowPaint);

    final Paint hullPaint = Paint()
      ..shader = Gradient.linear(
        hullRect.topCenter,
        hullRect.bottomCenter,
        <Color>[
          const Color(0xFFEAF4F8).withOpacity(blinkAlpha),
          const Color(0xFF9FB2BD).withOpacity(blinkAlpha),
          const Color(0xFF536C78).withOpacity(blinkAlpha),
        ],
      );
    canvas.drawPath(hullPath, hullPaint);

    final Paint lowerHullPaint = Paint()..color = const Color(0xFF263F4C).withOpacity(0.90 * blinkAlpha);
    canvas.drawPath(
      Path()
        ..moveTo(hullRect.left + 24, hullRect.center.dy + 8)
        ..lineTo(hullRect.right - 18, hullRect.center.dy + 6)
        ..lineTo(hullRect.right - 8, hullRect.bottom - 5)
        ..lineTo(hullRect.left + 28, hullRect.bottom - 3)
        ..close(),
      lowerHullPaint,
    );

    final Rect deckRect = Rect.fromCenter(
      center: _position.translate(-2, -4),
      width: 104,
      height: 18,
    );
    final Paint deckPaint = Paint()
      ..shader = Gradient.linear(
        deckRect.topCenter,
        deckRect.bottomCenter,
        <Color>[
          const Color(0xFF7C929D).withOpacity(blinkAlpha),
          const Color(0xFF3C5662).withOpacity(blinkAlpha),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deckRect, const Radius.circular(6)),
      deckPaint,
    );

    final Paint accentPaint = Paint()..color = const Color(0xFFEAF4F8).withOpacity(blinkAlpha);
    final Paint darkPaint = Paint()..color = const Color(0xFF203641).withOpacity(blinkAlpha);
    final Rect bridgeRect = Rect.fromCenter(
      center: _position.translate(3, -18),
      width: 34,
      height: 19,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bridgeRect, const Radius.circular(5)),
      accentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: _position.translate(3, -20), width: 24, height: 7),
        const Radius.circular(3),
      ),
      darkPaint,
    );

    _drawTurret(canvas, Offset(_position.dx - 42, _position.dy - 10), -1, blinkAlpha);
    _drawTurret(canvas, Offset(_position.dx + 42, _position.dy - 9), 1, blinkAlpha);

    final Paint mastPaint = Paint()
      ..color = const Color(0xFFD8E7ED).withOpacity(blinkAlpha)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(_position.translate(14, -28), _position.translate(14, -48), mastPaint);
    canvas.drawLine(_position.translate(-2, -40), _position.translate(32, -40), mastPaint..strokeWidth = 2);
    canvas.drawCircle(_position.translate(14, -50), 3, accentPaint);

    final Paint wakePaint = Paint()
      ..color = const Color(0x88E7FBFF).withOpacity(0.34 * blinkAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i += 1) {
      final double y = _position.dy + 20.0 + (i * 6.0);
      canvas.drawLine(Offset(_position.dx - 110.0 - (i * 18.0), y), Offset(_position.dx - 78, y - 2), wakePaint);
      canvas.drawLine(Offset(_position.dx + 78, y - 2), Offset(_position.dx + 110.0 + (i * 18.0), y), wakePaint);
    }
  }

  void _drawTurret(Canvas canvas, Offset center, int direction, double alpha) {
    final Paint turretPaint = Paint()..color = const Color(0xFFE1EEF3).withOpacity(alpha);
    final Paint barrelPaint = Paint()
      ..color = const Color(0xFFD0E0E7).withOpacity(alpha)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 25, height: 13),
        const Radius.circular(6),
      ),
      turretPaint,
    );
    canvas.drawLine(center.translate(8.0 * direction, -2), center.translate(38.0 * direction, -5), barrelPaint);
  }
}
