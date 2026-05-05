import 'dart:math' as math;
import 'dart:ui';

import '../config/game_constants.dart';

class DepthCharge {
  DepthCharge({required Offset startPosition}) : _position = startPosition;

  static const double _radius = 12;

  Offset _position;
  double _velocityY = 140;
  bool _inWater = false;
  bool isRemoved = false;

  Offset get position => _position;
  bool get isInWater => _inWater;

  Rect get bounds => Rect.fromCircle(center: _position, radius: _radius);

  void update(double dt, {required double waterlineY, required double playBottomY}) {
    if (dt <= 0 || isRemoved) {
      return;
    }

    if (!_inWater && _position.dy < waterlineY) {
      final double projectedY = _projectNextY(
        dt,
        acceleration: GameConstants.depthChargeAirAcceleration,
        maxSpeed: GameConstants.depthChargeAirMaxSpeed,
      );

      if (projectedY >= waterlineY) {
        final double travelDistance = projectedY - _position.dy;
        final double distanceToWater = waterlineY - _position.dy;
        final double airFraction = travelDistance <= 0
            ? 0
            : (distanceToWater / travelDistance).clamp(0.0, 1.0);
        final double airDt = dt * airFraction;

        if (airDt > 0) {
          _advance(
            airDt,
            acceleration: GameConstants.depthChargeAirAcceleration,
            maxSpeed: GameConstants.depthChargeAirMaxSpeed,
          );
        }

        _inWater = true;
        _position = Offset(_position.dx, math.max(_position.dy, waterlineY));
        _velocityY = math.min(_velocityY, 130);

        final double waterDt = dt - airDt;
        if (waterDt > 0) {
          _advance(
            waterDt,
            acceleration: GameConstants.depthChargeWaterAcceleration,
            maxSpeed: GameConstants.depthChargeWaterMaxSpeed,
          );
        }
      } else {
        _advance(
          dt,
          acceleration: GameConstants.depthChargeAirAcceleration,
          maxSpeed: GameConstants.depthChargeAirMaxSpeed,
        );
      }
    } else {
      if (!_inWater) {
        _inWater = true;
        _velocityY = math.min(_velocityY, 130);
      }

      _advance(
        dt,
        acceleration: GameConstants.depthChargeWaterAcceleration,
        maxSpeed: GameConstants.depthChargeWaterMaxSpeed,
      );
    }

    if (_position.dy - _radius > playBottomY + 24) {
      isRemoved = true;
    }
  }

  double _projectNextY(
    double dt, {
    required double acceleration,
    required double maxSpeed,
  }) {
    final double nextVelocity = math.min(maxSpeed, _velocityY + (acceleration * dt));
    final double averageVelocity = (_velocityY + nextVelocity) / 2;
    return _position.dy + (averageVelocity * dt);
  }

  void _advance(
    double dt, {
    required double acceleration,
    required double maxSpeed,
  }) {
    final double nextVelocity = math.min(maxSpeed, _velocityY + (acceleration * dt));
    final double averageVelocity = (_velocityY + nextVelocity) / 2;
    _position = _position.translate(0, averageVelocity * dt);
    _velocityY = nextVelocity;
  }

  void render(Canvas canvas) {
    if (_inWater) {
      final Paint bubblePaint = Paint()..color = const Color(0x88C9F8FF);
      for (int i = 0; i < 4; i += 1) {
        final double radius = 2.5 + i;
        final double drift = ((i.isEven ? -1 : 1) * (9 + i * 2)).toDouble();
        final double lift = (-18 - (i * 12)).toDouble();
        canvas.drawCircle(_position.translate(drift, lift), radius, bubblePaint);
      }
    }

    final Rect bodyRect = Rect.fromCenter(center: _position, width: _radius * 1.55, height: _radius * 2.25);
    final Paint bodyPaint = Paint()
      ..shader = Gradient.linear(
        bodyRect.topLeft,
        bodyRect.bottomRight,
        const <Color>[Color(0xFF7C929D), Color(0xFF283943), Color(0xFF0F171C)],
      );
    final Paint highlightPaint = Paint()..color = const Color(0xFFB3CDD8);

    canvas.save();
    canvas.translate(_position.dx, _position.dy);
    canvas.rotate(0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: _radius * 1.55, height: _radius * 2.25),
        const Radius.circular(7),
      ),
      bodyPaint,
    );
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, -10), width: 18, height: 3), highlightPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(0, 10), width: 18, height: 3), highlightPaint);
    canvas.drawCircle(const Offset(-3, -2), 3.2, Paint()..color = highlightPaint.color.withOpacity(0.65));
    canvas.restore();
  }
}
