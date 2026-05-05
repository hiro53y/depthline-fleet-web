import 'package:depthline_fleet/gameplay/game_session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GameSessionState.initial starts in playing state with wave 1', () {
    final GameSessionState state = GameSessionState.initial(totalWaves: 3, lives: 3);

    expect(state.score, 0);
    expect(state.lives, 3);
    expect(state.currentWave, 1);
    expect(state.totalWaves, 3);
    expect(state.status, GameStatus.playing);
    expect(state.powerupLabel, 'NONE');
  });

  test('copyWith updates only specified fields', () {
    const GameSessionState original = GameSessionState(
      score: 200,
      lives: 2,
      currentWave: 2,
      totalWaves: 3,
      status: GameStatus.playing,
      powerupLabel: 'NONE',
      powerupSecondsRemaining: 0,
    );

    final GameSessionState updated = original.copyWith(
      score: 300,
      status: GameStatus.cleared,
    );

    expect(updated.score, 300);
    expect(updated.lives, 2);
    expect(updated.currentWave, 2);
    expect(updated.status, GameStatus.cleared);
  });
}
