import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gameplay/game_session_state.dart';

class ControlOverlay extends StatelessWidget {
  const ControlOverlay({
    required this.sessionListenable,
    required this.onDropLeft,
    required this.onDropRight,
    super.key,
  });

  final ValueListenable<GameSessionState> sessionListenable;
  final VoidCallback onDropLeft;
  final VoidCallback onDropRight;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameSessionState>(
      valueListenable: sessionListenable,
      builder: (BuildContext context, GameSessionState state, _) {
        final bool enabled = state.isPlaying;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFF071018),
            border: Border(top: BorderSide(color: Color(0x553BB2D0), width: 1)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _DropButton(
                    label: '左投下',
                    enabled: enabled,
                    onPressed: onDropLeft,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _DropButton(
                    label: '右投下',
                    enabled: enabled,
                    onPressed: onDropRight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DropButton extends StatelessWidget {
  const _DropButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF154D63),
        disabledBackgroundColor: const Color(0xFF26333A),
        foregroundColor: const Color(0xFFF1FAFD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(label),
    );
  }
}
