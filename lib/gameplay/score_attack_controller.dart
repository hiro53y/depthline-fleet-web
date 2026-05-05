import 'dart:math' as math;

import 'wave_definition.dart';

class ScoreAttackController {
  ScoreAttackController({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  int _level = 1;
  int _spawnedAtLevel = 0;
  int _resolvedAtLevel = 0;
  int _enemyTarget = 5;
  double _timeUntilNextSpawn = 0.45;

  int get level => _level;

  WaveDefinition get currentWave => _buildWaveDefinition();

  void markEnemyResolved() {
    _resolvedAtLevel += 1;
    if (_resolvedAtLevel >= _enemyTarget) {
      _level += 1;
      _spawnedAtLevel = 0;
      _resolvedAtLevel = 0;
      _enemyTarget = _enemyTargetForLevel();
      _timeUntilNextSpawn = math.max(0.35, 0.9 - (_level * 0.035));
    }
  }

  void update(
    double dt, {
    required int activeEnemies,
    required void Function(WaveDefinition wave) onSpawn,
  }) {
    final int activeCap = math.min(7, 2 + (_level ~/ 2));
    int activeCount = activeEnemies;
    if (activeCount >= activeCap || _spawnedAtLevel >= _enemyTarget) {
      return;
    }

    _timeUntilNextSpawn -= dt;
    while (_timeUntilNextSpawn <= 0 && activeCount < activeCap) {
      onSpawn(_buildWaveDefinition());
      activeCount += 1;
      _spawnedAtLevel += 1;
      _timeUntilNextSpawn += _nextInterval();
      break;
    }
  }

  WaveDefinition _buildWaveDefinition() {
    final double intensity = _level.toDouble();
    final double speedBase = 120 + (intensity * 8);
    final List<int> lanes = <int>[0, 1, 2]..shuffle(_random);
    return WaveDefinition(
      enemyCount: _enemyTarget,
      spawnInterval: _nextInterval(),
      minSpeed: speedBase + _random.nextDouble() * 24,
      maxSpeed: speedBase + 38 + (_random.nextDouble() * 42),
      torpedoCooldown: math.max(1.35, 2.8 - (intensity * 0.06)),
      laneIndices: lanes.take(1 + _random.nextInt(3)).toList(growable: false),
    );
  }

  int _enemyTargetForLevel() {
    return math.min(24, 4 + _level + _random.nextInt(3));
  }

  double _nextInterval() {
    final double base = math.max(0.55, 1.35 - (_level * 0.045));
    return base + (_random.nextDouble() * 0.38);
  }
}
