import 'dart:ui';

class WorldToRadarMapper {
  const WorldToRadarMapper({
    required this.worldWidth,
    required this.waterlineY,
    required this.playBottomY,
    required this.radarWidth,
    required this.radarHeight,
    this.horizontalMargin = 12,
    this.verticalMargin = 10,
  });

  final double worldWidth;
  final double waterlineY;
  final double playBottomY;
  final double radarWidth;
  final double radarHeight;
  final double horizontalMargin;
  final double verticalMargin;

  Offset project({
    required double worldX,
    required double worldY,
  }) {
    final double usableWidth = radarWidth - (horizontalMargin * 2);
    final double usableHeight = radarHeight - (verticalMargin * 2);
    final double depthRange = playBottomY - waterlineY;

    final double normalizedX = (worldX / worldWidth).clamp(0.0, 1.0);
    final double normalizedDepth =
        ((worldY - waterlineY) / depthRange).clamp(0.0, 1.0);

    return Offset(
      horizontalMargin + (usableWidth * normalizedX),
      verticalMargin + (usableHeight * normalizedDepth),
    );
  }
}
