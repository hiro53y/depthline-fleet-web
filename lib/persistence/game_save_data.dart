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
      highScore: json['highScore'] as int? ?? 0,
      scoreAttackHighScore: json['scoreAttackHighScore'] as int? ?? 0,
      clearedStageIds: rawCleared is List<Object?>
          ? rawCleared.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  final int highScore;
  final int scoreAttackHighScore;
  final List<String> clearedStageIds;

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
