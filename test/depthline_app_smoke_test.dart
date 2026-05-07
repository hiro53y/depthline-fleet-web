import 'package:depthline_fleet/gameplay/depthline_game.dart';
import 'package:depthline_fleet/gameplay/weapon_side.dart';
import 'package:depthline_fleet/persistence/game_settings.dart';
import 'package:depthline_fleet/radar/radar_contact.dart';
import 'package:depthline_fleet/stages/sea_stage_definition.dart';
import 'package:depthline_fleet/ui/depthline_app.dart';
import 'package:depthline_fleet/ui/depthline_game_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Depthline app renders game screen and controls', (WidgetTester tester) async {
    await tester.pumpWidget(const DepthlineFleetApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('DEPTHLINE FLEET'), findsOneWidget);
    expect(find.text('出撃'), findsOneWidget);

    await tester.tap(find.text('出撃'));
    await tester.pump();

    expect(find.byType(DepthlineGameScreen), findsOneWidget);
    expect(find.byType(GameWidget<DepthlineGame>), findsOneWidget);
    expect(find.text('Sea Stage 1'), findsOneWidget);
    expect(find.text('左移動'), findsOneWidget);
    expect(find.text('右移動'), findsOneWidget);
    expect(find.text('左投下'), findsOneWidget);
    expect(find.text('右投下'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
  });

  test('DepthlineGame can be created and publish depth charge radar contact', () {
    final DepthlineGame game = DepthlineGame(
      stageDefinition: const SeaStageDefinition(),
      settings: const GameSettings(soundEnabled: false),
    );

    game.tryDropDepthCharge(WeaponSide.left);
    game.update(0.016);

    expect(game.sessionState.isPlaying, isTrue);
    expect(
      game.radarNotifier.value.any(
        (RadarContact contact) => contact.type == RadarContactType.depthCharge,
      ),
      isTrue,
    );

    game.disposeState();
  });
}
