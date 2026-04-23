import 'package:flutter/material.dart';

import '../gameplay/game_session_state.dart';

class SessionOverlay extends StatelessWidget {
  const SessionOverlay({
    required this.sessionListenable,
    required this.onRetry,
    super.key,
  });

  final ValueListenable<GameSessionState> sessionListenable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameSessionState>(
      valueListenable: sessionListenable,
      builder: (BuildContext context, GameSessionState state, _) {
        if (state.isPlaying) {
          return const SizedBox.shrink();
        }

        final bool cleared = state.status == GameStatus.cleared;
        return ColoredBox(
          color: const Color(0xB2071018),
          child: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1A24),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x773BB2D0), width: 1.5),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    cleared ? 'STAGE CLEAR' : 'GAME OVER',
                    style: const TextStyle(
                      color: Color(0xFFE6F8FF),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    cleared
                        ? '海域制圧完了。次の海域へ備えてください。'
                        : '艦隊が壊滅しました。海域を再挑戦しますか。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFACD9E8),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'SCORE ${state.score}',
                    style: const TextStyle(
                      color: Color(0xFFF9C97B),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF216177),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    child: const Text('リトライ'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
