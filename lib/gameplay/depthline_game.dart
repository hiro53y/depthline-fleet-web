import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/audio_backend.dart';
import '../audio/game_audio_controller.dart';
import '../config/game_constants.dart';
import '../enemy/enemy_spawner.dart';
import '../enemy/submarine_enemy.dart';
import '../enemy/torpedo.dart';
import '../entities/player_battleship.dart';
import '../persistence/game_settings.dart';
import '../powerup/powerup_pickup.dart';
import '../powerup/powerup_slot.dart';
import '../powerup/powerup_type.dart';
import '../radar/radar_contact.dart';
import '../radar/world_to_radar_mapper.dart';
import '../stages/sea_backdrop_renderer.dart';
import '../stages/stage_definition.dart';
import '../weapons/depth_charge.dart';
import 'bubble_particle.dart';
import 'collision_utils.dart';
import 'game_mode.dart';
import 'game_session_state.dart';
import 'score_attack_controller.dart';
import 'wave_controller.dart';
import 'wave_definition.dart';
import 'weapon_side.dart';

class DepthlineGame extends Game {
  DepthlineGame({
    required StageDefinition stageDefinition,
    GameMode gameMode = GameMode.campaign,
    GameSettings settings = const GameSettings(),
  })
      : _stageDefinition = stageDefinition,
        _gameMode = gameMode,
        _settings = settings,
        _audio = GameAudioController(settings: settings),
        _player = PlayerBattleship(
          startX: stageDefinition.playerStartX,
          startY: GameConstants.playerY,
        ),
        _waveController = WaveController(stageDefinition.waves),
        _enemySpawner = EnemySpawner(stageDefinition),
        sessionNotifier = ValueNotifier<GameSessionState>(
          GameSessionState.initial(
            totalWaves: gameMode == GameMode.scoreAttack ? 0 : stageDefinition.waves.length,
            lives: GameConstants.startingLives,
          ),
        ),
        radarNotifier = ValueNotifier<List<RadarContact>>(const <RadarContact>[]) {
    _radarMapper = WorldToRadarMapper(
      worldWidth: stageDefinition.worldWidth,
      waterlineY: stageDefinition.waterlineY,
      playBottomY: stageDefinition.playBottomY,
      radarWidth: GameConstants.logicalWidth,
      radarHeight: GameConstants.radarHeight,
    );
    _publishRadarContacts();
  }

  final StageDefinition _stageDefinition;
  final GameMode _gameMode;
  final GameSettings _settings;
  final GameAudioController _audio;
  final PlayerBattleship _player;
  final WaveController _waveController;
  final ScoreAttackController _scoreAttackController = ScoreAttackController();
  final EnemySpawner _enemySpawner;

  final List<DepthCharge> _depthCharges = <DepthCharge>[];
  final List<SubmarineEnemy> _submarines = <SubmarineEnemy>[];
  final List<Torpedo> _torpedoes = <Torpedo>[];
  final List<PowerupPickup> _powerups = <PowerupPickup>[];
  final List<BubbleParticle> _bubbles = <BubbleParticle>[];
  final PowerupSlot _powerupSlot = PowerupSlot();
  final math.Random _random = math.Random();

  final ValueNotifier<GameSessionState> sessionNotifier;
  final ValueNotifier<List<RadarContact>> radarNotifier;

  late final WorldToRadarMapper _radarMapper;
  late final SeaBackdropRenderer _backdropRenderer = SeaBackdropRenderer(_stageDefinition);

  double _leftCooldown = 0;
  double _rightCooldown = 0;
  double _bubbleTimer = 0;
  double _ambientTimer = 1.2;
  bool _endCuePlayed = false;

  WorldToRadarMapper get radarMapper => _radarMapper;
  GameSessionState get sessionState => sessionNotifier.value;
  String get stageName =>
      _gameMode == GameMode.scoreAttack ? 'Score Attack' : _stageDefinition.name;

  void startMusic() {
    unawaited(_audio.warmUp());
    _audio.startMusic(_musicTrackForSession());
  }

  @override
  Color backgroundColor() => const Color(0xFF06151E);

  @override
  void update(double dt) {
    _leftCooldown = math.max(0, _leftCooldown - dt);
    _rightCooldown = math.max(0, _rightCooldown - dt);

    if (!sessionNotifier.value.isPlaying) {
      _publishRadarContacts();
      return;
    }

    _updateAmbient(dt);
    _powerupSlot.update(dt);
    _publishPowerupState();

    final int activeEnemies =
        _submarines.where((SubmarineEnemy enemy) => !enemy.isRemoved).length;
    if (_gameMode == GameMode.scoreAttack) {
      _scoreAttackController.update(
        dt,
        activeEnemies: activeEnemies,
        onSpawn: _spawnSubmarine,
      );
      if (sessionNotifier.value.currentWave != _scoreAttackController.level) {
        _updateSession(
          sessionNotifier.value.copyWith(currentWave: _scoreAttackController.level),
        );
      }
    } else {
      _waveController.update(
        dt,
        activeEnemies: activeEnemies,
        onSpawn: _spawnSubmarine,
      );
    }

    _player.update(dt, minX: 0, maxX: _stageDefinition.worldWidth);

    for (final DepthCharge charge in _depthCharges) {
      charge.update(
        dt,
        waterlineY: _stageDefinition.waterlineY,
        playBottomY: _stageDefinition.playBottomY,
      );
    }
    for (final SubmarineEnemy enemy in _submarines) {
      enemy.update(dt);
    }
    for (final Torpedo torpedo in _torpedoes) {
      torpedo.update(dt);
    }
    for (final PowerupPickup powerup in _powerups) {
      powerup.update(dt);
    }
    for (final BubbleParticle bubble in _bubbles) {
      bubble.update(dt);
    }
    _spawnBubbles(dt);

    _handleCollisions();
    _handleEscapedSubmarines();
    _cleanupRemovedEntities();
    _spawnEnemyTorpedoes();
    _handleWaveProgress();
    _publishRadarContacts();
  }

  @override
  void render(Canvas canvas) {
    _backdropRenderer.render(canvas);

    for (final BubbleParticle bubble in _bubbles) {
      bubble.render(canvas);
    }
    for (final DepthCharge charge in _depthCharges) {
      charge.render(canvas);
    }
    for (final PowerupPickup powerup in _powerups) {
      powerup.render(canvas);
    }
    for (final Torpedo torpedo in _torpedoes) {
      torpedo.render(canvas);
    }
    for (final SubmarineEnemy enemy in _submarines) {
      enemy.render(canvas);
    }
    _player.render(canvas);
    if (_powerupSlot.hasShield) {
      _renderShield(canvas);
    }
  }

  void setMovementDirection(double direction) {
    if (!sessionNotifier.value.isPlaying) {
      return;
    }
    _player.setMovementDirection(direction);
  }

  void stopMovement() {
    _player.stop();
  }

  void tryDropDepthCharge(WeaponSide side) {
    if (!sessionNotifier.value.isPlaying) {
      return;
    }

    final bool sideReady = side == WeaponSide.left ? _leftCooldown <= 0 : _rightCooldown <= 0;
    if (!sideReady) {
      return;
    }

    _depthCharges.add(
      DepthCharge(startPosition: _player.dropPointFor(side)),
    );
    unawaited(_audio.warmUp());
    _audio.play(GameAudioCue.drop);

    final double cooldown =
        GameConstants.depthChargeSideCooldown * _powerupSlot.cooldownMultiplier;
    if (side == WeaponSide.left) {
      _leftCooldown = cooldown;
    } else {
      _rightCooldown = cooldown;
    }
  }

  void _spawnSubmarine(WaveDefinition wave) {
    _submarines.add(_enemySpawner.spawn(wave));
  }

  void _spawnEnemyTorpedoes() {
    for (final SubmarineEnemy enemy in _submarines) {
      if (enemy.isRemoved) {
        continue;
      }
      final Torpedo? torpedo = enemy.tryFire(_player.position.dx);
      if (torpedo != null) {
        _torpedoes.add(torpedo);
      }
    }
  }

  void _handleCollisions() {
    for (final DepthCharge charge in _depthCharges) {
      if (charge.isRemoved) {
        continue;
      }

      for (final SubmarineEnemy enemy in _submarines) {
        if (enemy.isRemoved) {
          continue;
        }

        if (rectsOverlap(charge.bounds, enemy.bounds)) {
          charge.isRemoved = true;
          enemy.isRemoved = true;
          _markEnemyResolved();
          _maybeSpawnPowerup(enemy.position);
          _audio.play(GameAudioCue.hit);
          _updateSession(
            sessionNotifier.value.copyWith(
              score: sessionNotifier.value.score + GameConstants.scorePerSubmarine,
            ),
          );
          break;
        }
      }
    }

    if (!_player.isInvulnerable) {
      for (final Torpedo torpedo in _torpedoes) {
        if (torpedo.isRemoved) {
          continue;
        }

        if (rectsOverlap(torpedo.bounds, _player.bounds)) {
          torpedo.isRemoved = true;
          if (_powerupSlot.consumeShield()) {
            _audio.play(GameAudioCue.powerup);
            _publishPowerupState();
            break;
          }
          _player.triggerInvulnerability();
          _loseLife();
          break;
        }
      }
    }

    for (final PowerupPickup powerup in _powerups) {
      if (powerup.isRemoved) {
        continue;
      }

      if (rectsOverlap(powerup.bounds, _player.bounds)) {
        powerup.isRemoved = true;
        _collectPowerup(powerup.type);
      }
    }
  }

  void _handleEscapedSubmarines() {
    bool lifeLostThisPass = false;
    for (final SubmarineEnemy enemy in _submarines) {
      if (enemy.isRemoved) {
        continue;
      }

      if (enemy.hasEscaped(_stageDefinition.worldWidth)) {
        enemy.isRemoved = true;
        _markEnemyResolved();
        if (!lifeLostThisPass) {
          _loseLife();
          lifeLostThisPass = true;
        }
      }
    }
  }

  void _cleanupRemovedEntities() {
    _depthCharges.removeWhere((DepthCharge charge) => charge.isRemoved);
    _submarines.removeWhere((SubmarineEnemy enemy) => enemy.isRemoved);
    _torpedoes.removeWhere((Torpedo torpedo) => torpedo.isRemoved);
    _powerups.removeWhere((PowerupPickup powerup) => powerup.isRemoved);
    _bubbles.removeWhere((BubbleParticle bubble) => bubble.isExpired);
  }

  void _handleWaveProgress() {
    if (!sessionNotifier.value.isPlaying) {
      return;
    }
    if (_gameMode == GameMode.scoreAttack) {
      return;
    }

    final WaveControllerEvent event = _waveController.evaluate(
      activeEnemies: _submarines.length,
    );

    switch (event) {
      case WaveControllerEvent.none:
        break;
      case WaveControllerEvent.waveAdvanced:
        _updateSession(
          sessionNotifier.value.copyWith(currentWave: _waveController.currentWaveNumber),
        );
        break;
      case WaveControllerEvent.stageCleared:
        _player.stop();
        _playEndCue(GameAudioCue.clear);
        _updateSession(
          sessionNotifier.value.copyWith(
            currentWave: _waveController.totalWaves,
            status: GameStatus.cleared,
          ),
        );
        break;
    }
  }

  void _markEnemyResolved() {
    if (_gameMode == GameMode.scoreAttack) {
      _scoreAttackController.markEnemyResolved();
      return;
    }
    _waveController.markEnemyResolved();
  }

  void _loseLife() {
    final GameSessionState state = sessionNotifier.value;
    if (!state.isPlaying) {
      return;
    }

    final int remainingLives = math.max(0, state.lives - 1);
    if (remainingLives == 0) {
      _player.stop();
      _playEndCue(GameAudioCue.gameOver);
      _updateSession(
        state.copyWith(lives: 0, status: GameStatus.gameOver),
      );
      return;
    }

    _audio.play(GameAudioCue.damage);
    _updateSession(state.copyWith(lives: remainingLives));
  }

  void _updateSession(GameSessionState nextState) {
    if (sessionNotifier.value == nextState) {
      return;
    }
    sessionNotifier.value = nextState;
  }

  void _publishRadarContacts() {
    final List<RadarContact> nextContacts = <RadarContact>[
      for (final SubmarineEnemy enemy in _submarines)
        RadarContact(
          type: RadarContactType.submarine,
          worldX: enemy.position.dx,
          worldY: enemy.position.dy,
        ),
      for (final DepthCharge charge in _depthCharges)
        RadarContact(
          type: RadarContactType.depthCharge,
          worldX: charge.position.dx,
          worldY: charge.position.dy,
        ),
      for (final PowerupPickup powerup in _powerups)
        RadarContact(
          type: RadarContactType.powerup,
          worldX: powerup.position.dx,
          worldY: powerup.position.dy,
        ),
    ];

    if (listEquals(radarNotifier.value, nextContacts)) {
      return;
    }

    radarNotifier.value = nextContacts;
  }

  void _maybeSpawnPowerup(Offset position) {
    if (_random.nextDouble() > GameConstants.powerupDropChance) {
      return;
    }
    final PowerupType type = PowerupType.values[_random.nextInt(PowerupType.values.length)];
    _powerups.add(PowerupPickup(type: type, startPosition: position));
  }

  void _collectPowerup(PowerupType type) {
    _audio.play(GameAudioCue.powerup);
    if (type == PowerupType.repair) {
      final GameSessionState state = sessionNotifier.value;
      _updateSession(
        state.copyWith(lives: math.min(GameConstants.maxLives, state.lives + 1)),
      );
      return;
    }
    _powerupSlot.activate(type);
    _publishPowerupState();
  }

  void _publishPowerupState() {
    final double roundedRemaining =
        (_powerupSlot.remaining * 10).roundToDouble() / 10;
    _updateSession(
      sessionNotifier.value.copyWith(
        powerupLabel: _powerupSlot.label,
        powerupSecondsRemaining: roundedRemaining,
      ),
    );
  }

  void _spawnBubbles(double dt) {
    if (!_settings.effectsEnabled) {
      return;
    }
    _bubbleTimer -= dt;
    if (_bubbleTimer > 0) {
      return;
    }
    _bubbleTimer = GameConstants.bubbleSpawnInterval;

    for (final DepthCharge charge in _depthCharges) {
      if (!charge.isInWater || charge.isRemoved) {
        continue;
      }
      final double drift = (_random.nextDouble() - 0.5) * 26;
      _bubbles.add(
        BubbleParticle(
          position: charge.position.translate((_random.nextDouble() - 0.5) * 12, 2),
          velocity: Offset(drift, -36 - (_random.nextDouble() * 34)),
          radius: 3 + (_random.nextDouble() * 5),
          lifetime: 0.7 + (_random.nextDouble() * 0.45),
        ),
      );
    }
  }

  void _updateAmbient(double dt) {
    _ambientTimer -= dt;
    if (_ambientTimer > 0) {
      return;
    }
    _ambientTimer = GameConstants.ambientPingInterval;
    _audio.play(GameAudioCue.ambient);
  }

  void _playEndCue(GameAudioCue cue) {
    if (_endCuePlayed) {
      return;
    }
    _endCuePlayed = true;
    _audio.stopMusic();
    _audio.play(cue);
  }

  void _renderShield(Canvas canvas) {
    final Paint shieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF89E8FF).withOpacity(0.72);
    canvas.drawOval(
      Rect.fromCenter(
        center: _player.position.translate(0, 4),
        width: 176,
        height: 64,
      ),
      shieldPaint,
    );
  }

  void disposeState() {
    _audio.stopMusic();
    sessionNotifier.dispose();
    radarNotifier.dispose();
  }

  GameMusicTrack _musicTrackForSession() {
    if (_gameMode == GameMode.scoreAttack) {
      return GameMusicTrack.scoreAttack;
    }
    return switch (_stageDefinition.stageNumber) {
      1 => GameMusicTrack.stage1,
      2 => GameMusicTrack.stage2,
      _ => GameMusicTrack.stage3,
    };
  }
}
