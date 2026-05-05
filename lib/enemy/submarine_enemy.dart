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
    final double direction = speedX >= 0 ? 1 : -1;
    canvas.save();
    canvas.translate(_position.dx, _position.dy);
    canvas.scale(direction, 1);

    final Paint shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 12), width: _size.width * 0.92, height: 22),
      shadowPaint,
    );

    final Rect hullRect = Rect.fromCenter(
      center: Offset.zero,
      width: _size.width,
      height: _size.height,
    );
    final Paint hullPaint = Paint()
      ..shader = Gradient.linear(
        hullRect.topCenter,
        hullRect.bottomCenter,
        const <Color>[
          Color(0xFF9EADBC),
          Color(0xFF596C7F),
          Color(0xFF263646),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hullRect, const Radius.circular(20)),
      hullPaint,
    );

    final Paint bellyPaint = Paint()
      ..color = const Color(0xFF1D2C3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(2, 4), width: _size.width - 8, height: _size.height - 8),
      0,
      3.14,
      false,
      bellyPaint,
    );

    final Paint cabinPaint = Paint()..color = const Color(0xFFB4C3CF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(9, -17), width: 38, height: 18),
        const Radius.circular(6),
      ),
      cabinPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(28, -26), width: 3, height: 15),
      cabinPaint,
    );

    final Paint windowPaint = Paint()..color = const Color(0xFFFFC96B);
    for (final double x in <double>[-42, -20, 2, 24, 46]) {
      canvas.drawCircle(Offset(x, -1), 4.2, windowPaint);
      canvas.drawCircle(Offset(x, -1), 7.2, Paint()..color = windowPaint.color.withOpacity(0.12));
    }

    final Paint finPaint = Paint()..color = const Color(0xFF425467);
    canvas.drawPath(
      Path()
        ..moveTo(-58, -2)
        ..lineTo(-80, -15)
        ..lineTo(-74, -2)
        ..lineTo(-80, 12)
        ..close(),
      finPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(56, -8)
        ..lineTo(72, -18)
        ..lineTo(67, -5)
        ..close(),
      finPaint,
    );
    canvas.drawLine(
      const Offset(-50, -13),
      const Offset(50, -13),
      Paint()
        ..color = const Color(0x99D9EEF8)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }
}
