import 'package:depthline_fleet/persistence/game_save_data.dart';
import 'package:depthline_fleet/stages/stage_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('save data unlocks the next stage after a clear', () {
    final String firstStageId = StageCatalog.allStages[0].id;
    final String secondStageId = StageCatalog.allStages[1].id;

    final GameSaveData saveData = const GameSaveData().recordResult(
      stageId: firstStageId,
      score: 1200,
      cleared: true,
    );

    expect(saveData.highScore, 1200);
    expect(saveData.isStageUnlocked(secondStageId), isTrue);
  });

  test('failed run records high score without unlocking next stage', () {
    final String firstStageId = StageCatalog.allStages[0].id;
    final String secondStageId = StageCatalog.allStages[1].id;

    final GameSaveData saveData = const GameSaveData().recordResult(
      stageId: firstStageId,
      score: 400,
      cleared: false,
    );

    expect(saveData.highScore, 400);
    expect(saveData.isStageUnlocked(secondStageId), isFalse);
  });

  test('score attack records a separate high score', () {
    final GameSaveData saveData = const GameSaveData().recordResult(
      stageId: 'score_attack',
      score: 1800,
      cleared: false,
      scoreAttack: true,
    );

    expect(saveData.highScore, 0);
    expect(saveData.scoreAttackHighScore, 1800);
  });
}
