enum GameAudioCue {
  start,
  drop,
  hit,
  powerup,
  damage,
  clear,
  gameOver,
  ambient,
}

enum GameMusicTrack {
  stage1,
  stage2,
  stage3,
  scoreAttack,
}

abstract class AudioBackend {
  Future<void> warmUp();

  void play(GameAudioCue cue);

  void startMusic(GameMusicTrack track);

  void stopMusic();
}
