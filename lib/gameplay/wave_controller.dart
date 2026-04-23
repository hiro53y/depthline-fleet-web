import 'wave_definition.dart';

enum WaveControllerEvent {
  none,
  waveAdvanced,
  stageCleared,
}

class WaveController {
  WaveController(this._waves) {
    _resetCurrentWave(initialWave: true);
  }

  final List<WaveDefinition> _waves;

  int _currentWaveIndex = 0;
  int _spawnedInWave = 0;
  int _resolvedInWave = 0;
  double _timeUntilNextSpawn = 0.7;
  bool _stageCleared = false;

  int get currentWaveNumber => _currentWaveIndex + 1;
  int get totalWaves => _waves.length;
  bool get stageCleared => _stageCleared;
  WaveDefinition get currentWave => _waves[_currentWaveIndex];

  void markEnemyResolved() {
    _resolvedInWave += 1;
  }

  WaveControllerEvent update(
    double dt, {
    required int activeEnemies,
    required void Function(WaveDefinition wave) onSpawn,
  }) {
    final WaveControllerEvent event = evaluate(activeEnemies: activeEnemies);
    if (_stageCleared) {
      return event;
    }

    if (_spawnedInWave >= currentWave.enemyCount) {
      return event;
    }

    _timeUntilNextSpawn -= dt;
    while (_timeUntilNextSpawn <= 0 && _spawnedInWave < currentWave.enemyCount) {
      onSpawn(currentWave);
      _spawnedInWave += 1;
      _timeUntilNextSpawn += currentWave.spawnInterval;
    }

    return event;
  }

  WaveControllerEvent evaluate({required int activeEnemies}) {
    if (_stageCleared) {
      return WaveControllerEvent.stageCleared;
    }

    final bool waveDone = _spawnedInWave == currentWave.enemyCount &&
        _resolvedInWave == currentWave.enemyCount &&
        activeEnemies == 0;
    if (!waveDone) {
      return WaveControllerEvent.none;
    }

    if (_currentWaveIndex == _waves.length - 1) {
      _stageCleared = true;
      return WaveControllerEvent.stageCleared;
    }

    _currentWaveIndex += 1;
    _resetCurrentWave();
    return WaveControllerEvent.waveAdvanced;
  }

  void reset() {
    _currentWaveIndex = 0;
    _stageCleared = false;
    _resetCurrentWave(initialWave: true);
  }

  void _resetCurrentWave({bool initialWave = false}) {
    _spawnedInWave = 0;
    _resolvedInWave = 0;
    _timeUntilNextSpawn = initialWave ? 0.7 : 1.0;
  }
}
