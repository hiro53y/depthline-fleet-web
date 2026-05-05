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
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      musicEnabled: json['musicEnabled'] as bool? ?? true,
      ambientEnabled: json['ambientEnabled'] as bool? ?? true,
      effectsEnabled: json['effectsEnabled'] as bool? ?? true,
      showTouchZones: json['showTouchZones'] as bool? ?? true,
    );
  }

  final bool soundEnabled;
  final bool musicEnabled;
  final bool ambientEnabled;
  final bool effectsEnabled;
  final bool showTouchZones;

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
