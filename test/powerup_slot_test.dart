import 'package:depthline_fleet/powerup/powerup_slot.dart';
import 'package:depthline_fleet/powerup/powerup_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rapid reload lowers depth charge cooldown while active', () {
    final PowerupSlot slot = PowerupSlot()..activate(PowerupType.rapidReload);

    expect(slot.isActive, isTrue);
    expect(slot.cooldownMultiplier, lessThan(1));

    slot.update(PowerupSlot.rapidReloadDuration + 0.1);

    expect(slot.isActive, isFalse);
    expect(slot.cooldownMultiplier, 1);
  });

  test('shield is consumed once', () {
    final PowerupSlot slot = PowerupSlot()..activate(PowerupType.shield);

    expect(slot.consumeShield(), isTrue);
    expect(slot.consumeShield(), isFalse);
  });
}
