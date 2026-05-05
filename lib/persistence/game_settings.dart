class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.ambientEnabled = true,
    this.effectsEnabled = true,
    this.showTouchZones = true,
  });

  factory GameSettings.fromJson(Map<String, Object?> json) {
    return GameSettings(
      soundEnabled: _readBool(json['soundEnabled']),
      musicEnabled: _readBool(json['musicEnabled']),
      ambientEnabled: _readBool(json['ambientEnabled']),
      effectsEnabled: _readBool(json['effectsEnabled']),
      showTouchZones: _readBool(json['showTouchZones']),
    );
  }

  final bool soundEnabled;
  final bool musicEnabled;
  final bool ambientEnabled;
  final bool effectsEnabled;
  final bool showTouchZones;

  static bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final String normalized = value.toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    return true;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'soundEnabled': soundEnabled,
      'musicEnabled': musicEnabled,
      'ambientEnabled': ambientEnabled,
      'effectsEnabled': effectsEnabled,
      'showTouchZones': showTouchZones,
    };
  }

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? ambientEnabled,
    bool? effectsEnabled,
    bool? showTouchZones,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      ambientEnabled: ambientEnabled ?? this.ambientEnabled,
      effectsEnabled: effectsEnabled ?? this.effectsEnabled,
      showTouchZones: showTouchZones ?? this.showTouchZones,
    );
  }
}
