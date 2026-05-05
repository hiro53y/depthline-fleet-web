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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFF091A24), Color(0xFF040A0F)],
            ),
            border: Border(top: BorderSide(color: Color(0x6638D7FF), width: 1.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _DropButton(
                    title: '左投下',
                    subtitle: 'PORT DEPTH CHARGE',
                    alignment: Alignment.centerLeft,
                    enabled: enabled,
                    onPressed: onDropLeft,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _DropButton(
                    title: '右投下',
                    subtitle: 'STARBOARD DEPTH CHARGE',
                    alignment: Alignment.centerRight,
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
    required this.title,
    required this.subtitle,
    required this.alignment,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final Alignment alignment;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color accent = alignment == Alignment.centerLeft
        ? const Color(0xFF66E8FF)
        : const Color(0xFFFFC86D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? const <Color>[Color(0xFF1A647C), Color(0xFF0E3447)]
                  : const <Color>[Color(0xFF25323A), Color(0xFF11181D)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: enabled ? accent.withOpacity(0.70) : const Color(0xFF35464E)),
            boxShadow: <BoxShadow>[
              if (enabled)
                BoxShadow(
                  color: accent.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                top: 9,
                left: alignment == Alignment.centerLeft ? 18 : null,
                right: alignment == Alignment.centerRight ? 18 : null,
                child: Container(
                  width: 96,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(enabled ? 0.9 : 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Align(
                alignment: alignment,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: alignment == Alignment.centerLeft ? TextDirection.ltr : TextDirection.rtl,
                    children: <Widget>[
                      Icon(
                        Icons.keyboard_double_arrow_down,
                        color: enabled ? accent : const Color(0xFF6F7D84),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: enabled ? const Color(0xFFBDEEFF) : const Color(0xFF6F7D84),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: TextStyle(
                              color: enabled ? Colors.white : const Color(0xFF9AA5AA),
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
