enum GameStatus {
  playing,
  gameOver,
  cleared,
}

class GameSessionState {
  const GameSessionState({
    required this.score,
    required this.lives,
    required this.currentWave,
    required this.totalWaves,
    required this.status,
    required this.powerupLabel,
    required this.powerupSecondsRemaining,
  });

  factory GameSessionState.initial({required int totalWaves, required int lives}) {
    return GameSessionState(
      score: 0,
      lives: lives,
      currentWave: 1,
      totalWaves: totalWaves,
      status: GameStatus.playing,
      powerupLabel: 'NONE',
      powerupSecondsRemaining: 0,
    );
  }

  final int score;
  final int lives;
  final int currentWave;
  final int totalWaves;
  final GameStatus status;
  final String powerupLabel;
  final double powerupSecondsRemaining;

  bool get isPlaying => status == GameStatus.playing;

  GameSessionState copyWith({
    int? score,
    int? lives,
    int? currentWave,
    int? totalWaves,
    GameStatus? status,
    String? powerupLabel,
    double? powerupSecondsRemaining,
  }) {
    return GameSessionState(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      currentWave: currentWave ?? this.currentWave,
      totalWaves: totalWaves ?? this.totalWaves,
      status: status ?? this.status,
      powerupLabel: powerupLabel ?? this.powerupLabel,
      powerupSecondsRemaining: powerupSecondsRemaining ?? this.powerupSecondsRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GameSessionState &&
        other.score == score &&
        other.lives == lives &&
        other.currentWave == currentWave &&
        other.totalWaves == totalWaves &&
        other.status == status &&
        other.powerupLabel == powerupLabel &&
        other.powerupSecondsRemaining == powerupSecondsRemaining;
  }

  @override
  int get hashCode => Object.hash(
        score,
        lives,
        currentWave,
        totalWaves,
        status,
        powerupLabel,
        powerupSecondsRemaining,
      );
}
