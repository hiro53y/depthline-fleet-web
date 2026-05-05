import 'sea_stage_definition.dart';
import 'stage_definition.dart';

class StageCatalog {
  const StageCatalog._();

  static const List<StageDefinition> allStages = <StageDefinition>[
    SeaStageDefinition(stageId: SeaStageId.shelf),
    SeaStageDefinition(stageId: SeaStageId.convoy),
    SeaStageDefinition(stageId: SeaStageId.abyss),
  ];

  static const StageDefinition scoreAttackStageDefinition =
      SeaStageDefinition(stageId: SeaStageId.scoreAttack);

  static StageDefinition firstStage() => allStages.first;

  static StageDefinition byId(String id) {
    return allStages.firstWhere(
      (StageDefinition stage) => stage.id == id,
      orElse: firstStage,
    );
  }

  static String? nextStageId(String id) {
    final int index = allStages.indexWhere((StageDefinition stage) => stage.id == id);
    if (index < 0 || index >= allStages.length - 1) {
      return null;
    }
    return allStages[index + 1].id;
  }
}
