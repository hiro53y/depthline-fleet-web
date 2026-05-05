import '../config/game_constants.dart';
import '../gameplay/wave_definition.dart';
import 'stage_definition.dart';

enum SeaStageId {
  shelf,
  convoy,
  abyss,
  scoreAttack,
}

class SeaStageDefinition implements StageDefinition {
  const SeaStageDefinition({this.stageId = SeaStageId.shelf});

  final SeaStageId stageId;

  @override
  List<double> get depthLanes {
    switch (stageId) {
      case SeaStageId.shelf:
        return const <double>[255, 360, 460];
      case SeaStageId.convoy:
        return const <double>[238, 345, 470];
      case SeaStageId.abyss:
        return const <double>[275, 395, 500];
      case SeaStageId.scoreAttack:
        return const <double>[235, 350, 485];
    }
  }

  @override
  String get briefing {
    switch (stageId) {
      case SeaStageId.shelf:
        return '浅い海棚で接近する潜水艦を迎撃する基本海域。';
      case SeaStageId.convoy:
        return '輸送航路を守る中盤海域。敵の出現間隔が短くなる。';
      case SeaStageId.abyss:
        return '深海ゲートの最終海域。高速艦と魚雷の圧力が強い。';
      case SeaStageId.scoreAttack:
        return '撃沈されるまで続く記録戦。敵の出現パターンは毎回変わる。';
    }
  }

  @override
  String get id {
    switch (stageId) {
      case SeaStageId.shelf:
        return 'sea_shelf';
      case SeaStageId.convoy:
        return 'sea_convoy';
      case SeaStageId.abyss:
        return 'sea_abyss';
      case SeaStageId.scoreAttack:
        return 'score_attack';
    }
  }

  @override
  String get name {
    switch (stageId) {
      case SeaStageId.shelf:
        return 'Sea Stage 1';
      case SeaStageId.convoy:
        return 'Sea Stage 2';
      case SeaStageId.abyss:
        return 'Sea Stage 3';
      case SeaStageId.scoreAttack:
        return 'Score Attack';
    }
  }

  @override
  double get playBottomY => GameConstants.playBottom;

  @override
  double get playerStartX => GameConstants.playerStartX;

  @override
  double get waterlineY => GameConstants.waterlineY;

  @override
  int get stageNumber {
    switch (stageId) {
      case SeaStageId.shelf:
        return 1;
      case SeaStageId.convoy:
        return 2;
      case SeaStageId.abyss:
        return 3;
      case SeaStageId.scoreAttack:
        return 4;
    }
  }

  @override
  List<WaveDefinition> get waves {
    switch (stageId) {
      case SeaStageId.shelf:
        return const <WaveDefinition>[
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
      case SeaStageId.convoy:
        return const <WaveDefinition>[
          WaveDefinition(
            enemyCount: 4,
            spawnInterval: 1.35,
            minSpeed: 135,
            maxSpeed: 175,
            torpedoCooldown: 2.6,
            laneIndices: <int>[0, 1, 2],
          ),
          WaveDefinition(
            enemyCount: 5,
            spawnInterval: 1.15,
            minSpeed: 155,
            maxSpeed: 195,
            torpedoCooldown: 2.35,
            laneIndices: <int>[0, 1, 2],
          ),
          WaveDefinition(
            enemyCount: 6,
            spawnInterval: 1.0,
            minSpeed: 175,
            maxSpeed: 225,
            torpedoCooldown: 2.15,
            laneIndices: <int>[0, 1, 2],
          ),
        ];
      case SeaStageId.abyss:
        return const <WaveDefinition>[
          WaveDefinition(
            enemyCount: 5,
            spawnInterval: 1.15,
            minSpeed: 160,
            maxSpeed: 210,
            torpedoCooldown: 2.25,
            laneIndices: <int>[0, 1, 2],
          ),
          WaveDefinition(
            enemyCount: 6,
            spawnInterval: 0.95,
            minSpeed: 185,
            maxSpeed: 240,
            torpedoCooldown: 2.05,
            laneIndices: <int>[0, 1, 2],
          ),
          WaveDefinition(
            enemyCount: 7,
            spawnInterval: 0.85,
            minSpeed: 205,
            maxSpeed: 265,
            torpedoCooldown: 1.9,
            laneIndices: <int>[0, 1, 2],
          ),
        ];
      case SeaStageId.scoreAttack:
        return const <WaveDefinition>[
          WaveDefinition(
            enemyCount: 1,
            spawnInterval: 1,
            minSpeed: 140,
            maxSpeed: 180,
            torpedoCooldown: 2.4,
            laneIndices: <int>[0, 1, 2],
          ),
        ];
    }
  }

  @override
  double get worldHeight => GameConstants.logicalHeight;

  @override
  double get worldWidth => GameConstants.logicalWidth;
}
