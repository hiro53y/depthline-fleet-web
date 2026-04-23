import '../config/game_constants.dart';
import '../gameplay/wave_definition.dart';
import 'stage_definition.dart';

class SeaStageDefinition implements StageDefinition {
  const SeaStageDefinition();

  @override
  List<double> get depthLanes => const <double>[255, 360, 460];

  @override
  String get name => 'Sea Stage 1';

  @override
  double get playBottomY => GameConstants.playBottom;

  @override
  double get playerStartX => GameConstants.playerStartX;

  @override
  double get waterlineY => GameConstants.waterlineY;

  @override
  List<WaveDefinition> get waves => const <WaveDefinition>[
        WaveDefinition(
          enemyCount: 3,
          spawnInterval: 1.6,
          minSpeed: 115,
          maxSpeed: 145,
          torpedoCooldown: 2.8,
          laneIndices: <int>[0, 1, 2],
        ),
        WaveDefinition(
          enemyCount: 4,
          spawnInterval: 1.35,
          minSpeed: 135,
          maxSpeed: 170,
          torpedoCooldown: 2.5,
          laneIndices: <int>[0, 1, 2],
        ),
        WaveDefinition(
          enemyCount: 5,
          spawnInterval: 1.1,
          minSpeed: 155,
          maxSpeed: 205,
          torpedoCooldown: 2.2,
          laneIndices: <int>[0, 1, 2],
        ),
      ];

  @override
  double get worldHeight => GameConstants.logicalHeight;

  @override
  double get worldWidth => GameConstants.logicalWidth;
}
