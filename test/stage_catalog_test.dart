import 'package:depthline_fleet/stages/stage_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stage catalog exposes three sea stages in order', () {
    expect(StageCatalog.allStages, hasLength(3));
    expect(StageCatalog.allStages[0].stageNumber, 1);
    expect(StageCatalog.allStages[1].stageNumber, 2);
    expect(StageCatalog.allStages[2].stageNumber, 3);
    expect(StageCatalog.scoreAttackStageDefinition.stageNumber, 4);
  });
}
