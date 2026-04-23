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
    final Paint bodyPaint = Paint()..color = const Color(0xFFF2A65A);
    final Path bodyPath = Path()
      ..moveTo(_position.dx, _position.dy - (_size.height / 2))
      ..lineTo(_position.dx + (_size.width / 2), _position.dy + (_size.height / 2))
      ..lineTo(_position.dx - (_size.width / 2), _position.dy + (_size.height / 2))
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
  }
}
