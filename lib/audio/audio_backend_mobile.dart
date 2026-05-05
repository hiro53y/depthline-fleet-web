import 'dart:async';

import 'package:flutter/services.dart';

import 'audio_backend.dart';

AudioBackend createAudioBackend() => MobileAudioBackend();

class MobileAudioBackend implements AudioBackend {
  @override
  Future<void> warmUp() async {}

  @override
  void play(GameAudioCue cue) {
    if (cue == GameAudioCue.ambient) {
      return;
    }
    unawaited(SystemSound.play(SystemSoundType.click).catchError((_) {}));
  }

  @override
  void startMusic(GameMusicTrack track) {}

  @override
  void stopMusic() {}
}
