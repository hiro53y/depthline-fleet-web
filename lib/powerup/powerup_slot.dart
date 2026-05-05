import 'powerup_type.dart';

class PowerupSlot {
  static const double rapidReloadDuration = 8;
  static const double shieldDuration = 10;

  PowerupType? _activeType;
  double _remaining = 0;

  bool get isActive => _activeType != null && _remaining > 0;
  bool get hasShield => _activeType == PowerupType.shield && isActive;
  double get remaining => isActive ? _remaining : 0;
  PowerupType? get activeType => isActive ? _activeType : null;
  String get label => activeType?.label ?? 'NONE';

  double get cooldownMultiplier {
    return _activeType == PowerupType.rapidReload && isActive ? 0.48 : 1.0;
  }

  void update(double dt) {
    if (!isActive) {
      return;
    }
    _remaining -= dt;
    if (_remaining <= 0) {
      reset();
    }
  }

  void activate(PowerupType type) {
    switch (type) {
      case PowerupType.rapidReload:
        _activeType = PowerupType.rapidReload;
        _remaining = rapidReloadDuration;
        break;
      case PowerupType.shield:
        _activeType = PowerupType.shield;
        _remaining = shieldDuration;
        break;
      case PowerupType.repair:
        reset();
        break;
    }
  }

  bool consumeShield() {
    if (!hasShield) {
      return false;
    }
    reset();
    return true;
  }

  void reset() {
    _activeType = null;
    _remaining = 0;
  }
}
