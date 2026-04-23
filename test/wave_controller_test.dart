import 'package:depthline_fleet/gameplay/wave_controller.dart';
import 'package:depthline_fleet/gameplay/wave_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WaveController advances to next wave after current wave resolves', () {
    final WaveController controller = WaveController(
      const <WaveDefinition>[
        WaveDefinition(
          enemyCount: 1,
          spawnInterval: 1,
          minSpeed: 100,
          maxSpeed: 120,
          torpedoCooldown: 2,
          laneIndices: <int>[0],
        ),
        WaveDefinition(
          enemyCount: 1,
          spawnInterval: 1,
          minSpeed: 120,
          maxSpeed: 140,
          torpedoCooldown: 2,
          laneIndices: <int>[1],
        ),
      ],
    );

    int spawnCount = 0;
    controller.update(
      0.8,
      activeEnemies: 0,
      onSpawn: (_) => spawnCount += 1,
    );
    controller.markEnemyResolved();

    final WaveControllerEvent event = controller.evaluate(activeEnemies: 0);

    expect(spawnCount, 1);
    expect(event, WaveControllerEvent.waveAdvanced);
    expect(controller.currentWaveNumber, 2);
  });

  test('WaveController clears the stage on last resolved wave', () {
    final WaveController controller = WaveController(
      const <WaveDefinition>[
        WaveDefinition(
          enemyCount: 1,
          spawnInterval: 1,
          minSpeed: 100,
          maxSpeed: 120,
          torpedoCooldown: 2,
          laneIndices: <int>[0],
        ),
      ],
    );

    controller.update(
      0.8,
      activeEnemies: 0,
      onSpawn: (_) {},
    );
    controller.markEnemyResolved();

    expect(
      controller.evaluate(activeEnemies: 0),
      WaveControllerEvent.stageCleared,
    );
    expect(controller.stageCleared, isTrue);
  });
}
