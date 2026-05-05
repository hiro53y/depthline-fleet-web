enum RadarContactType {
  submarine,
  depthCharge,
  powerup,
}

class RadarContact {
  const RadarContact({
    required this.type,
    required this.worldX,
    required this.worldY,
    this.active = true,
  });

  final RadarContactType type;
  final double worldX;
  final double worldY;
  final bool active;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RadarContact &&
        other.type == type &&
        other.worldX == worldX &&
        other.worldY == worldY &&
        other.active == active;
  }

  @override
  int get hashCode => Object.hash(type, worldX, worldY, active);
}
