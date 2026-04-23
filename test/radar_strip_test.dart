import 'package:depthline_fleet/gameplay/game_session_state.dart';
import 'package:depthline_fleet/radar/radar_contact.dart';
import 'package:depthline_fleet/radar/radar_strip.dart';
import 'package:depthline_fleet/radar/world_to_radar_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RadarStrip updates overlay text when session status changes', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<List<RadarContact>> contacts = ValueNotifier<List<RadarContact>>(
      const <RadarContact>[],
    );
    final ValueNotifier<GameSessionState> session = ValueNotifier<GameSessionState>(
      GameSessionState.initial(totalWaves: 3, lives: 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 64,
            child: RadarStrip(
              contactsListenable: contacts,
              mapper: const WorldToRadarMapper(
                worldWidth: 1280,
                waterlineY: 170,
                playBottomY: 560,
                radarWidth: 1280,
                radarHeight: 64,
              ),
              sessionListenable: session,
            ),
          ),
        ),
      ),
    );

    final CustomPaint before = tester.widget<CustomPaint>(find.byType(CustomPaint));

    session.value = session.value.copyWith(status: GameStatus.gameOver);
    await tester.pump();

    final CustomPaint after = tester.widget<CustomPaint>(find.byType(CustomPaint));

    expect(after.painter, isNot(same(before.painter)));

    contacts.dispose();
    session.dispose();
  });
}
