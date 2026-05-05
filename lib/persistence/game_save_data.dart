import '../stages/stage_catalog.dart';

class GameSaveData {
  const GameSaveData({
    this.highScore = 0,
    this.scoreAttackHighScore = 0,
    this.clearedStageIds = const <String>[],
  });

  factory GameSaveData.fromJson(Map<String, Object?> json) {
    final Object? rawCleared = json['clearedStageIds'];
    return GameSaveData(
      highScore: _readInt(json['highScore']),
      scoreAttackHighScore: _readInt(json['scoreAttackHighScore']),
      clearedStageIds: rawCleared is List<Object?>
          ? rawCleared.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  final int highScore;
  final int scoreAttackHighScore;
  final List<String> clearedStageIds;

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool isStageUnlocked(String stageId) {
    if (stageId == StageCatalog.firstStage().id) {
      return true;
    }
    for (final String clearedStageId in clearedStageIds) {
      if (StageCatalog.nextStageId(clearedStageId) == stageId) {
        return true;
      }
    }
    return clearedStageIds.contains(stageId);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'highScore': highScore,
      'scoreAttackHighScore': scoreAttackHighScore,
      'clearedStageIds': clearedStageIds,
    };
  }

  GameSaveData recordResult({
    required String stageId,
    required int score,
    required bool cleared,
    bool scoreAttack = false,
  }) {
    if (scoreAttack) {
      return GameSaveData(
        highScore: highScore,
        scoreAttackHighScore: score > scoreAttackHighScore ? score : scoreAttackHighScore,
        clearedStageIds: clearedStageIds,
      );
    }

    final Set<String> nextCleared = clearedStageIds.toSet();
    if (cleared) {
      nextCleared.add(stageId);
    }

    return GameSaveData(
      highScore: score > highScore ? score : highScore,
      scoreAttackHighScore: scoreAttackHighScore,
      clearedStageIds: nextCleared.toList(growable: false)..sort(),
    );
  }
}
