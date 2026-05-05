import 'package:flutter/material.dart';

import '../persistence/game_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.onChanged,
    required this.onBack,
    super.key,
  });

  final GameSettings settings;
  final ValueChanged<GameSettings> onChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020B11),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton.filledTonal(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: '戻る',
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'SETTINGS',
                          style: TextStyle(
                            color: Color(0xFFF2FBFF),
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SettingSwitch(
                      icon: Icons.volume_up_rounded,
                      title: '効果音',
                      subtitle: '投下、命中、被弾、クリアの音を鳴らす',
                      value: settings.soundEnabled,
                      onChanged: (bool value) {
                        onChanged(settings.copyWith(soundEnabled: value));
                      },
                    ),
                    _SettingSwitch(
                      icon: Icons.music_note_rounded,
                      title: '音楽',
                      subtitle: 'ステージごとの生成BGMを鳴らす',
                      value: settings.musicEnabled,
                      onChanged: (bool value) {
                        onChanged(settings.copyWith(musicEnabled: value));
                      },
                    ),
                    _SettingSwitch(
                      icon: Icons.graphic_eq_rounded,
                      title: 'ソナー音',
                      subtitle: 'プレイ中の周期的な低音パルスを鳴らす',
                      value: settings.ambientEnabled,
                      onChanged: settings.soundEnabled
                          ? (bool value) {
                              onChanged(settings.copyWith(ambientEnabled: value));
                            }
                          : null,
                    ),
                    _SettingSwitch(
                      icon: Icons.bubble_chart_rounded,
                      title: '泡エフェクト',
                      subtitle: '爆雷の沈降に合わせた泡を表示する',
                      value: settings.effectsEnabled,
                      onChanged: (bool value) {
                        onChanged(settings.copyWith(effectsEnabled: value));
                      },
                    ),
                    _SettingSwitch(
                      icon: Icons.touch_app_rounded,
                      title: 'タッチガイド',
                      subtitle: '移動領域の左右ガイドを薄く表示する',
                      value: settings.showTouchZones,
                      onChanged: (bool value) {
                        onChanged(settings.copyWith(showTouchZones: value));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1B25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x443BB2D0)),
        ),
        child: SwitchListTile(
          secondary: Icon(icon, color: const Color(0xFF9DE9FF)),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF2FBFF),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9BCFDC)),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF6FE7FF),
        ),
      ),
    );
  }
}
