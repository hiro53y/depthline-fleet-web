import 'dart:ui';

class BubbleParticle {
  BubbleParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.lifetime,
  }) : _remaining = lifetime;

  Offset position;
  final Offset velocity;
  final double radius;
  final double lifetime;
  double _remaining;

  bool get isExpired => _remaining <= 0;

  void update(double dt) {
    _remaining -= dt;
    position = position.translate(velocity.dx * dt, velocity.dy * dt);
  }

  void render(Canvas canvas) {
    final double alpha = (_remaining / lifetime).clamp(0.0, 1.0);
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFC8F7FF).withOpacity(0.62 * alpha);
    final Paint fillPaint = Paint()
      ..color = const Color(0xFFB8F3FF).withOpacity(0.12 * alpha);

    canvas.drawCircle(position, radius, fillPaint);
    canvas.drawCircle(position, radius, ringPaint);
  }
}
