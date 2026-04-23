import 'dart:ui';

import 'package:depthline_fleet/config/game_constants.dart';
import 'package:depthline_fleet/weapons/depth_charge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('depth charge switches to underwater motion within the crossing frame', () {
    final DepthCharge charge = DepthCharge(
      startPosition: Offset(320, GameConstants.waterlineY - 5),
    );

    const double dt = 0.2;
    const double initialVelocity = 140;
    final double pureAirNextVelocity =
        (initialVelocity + (GameConstants.depthChargeAirAcceleration * dt))
            .clamp(0, GameConstants.depthChargeAirMaxSpeed)
            .toDouble();
    final double pureAirProjectedY =
        (GameConstants.waterlineY - 5) + (((initialVelocity + pureAirNextVelocity) / 2) * dt);

    charge.update(
      dt,
      waterlineY: GameConstants.waterlineY,
      playBottomY: GameConstants.playBottom,
    );

    expect(charge.position.dy, greaterThanOrEqualTo(GameConstants.waterlineY));
    expect(charge.position.dy, lessThan(pureAirProjectedY));
    expect(charge.isRemoved, isFalse);
  });
}
