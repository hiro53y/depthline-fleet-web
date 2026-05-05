import 'dart:ui';

import '../config/game_constants.dart';
import 'powerup_type.dart';

class PowerupPickup {
  PowerupPickup({
    required this.type,
    required Offset startPosition,
  }) : _position = startPosition;

  static const double _size = 34;
  static const double _floatSpeed = -62;

  final PowerupType type;
  Offset _position;
  double _age = 0;
  bool isRemoved = false;

  Offset get position => _position;

  Rect get bounds => Rect.fromCenter(
        center: _position,
        width: _size,
        height: _size,
      );

  void update(double dt) {
    _age += dt;
    _position = _position.translate(0, _floatSpeed * dt);
    if (_position.dy < GameConstants.waterlineY - 18 || _age > 10) {
      isRemoved = true;
    }
  }

  void render(Canvas canvas) {
    final Color color = switch (type) {
      PowerupType.rapidReload => const Color(0xFFFFD56B),
      PowerupType.shield => const Color(0xFF89E8FF),
      PowerupType.repair => const Color(0xFFA5F28C),
    };
    final Paint glowPaint = Paint()..color = color.withOpacity(0.24);
    final Paint bodyPaint = Paint()..color = color;
    final Paint corePaint = Paint()..color = const Color(0xFF071018);

    canvas.drawCircle(_position, _size * 0.72, glowPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(9)),
      bodyPaint,
    );
    canvas.drawCircle(_position, 7, corePaint);

    if (type == PowerupType.repair) {
      canvas.drawRect(
        Rect.fromCenter(center: _position, width: 5, height: 18),
        bodyPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: _position, width: 18, height: 5),
        bodyPaint,
      );
    } else if (type == PowerupType.shield) {
      final Path shield = Path()
        ..moveTo(_position.dx, _position.dy - 13)
        ..lineTo(_position.dx + 12, _position.dy - 5)
        ..quadraticBezierTo(_position.dx + 8, _position.dy + 12, _position.dx, _position.dy + 16)
        ..quadraticBezierTo(_position.dx - 8, _position.dy + 12, _position.dx - 12, _position.dy - 5)
        ..close();
      canvas.drawPath(shield, Paint()..color = corePaint.color.withOpacity(0.7));
    } else {
      canvas.drawLine(
        _position.translate(-11, 8),
        _position.translate(0, -12),
        Paint()
          ..color = corePaint.color.withOpacity(0.7)
          ..strokeWidth = 4,
      );
      canvas.drawLine(
        _position.translate(0, -12),
        _position.translate(11, 8),
        Paint()
          ..color = corePaint.color.withOpacity(0.7)
          ..strokeWidth = 4,
      );
    }
  }
}
