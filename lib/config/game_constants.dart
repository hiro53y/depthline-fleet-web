class GameConstants {
  const GameConstants._();

  static const double logicalWidth = 1280;
  static const double logicalHeight = 720;

  static const double hudHeight = 64;
  static const double radarHeight = 64;
  static const double controlHeight = 96;
  static const double playTop = hudHeight;
  static const double playBottom = logicalHeight - radarHeight - controlHeight;
  static const double playHeight = playBottom - playTop;
  static const double waterlineY = 170;

  static const double playerSpeed = 340;
  static const double playerStartX = logicalWidth / 2;
  static const double playerY = waterlineY - 16;

  static const double depthChargeOffsetX = 36;
  static const double depthChargeAirAcceleration = 520;
  static const double depthChargeWaterAcceleration = 110;
  static const double depthChargeAirMaxSpeed = 420;
  static const double depthChargeWaterMaxSpeed = 230;
  static const double depthChargeSideCooldown = 0.35;

  static const int startingLives = 3;
  static const int scorePerSubmarine = 100;
  static const double playerInvulnerabilitySeconds = 1.0;
}
