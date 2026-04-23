import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/game_constants.dart';
import '../enemy/enemy_spawner.dart';
import '../enemy/submarine_enemy.dart';
import '../enemy/torpedo.dart';
import '../entities/player_battleship.dart';
import '../radar/radar_contact.dart';
import '../radar/world_to_radar_mapper.dart';
import '../stages/sea_backdrop_renderer.dart';
import '../stages/stage_definition.dart';
import '../weapons/depth_charge.dart';
import 'collision_utils.dart';
import 'game_session_state.dart';
import 'wave_controller.dart';
import 'weapon_side.dart';

class DepthlineGame extends Game {
  DepthlineGame({required StageDefinition stageDefinition})
      : _stageDefinition = stageDefinition,
        _player = PlayerBattleship(
          startX: stageDefinition.playerStartX,
          startY: GameConstants.playerY,
        ),
        _waveController = WaveController(stageDefinition.waves),
        _enemySpawner = EnemySpawner(stageDefinition),
        sessionNotifier = ValueNotifier<GameSessionState>(
          GameSessionState.initial(
            totalWaves: stageDefinition.waves.length,
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
  final PlayerBattleship _player;
  final WaveController _waveController;
  final EnemySpawner _enemySpawner;

  final List<DepthCharge> _depthCharges = <DepthCharge>[];
  final List<SubmarineEnemy> _submarines = <SubmarineEnemy>[];
  final List<Torpedo> _torpedoes = <Torpedo>[];

  final ValueNotifier<GameSessionState> sessionNotifier;
  final ValueNotifier<List<RadarContact>> radarNotifier;

  late final WorldToRadarMapper _radarMapper;
  late final SeaBackdropRenderer _backdropRenderer = SeaBackdropRenderer(_stageDefinition);

  double _leftCooldown = 0;
  double _rightCooldown = 0;

  WorldToRadarMapper get radarMapper => _radarMapper;
  GameSessionState get sessionState => sessionNotifier.value;
  String get stageName => _stageDefinition.name;

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

    _waveController.update(
      dt,
      activeEnemies: _submarines.where((SubmarineEnemy enemy) => !enemy.isRemoved).length,
      onSpawn: (_) => _spawnSubmarine(),
    );

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

    for (final DepthCharge charge in _depthCharges) {
      charge.render(canvas);
    }
    for (final Torpedo torpedo in _torpedoes) {
      torpedo.render(canvas);
    }
    for (final SubmarineEnemy enemy in _submarines) {
      enemy.render(canvas);
    }
    _player.render(canvas);
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

    if (side == WeaponSide.left) {
      _leftCooldown = GameConstants.depthChargeSideCooldown;
    } else {
      _rightCooldown = GameConstants.depthChargeSideCooldown;
    }
  }

  void _spawnSubmarine() {
    _submarines.add(_enemySpawner.spawn(_waveController.currentWave));
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
          _waveController.markEnemyResolved();
          _updateSession(
            sessionNotifier.value.copyWith(
              score: sessionNotifier.value.score + GameConstants.scorePerSubmarine,
            ),
          );
          break;
        }
      }
    }

    if (_player.isInvulnerable) {
      return;
    }

    for (final Torpedo torpedo in _torpedoes) {
      if (torpedo.isRemoved) {
        continue;
      }

      if (rectsOverlap(torpedo.bounds, _player.bounds)) {
        torpedo.isRemoved = true;
        _player.triggerInvulnerability();
        _loseLife();
        break;
      }
    }
  }

  void _handleEscapedSubmarines() {
    for (final SubmarineEnemy enemy in _submarines) {
      if (enemy.isRemoved) {
        continue;
      }

      if (enemy.hasEscaped(_stageDefinition.worldWidth)) {
        enemy.isRemoved = true;
        _waveController.markEnemyResolved();
        _loseLife();
      }
    }
  }

  void _cleanupRemovedEntities() {
    _depthCharges.removeWhere((DepthCharge charge) => charge.isRemoved);
    _submarines.removeWhere((SubmarineEnemy enemy) => enemy.isRemoved);
    _torpedoes.removeWhere((Torpedo torpedo) => torpedo.isRemoved);
  }

  void _handleWaveProgress() {
    if (!sessionNotifier.value.isPlaying) {
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
        _updateSession(
          sessionNotifier.value.copyWith(
            currentWave: _waveController.totalWaves,
            status: GameStatus.cleared,
          ),
        );
        break;
    }
  }

  void _loseLife() {
    final GameSessionState state = sessionNotifier.value;
    if (!state.isPlaying) {
      return;
    }

    final int remainingLives = math.max(0, state.lives - 1);
    if (remainingLives == 0) {
      _player.stop();
      _updateSession(
        state.copyWith(lives: 0, status: GameStatus.gameOver),
      );
      return;
    }

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
    ];

    if (listEquals(radarNotifier.value, nextContacts)) {
      return;
    }

    radarNotifier.value = nextContacts;
  }

  void disposeState() {
    sessionNotifier.dispose();
    radarNotifier.dispose();
  }
}
