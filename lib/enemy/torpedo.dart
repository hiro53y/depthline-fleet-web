import 'dart:ui';

import '../config/game_constants.dart';

class Torpedo {
  Torpedo({required Offset startPosition}) : _position = startPosition;

  static const Size _size = Size(18, 36);
  static const double _speedY = -290;

  Offset _position;
  bool isRemoved = false;

  Offset get position => _position;

  Rect get bounds => Rect.fromCenter(
        center: _position,
        width: _size.width,
        height: _size.height,
      );

  void update(double dt) {
    _position = _position.translate(0, _speedY * dt);
    if (_position.dy + (_size.height / 2) < GameConstants.playTop) {
      isRemoved = true;
    }
  }

  void render(Canvas canvas) {
    final Rect glowRect = Rect.fromCircle(center: _position, radius: 24);
    canvas.drawCircle(
      _position,
      24,
      Paint()
        ..shader = Gradient.radial(
          _position,
          24,
          const <Color>[Color(0x66FFB55C), Color(0x00FFB55C)],
        ),
    );
    final Paint trailPaint = Paint()
      ..shader = Gradient.linear(
        glowRect.topCenter,
        glowRect.bottomCenter,
        const <Color>[Color(0x00FFD280), Color(0x77FFD280)],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: _position.translate(0, 24), width: 6, height: 34),
        const Radius.circular(4),
      ),
      trailPaint,
    );

    final Paint bodyPaint = Paint()
      ..shader = Gradient.linear(
        _position.translate(0, -18),
        _position.translate(0, 18),
        const <Color>[Color(0xFFFFE2A0), Color(0xFFF09A38), Color(0xFF8E3C1F)],
      );
    final Path bodyPath = Path()
      ..moveTo(_position.dx, _position.dy - (_size.height / 2))
      ..lineTo(_position.dx + (_size.width / 2), _position.dy + (_size.height / 2))
      ..lineTo(_position.dx - (_size.width / 2), _position.dy + (_size.height / 2))
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawCircle(_position.translate(0, 6), 3, Paint()..color = const Color(0xFFFFF1C8));
  }
}
