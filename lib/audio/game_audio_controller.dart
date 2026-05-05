import '../persistence/game_settings.dart';
import 'audio_backend.dart';
import 'audio_backend_factory.dart';

class GameAudioController {
  GameAudioController({required GameSettings settings})
      : _settings = settings,
        _backend = createPlatformAudioBackend();

  final GameSettings _settings;
  final AudioBackend _backend;

  Future<void> warmUp() async {
    try {
      await _backend.warmUp();
    } catch (_) {
      // Audio startup is best-effort, especially on mobile browsers.
    }
  }

  void play(GameAudioCue cue) {
    if (!_settings.soundEnabled) {
      return;
    }
    if (cue == GameAudioCue.ambient && !_settings.ambientEnabled) {
      return;
    }
    try {
      _backend.play(cue);
    } catch (_) {
      // Keep gameplay responsive even when a browser blocks audio.
    }
  }

  void startMusic(GameMusicTrack track) {
    if (!_settings.musicEnabled) {
      return;
    }
    try {
      _backend.startMusic(track);
    } catch (_) {
      // Music is optional; blocked audio must not block play.
    }
  }

  void stopMusic() {
    try {
      _backend.stopMusic();
    } catch (_) {
      // Ignore platform audio shutdown errors.
    }
  }
}
