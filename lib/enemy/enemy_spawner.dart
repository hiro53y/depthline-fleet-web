import 'dart:math' as math;
import 'dart:ui';

import '../gameplay/wave_definition.dart';
import '../stages/stage_definition.dart';
import 'submarine_enemy.dart';

class EnemySpawner {
  EnemySpawner(this._stage, {math.Random? random}) : _random = random ?? math.Random();

  final StageDefinition _stage;
  final math.Random _random;

  SubmarineEnemy spawn(WaveDefinition wave) {
    final bool fromLeft = _random.nextBool();
    final int laneIndex = wave.nextLaneIndex(_random);
    final double speed = wave.nextSpeed(_random) * (fromLeft ? 1 : -1);
    final double x = fromLeft ? -80 : _stage.worldWidth + 80;
    final double y = _stage.depthLanes[laneIndex];

    return SubmarineEnemy(
      startPosition: Offset(x, y),
      speedX: speed,
      reloadDuration: wave.torpedoCooldown,
    );
  }
}
