import 'package:depthline_fleet/gameplay/depthline_game.dart';
import 'package:depthline_fleet/stages/sea_stage_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DepthlineGame does not notify radar listeners when contacts are unchanged', () {
    final DepthlineGame game = DepthlineGame(stageDefinition: const SeaStageDefinition());
    int notifications = 0;

    game.radarNotifier.addListener(() {
      notifications += 1;
    });

    game.update(0.016);

    expect(notifications, 0);

    game.disposeState();
  });
}
