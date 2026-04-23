import 'dart:math' as math;

class WaveDefinition {
  const WaveDefinition({
    required this.enemyCount,
    required this.spawnInterval,
    required this.minSpeed,
    required this.maxSpeed,
    required this.torpedoCooldown,
    required this.laneIndices,
  });

  final int enemyCount;
  final double spawnInterval;
  final double minSpeed;
  final double maxSpeed;
  final double torpedoCooldown;
  final List<int> laneIndices;

  double nextSpeed(math.Random random) {
    final double factor = random.nextDouble();
    return minSpeed + ((maxSpeed - minSpeed) * factor);
  }

  int nextLaneIndex(math.Random random) {
    if (laneIndices.length == 1) {
      return laneIndices.first;
    }
    return laneIndices[random.nextInt(laneIndices.length)];
  }
}
