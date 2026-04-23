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
    final Paint bodyPaint = Paint()..color = const Color(0xFF202C33);
    final Paint highlightPaint = Paint()..color = const Color(0xFF4F6974);

    canvas.drawCircle(_position, _radius, bodyPaint);
    canvas.drawCircle(_position.translate(-3, -3), _radius * 0.45, highlightPaint);

    // TODO: Add a subtle bubble trail in a later visuals pass.
  }
}
