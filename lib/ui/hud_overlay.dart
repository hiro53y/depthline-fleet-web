import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gameplay/game_session_state.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    required this.sessionListenable,
    required this.stageName,
    super.key,
  });

  final ValueListenable<GameSessionState> sessionListenable;
  final String stageName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF061019),
        border: Border(
          bottom: BorderSide(color: Color(0x6638D7FF), width: 1.5),
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    const Color(0xFF0A2230),
                    const Color(0xFF071019),
                    const Color(0xFF102333).withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 7,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF60F4FF), Color(0xFFFFC86D)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 10,
            child: Container(height: 1, color: const Color(0x44BFF7FF)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 9, 22, 9),
            child: ValueListenableBuilder<GameSessionState>(
              valueListenable: sessionListenable,
              builder: (BuildContext context, GameSessionState state, _) {
                return Row(
                  children: <Widget>[
                    _StageBadge(stageName: stageName),
                    const Spacer(),
                    _HudChip(
                      label: 'SCORE',
                      value: state.score.toString(),
                      accent: const Color(0xFFFFC86D),
                    ),
                    const SizedBox(width: 12),
                    _HudChip(
                      label: 'LIVES',
                      value: state.lives.toString(),
                      accent: const Color(0xFF77FFB7),
                    ),
                    const SizedBox(width: 12),
                    _HudChip(
                      label: state.totalWaves == 0 ? 'LEVEL' : 'WAVE',
                      value: state.totalWaves == 0
                          ? state.currentWave.toString()
                          : '${state.currentWave}/${state.totalWaves}',
                      accent: const Color(0xFF8DEAFF),
                    ),
                    const SizedBox(width: 12),
                    _HudChip(
                      label: 'POWER',
                      value: state.powerupLabel == 'NONE'
                          ? '-'
                          : '${state.powerupLabel} ${state.powerupSecondsRemaining.toStringAsFixed(1)}',
                      accent: const Color(0xFFFF86D8),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stageName});

  final String stageName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: <Color>[Color(0xFF7EFAFF), Color(0xFF1E6980)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF62ECFF).withOpacity(0.28),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Icon(Icons.radar, color: Color(0xFF061019), size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              stageName,
              style: const TextStyle(
                color: Color(0xFFEAFBFF),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'FLEET OPERATIONS',
              style: TextStyle(
                color: Color(0xFF7BBFD0),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0x66112B3B), Color(0x9910212E)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.58)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withOpacity(0.13),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 5,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: <BoxShadow>[
                BoxShadow(color: accent.withOpacity(0.55), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9AD3E3),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.7,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF4FBFF),
                  fontSize: 20,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
