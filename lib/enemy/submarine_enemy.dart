import 'dart:ui';

import 'torpedo.dart';

class SubmarineEnemy {
  SubmarineEnemy({
    required Offset startPosition,
    required this.speedX,
    required this.reloadDuration,
  }) : _position = startPosition;

  static const Size _size = Size(128, 38);

  Offset _position;
  final double speedX;
  final double reloadDuration;
  bool isRemoved = false;
  double _reloadRemaining = 1.2;

  Offset get position => _position;

  Rect get bounds => Rect.fromCenter(
        center: _position,
        width: _size.width * 0.88,
        height: _size.height * 0.75,
      );

  void update(double dt) {
    _position = _position.translate(speedX * dt, 0);
    if (_reloadRemaining > 0) {
      _reloadRemaining -= dt;
    }
  }

  bool hasEscaped(double worldWidth) {
    if (speedX >= 0) {
      return _position.dx - (_size.width / 2) > worldWidth + 20;
    }
    return _position.dx + (_size.width / 2) < -20;
  }

  Torpedo? tryFire(double playerX) {
    if (_reloadRemaining > 0) {
      return null;
    }
    if ((playerX - _position.dx).abs() > 92) {
      return null;
    }

    _reloadRemaining = reloadDuration;
    return Torpedo(
      startPosition: Offset(_position.dx, _position.dy - (_size.height / 2) - 12),
    );
  }

  void render(Canvas canvas) {
    final Paint hullPaint = Paint()..color = const Color(0xFF6F7C8C);
    final Paint cabinPaint = Paint()..color = const Color(0xFF9DA9B3);

    final Rect hullRect = Rect.fromCenter(
      center: _position,
      width: _size.width,
      height: _size.height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hullRect, const Radius.circular(20)),
      hullPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: _position.translate(12, -12), width: 30, height: 16),
        const Radius.circular(6),
      ),
      cabinPaint,
    );
    canvas.drawCircle(_position.translate(-48, 0), 7, cabinPaint);
  }
}
