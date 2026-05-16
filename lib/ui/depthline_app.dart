import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/audio_backend.dart';
import '../audio/game_audio_controller.dart';
import '../gameplay/game_mode.dart';
import '../gameplay/game_session_state.dart';
import '../persistence/game_save_data.dart';
import '../persistence/game_settings.dart';
import '../persistence/persisted_state.dart';
import '../persistence/save_store.dart';
import '../persistence/save_store_factory.dart';
import '../stages/stage_catalog.dart';
import '../stages/stage_definition.dart';
import 'depthline_game_screen.dart';
import 'settings_screen.dart';
import 'title_screen.dart';

class DepthlineFleetApp extends StatefulWidget {
  const DepthlineFleetApp({super.key});

  @override
  State<DepthlineFleetApp> createState() => _DepthlineFleetAppState();
}

enum _AppScreen {
  title,
  settings,
  game,
}

class _DepthlineFleetAppState extends State<DepthlineFleetApp> {
  final SaveStore _saveStore = createPlatformSaveStore();
  GameAudioController? _titleAudio;

  PersistedState _persistedState = const PersistedState();
  _AppScreen _screen = _AppScreen.title;
  GameMode _selectedGameMode = GameMode.campaign;
  String _selectedStageId = StageCatalog.firstStage().id;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final PersistedState loadedState = await _saveStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _persistedState = loadedState;
      _loaded = true;
    });
    _startTitleMusic();
  }

  Future<void> _save(PersistedState state) async {
    setState(() {
      _persistedState = state;
    });
    await _saveStore.save(state);
  }

  void _selectStage(String stageId) {
    if (!_persistedState.saveData.isStageUnlocked(stageId)) {
      return;
    }
    _startTitleMusic();
    setState(() {
      _selectedStageId = stageId;
    });
  }

  void _selectGameMode(GameMode mode) {
    _startTitleMusic();
    setState(() {
      _selectedGameMode = mode;
    });
  }

  void _startGame() {
    _stopTitleMusic();
    final GameAudioController audio = GameAudioController(
      settings: _persistedState.settings,
    );
    unawaited(audio.warmUp());
    audio.play(GameAudioCue.start);
    setState(() {
      _screen = _AppScreen.game;
    });
  }

  void _openSettings() {
    _stopTitleMusic();
    setState(() {
      _screen = _AppScreen.settings;
    });
  }

  void _returnToTitle() {
    setState(() {
      _screen = _AppScreen.title;
    });
    _startTitleMusic();
  }

  void _handleSettingsChanged(GameSettings settings) {
    unawaited(_save(_persistedState.copyWith(settings: settings)));
    if (settings.musicEnabled) {
      _startTitleMusic(settings: settings);
    } else {
      _stopTitleMusic();
    }
  }

  void _startTitleMusic({GameSettings? settings}) {
    final GameSettings activeSettings = settings ?? _persistedState.settings;
    if (!activeSettings.musicEnabled || _screen != _AppScreen.title) {
      return;
    }
    _titleAudio?.stopMusic();
    final GameAudioController audio = GameAudioController(settings: activeSettings);
    _titleAudio = audio;
    unawaited(audio.warmUp());
    audio.startMusic(GameMusicTrack.title);
  }

  void _stopTitleMusic() {
    _titleAudio?.stopMusic();
    _titleAudio = null;
  }

  @override
  void dispose() {
    _stopTitleMusic();
    super.dispose();
  }

  void _handleSessionFinished(GameSessionState state, StageDefinition stage) {
    final GameSaveData saveData = _persistedState.saveData.recordResult(
      stageId: stage.id,
      score: state.score,
      cleared: state.status == GameStatus.cleared,
      scoreAttack: _selectedGameMode == GameMode.scoreAttack,
    );
    unawaited(_save(_persistedState.copyWith(saveData: saveData)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depthline Fleet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3BB2D0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF020B11),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_screen) {
      case _AppScreen.title:
        return TitleScreen(
          saveData: _persistedState.saveData,
          selectedGameMode: _selectedGameMode,
          selectedStageId: _selectedStageId,
          onGameModeSelected: _selectGameMode,
          onStageSelected: _selectStage,
          onStart: _startGame,
          onSettings: _openSettings,
        );
      case _AppScreen.settings:
        return SettingsScreen(
          settings: _persistedState.settings,
          onChanged: _handleSettingsChanged,
          onBack: _returnToTitle,
        );
      case _AppScreen.game:
        return DepthlineGameScreen(
          key: ValueKey<String>('game-${_selectedGameMode.name}-$_selectedStageId'),
          stageDefinition: _selectedGameMode == GameMode.scoreAttack
              ? StageCatalog.scoreAttackStageDefinition
              : StageCatalog.byId(_selectedStageId),
          gameMode: _selectedGameMode,
          settings: _persistedState.settings,
          onSessionFinished: _handleSessionFinished,
          onExitToTitle: _returnToTitle,
        );
    }
  }
}
