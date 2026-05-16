import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:web_audio' as html;

import 'audio_backend.dart';

AudioBackend createAudioBackend() => WebAudioBackend();

class WebAudioBackend implements AudioBackend {
  html.AudioContext? _context;
  Timer? _musicTimer;
  Object? _musicElement;
  GameMusicTrack? _currentTrack;
  int _musicStep = 0;
  int _musicToken = 0;

  @override
  Future<void> warmUp() async {
    _context ??= html.AudioContext();
    if (_context?.state == 'suspended') {
      await _context?.resume();
    }
  }

  @override
  void play(GameAudioCue cue) {
    final html.AudioContext context = _context ??= html.AudioContext();
    if (context.state == 'suspended') {
      unawaited(context.resume().catchError((_) {}));
    }

    final _Tone tone = _Tone.forCue(cue);
    _playTone(context, tone);
  }

  @override
  void startMusic(GameMusicTrack track) {
    final html.AudioContext context = _context ??= html.AudioContext();
    if (context.state == 'suspended') {
      unawaited(context.resume().catchError((_) {}));
    }

    if (_currentTrack == track && _musicTimer != null) {
      return;
    }
    stopMusic();
    _currentTrack = track;
    _musicStep = 0;

    if (_startExternalMusic(track)) {
      return;
    }
    _startGeneratedMusic(track);
  }

  void _startGeneratedMusic(GameMusicTrack track) {
    final _MusicPattern pattern = _MusicPattern.forTrack(track);
    _musicTimer = Timer.periodic(
      Duration(milliseconds: pattern.stepMillis),
      (_) {
        try {
          final html.AudioContext activeContext = _context ??= html.AudioContext();
          final double frequency = pattern.notes[_musicStep % pattern.notes.length];
          _playTone(
            activeContext,
            _Tone(
              frequency: frequency,
              duration: pattern.noteDuration,
              gain: pattern.gain,
              type: pattern.type,
            ),
          );
          if (_musicStep % 4 == 0) {
            _playTone(
              activeContext,
              _Tone(
                frequency: pattern.bassFrequency,
                duration: pattern.noteDuration * 1.8,
                gain: pattern.gain * 0.55,
                type: 'sine',
              ),
            );
          }
          _musicStep += 1;
        } catch (_) {
          // Browser audio can be interrupted by tab throttling or policy changes.
        }
      },
    );
  }

  bool _startExternalMusic(GameMusicTrack track) {
    final List<String> candidates = _MusicAsset.forTrack(track);
    if (candidates.isEmpty) {
      return false;
    }

    _startExternalMusicCandidate(track, candidates, 0, ++_musicToken);
    return true;
  }

  void _startExternalMusicCandidate(
    GameMusicTrack track,
    List<String> candidates,
    int index,
    int token,
  ) {
    if (token != _musicToken || _currentTrack != track) {
      return;
    }
    if (index >= candidates.length) {
      _startGeneratedMusic(track);
      return;
    }

    try {
      final Object audioConstructor = js_util.getProperty(js_util.globalThis, 'Audio');
      final Object audio = js_util.callConstructor(
        audioConstructor,
        <Object?>[candidates[index]],
      );
      _musicElement = audio;
      js_util.setProperty(audio, 'loop', true);
      js_util.setProperty(audio, 'preload', 'auto');
      js_util.setProperty(audio, 'volume', 0.62);
      js_util.setProperty(
        audio,
        'onerror',
        js_util.allowInterop(() {
          if (token != _musicToken || _currentTrack != track) {
            return;
          }
          _stopExternalMusic();
          _startExternalMusicCandidate(track, candidates, index + 1, token);
        }),
      );

      final Object? playResult = js_util.callMethod<Object?>(
        audio,
        'play',
        const <Object?>[],
      );
      if (playResult != null && js_util.hasProperty(playResult, 'catch')) {
        js_util.callMethod<Object?>(
          playResult,
          'catch',
          <Object?>[js_util.allowInterop((_) {})],
        );
      }
    } catch (_) {
      _stopExternalMusic();
      _startExternalMusicCandidate(track, candidates, index + 1, token);
    }
  }

  void _stopExternalMusic() {
    final Object? audio = _musicElement;
    if (audio == null) {
      return;
    }
    try {
      js_util.callMethod<void>(audio, 'pause', const <Object?>[]);
      js_util.setProperty(audio, 'currentTime', 0);
      js_util.setProperty(audio, 'onerror', null);
    } catch (_) {
      // External music is optional.
    }
    _musicElement = null;
  }

  @override
  void stopMusic() {
    _musicToken += 1;
    _stopExternalMusic();
    _musicTimer?.cancel();
    _musicTimer = null;
    _currentTrack = null;
    _musicStep = 0;
  }

  void _playTone(html.AudioContext context, _Tone tone) {
    try {
      final html.OscillatorNode oscillator = context.createOscillator();
      final html.GainNode gain = context.createGain();
      final double now = (context.currentTime ?? 0).toDouble();

      oscillator.type = tone.type;
      oscillator.frequency?.setValueAtTime(tone.frequency, now);
      gain.gain?.setValueAtTime(0.0001, now);
      gain.gain?.exponentialRampToValueAtTime(tone.gain, now + 0.02);
      gain.gain?.exponentialRampToValueAtTime(0.0001, now + tone.duration);

      oscillator.connectNode(gain);
      gain.connectNode(context.destination!);
      js_util.callMethod<void>(oscillator, 'start', const <Object?>[0]);
      js_util.callMethod<void>(
        oscillator,
        'stop',
        <Object?>[now + tone.duration + 0.03],
      );
    } catch (_) {
      // Sound is optional and must never break gameplay.
    }
  }
}

class _MusicPattern {
  const _MusicPattern({
    required this.notes,
    required this.bassFrequency,
    required this.stepMillis,
    required this.noteDuration,
    required this.gain,
    required this.type,
  });

  factory _MusicPattern.forTrack(GameMusicTrack track) {
    switch (track) {
      case GameMusicTrack.title:
        return const _MusicPattern(
          notes: <double>[196, 247, 294, 247, 220, 262, 330, 262],
          bassFrequency: 98,
          stepMillis: 410,
          noteDuration: 0.26,
          gain: 0.016,
          type: 'triangle',
        );
      case GameMusicTrack.stage1:
        return const _MusicPattern(
          notes: <double>[220, 247, 294, 330, 294, 247, 196, 220],
          bassFrequency: 110,
          stepMillis: 360,
          noteDuration: 0.24,
          gain: 0.018,
          type: 'triangle',
        );
      case GameMusicTrack.stage2:
        return const _MusicPattern(
          notes: <double>[196, 233, 262, 311, 349, 311, 262, 233],
          bassFrequency: 98,
          stepMillis: 310,
          noteDuration: 0.22,
          gain: 0.02,
          type: 'triangle',
        );
      case GameMusicTrack.stage3:
        return const _MusicPattern(
          notes: <double>[174, 220, 261, 329, 392, 329, 261, 220],
          bassFrequency: 87,
          stepMillis: 270,
          noteDuration: 0.2,
          gain: 0.022,
          type: 'sawtooth',
        );
      case GameMusicTrack.scoreAttack:
        return const _MusicPattern(
          notes: <double>[330, 392, 494, 587, 659, 740, 659, 494, 392, 523, 784, 988],
          bassFrequency: 165,
          stepMillis: 190,
          noteDuration: 0.16,
          gain: 0.026,
          type: 'square',
        );
    }
  }

  final List<double> notes;
  final double bassFrequency;
  final int stepMillis;
  final double noteDuration;
  final double gain;
  final String type;
}

class _MusicAsset {
  const _MusicAsset._();

  static const String _basePath = 'assets/assets/audio/bgm';

  static List<String> forTrack(GameMusicTrack track) {
    switch (track) {
      case GameMusicTrack.title:
        return const <String>['$_basePath/title.mp3'];
      case GameMusicTrack.stage1:
        return const <String>['$_basePath/campaign.mp3'];
      case GameMusicTrack.stage2:
        return const <String>['$_basePath/campaign.mp3'];
      case GameMusicTrack.stage3:
        return const <String>['$_basePath/campaign.mp3'];
      case GameMusicTrack.scoreAttack:
        return const <String>['$_basePath/score_attack.mp3'];
    }
  }
}

class _Tone {
  const _Tone({
    required this.frequency,
    required this.duration,
    required this.gain,
    required this.type,
  });

  factory _Tone.forCue(GameAudioCue cue) {
    switch (cue) {
      case GameAudioCue.start:
        return const _Tone(
          frequency: 330,
          duration: 0.18,
          gain: 0.055,
          type: 'triangle',
        );
      case GameAudioCue.drop:
        return const _Tone(
          frequency: 170,
          duration: 0.12,
          gain: 0.045,
          type: 'sine',
        );
      case GameAudioCue.hit:
        return const _Tone(
          frequency: 86,
          duration: 0.22,
          gain: 0.075,
          type: 'square',
        );
      case GameAudioCue.powerup:
        return const _Tone(
          frequency: 620,
          duration: 0.18,
          gain: 0.052,
          type: 'triangle',
        );
      case GameAudioCue.damage:
        return const _Tone(
          frequency: 120,
          duration: 0.28,
          gain: 0.07,
          type: 'sawtooth',
        );
      case GameAudioCue.clear:
        return const _Tone(
          frequency: 520,
          duration: 0.32,
          gain: 0.06,
          type: 'triangle',
        );
      case GameAudioCue.gameOver:
        return const _Tone(
          frequency: 72,
          duration: 0.38,
          gain: 0.065,
          type: 'sawtooth',
        );
      case GameAudioCue.ambient:
        return const _Tone(
          frequency: 210,
          duration: 0.08,
          gain: 0.025,
          type: 'sine',
        );
    }
  }

  final double frequency;
  final double duration;
  final double gain;
  final String type;
}
