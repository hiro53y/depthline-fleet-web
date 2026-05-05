import 'game_save_data.dart';
import 'game_settings.dart';

class PersistedState {
  const PersistedState({
    this.saveData = const GameSaveData(),
    this.settings = const GameSettings(),
  });

  factory PersistedState.fromJson(Map<String, Object?> json) {
    final Object? saveJson = json['saveData'];
    final Object? settingsJson = json['settings'];
    return PersistedState(
      saveData: saveJson is Map
          ? GameSaveData.fromJson(Map<String, Object?>.from(saveJson))
          : const GameSaveData(),
      settings: settingsJson is Map
          ? GameSettings.fromJson(Map<String, Object?>.from(settingsJson))
          : const GameSettings(),
    );
  }

  final GameSaveData saveData;
  final GameSettings settings;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'saveData': saveData.toJson(),
      'settings': settings.toJson(),
    };
  }

  PersistedState copyWith({
    GameSaveData? saveData,
    GameSettings? settings,
  }) {
    return PersistedState(
      saveData: saveData ?? this.saveData,
      settings: settings ?? this.settings,
    );
  }
}
