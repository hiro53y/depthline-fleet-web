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

    final Paint hullPaint = Paint()..color = const Color(0xFFB9C3C9).withOpacity(blinkAlpha);
    final Paint deckPaint = Paint()..color = const Color(0xFF506670).withOpacity(blinkAlpha);
    final Paint accentPaint = Paint()..color = const Color(0xFFDFE8EC).withOpacity(blinkAlpha);

    final Rect hullRect = Rect.fromCenter(
      center: _position.translate(0, 8),
      width: _size.width,
      height: 22,
    );
    final RRect hull = RRect.fromRectAndRadius(hullRect, const Radius.circular(8));
    canvas.drawRRect(hull, hullPaint);

    final Rect deckRect = Rect.fromCenter(
      center: _position.translate(0, -2),
      width: 100,
      height: 18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(deckRect, const Radius.circular(6)),
      deckPaint,
    );

    final Rect bridgeRect = Rect.fromCenter(
      center: _position.translate(6, -14),
      width: 28,
      height: 18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bridgeRect, const Radius.circular(4)),
      accentPaint,
    );

    canvas.drawRect(
      Rect.fromCenter(center: _position.translate(-22, -14), width: 28, height: 4),
      accentPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: _position.translate(34, -10), width: 28, height: 4),
      accentPaint,
    );
  }
}
