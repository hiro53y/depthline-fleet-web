import 'package:depthline_fleet/config/game_constants.dart';
import 'package:depthline_fleet/entities/player_battleship.dart';
import 'package:depthline_fleet/gameplay/weapon_side.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('depth charges start above the waterline on both sides', () {
    final PlayerBattleship ship = PlayerBattleship(
      startX: GameConstants.playerStartX,
      startY: GameConstants.playerY,
    );

    final leftDrop = ship.dropPointFor(WeaponSide.left);
    final rightDrop = ship.dropPointFor(WeaponSide.right);

    expect(leftDrop.dy, lessThan(GameConstants.waterlineY));
    expect(rightDrop.dy, lessThan(GameConstants.waterlineY));
    expect(leftDrop.dx, lessThan(ship.position.dx));
    expect(rightDrop.dx, greaterThan(ship.position.dx));
  });
}
