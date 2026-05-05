import 'dart:math' as math;

import 'package:depthline_fleet/gameplay/score_attack_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score attack controller spawns random wave definitions and levels up', () {
    final ScoreAttackController controller = ScoreAttackController(
      random: math.Random(1),
    );
    int spawns = 0;

    controller.update(
      1,
      activeEnemies: 0,
      onSpawn: (_) {
        spawns += 1;
      },
    );

    expect(spawns, 1);
    expect(controller.level, 1);

    for (int i = 0; i < 8; i += 1) {
      controller.markEnemyResolved();
    }

    expect(controller.level, greaterThan(1));
  });
}
