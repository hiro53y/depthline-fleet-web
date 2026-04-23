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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF071018),
            Color(0xCC0C1E2A),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: ValueListenableBuilder<GameSessionState>(
          valueListenable: sessionListenable,
          builder: (BuildContext context, GameSessionState state, _) {
            return Row(
              children: <Widget>[
                Text(
                  stageName,
                  style: const TextStyle(
                    color: Color(0xFFDBF3FB),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                _HudChip(label: 'SCORE', value: state.score.toString()),
                const SizedBox(width: 12),
                _HudChip(label: 'LIVES', value: state.lives.toString()),
                const SizedBox(width: 12),
                _HudChip(label: 'WAVE', value: '${state.currentWave}/${state.totalWaves}'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x44132B37),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x663BB2D0)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AD3E3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF4FBFF),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
