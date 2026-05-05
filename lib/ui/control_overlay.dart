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
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
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

// ---------------------------------------------------------------------------
// _DropButton – StatefulWidget with press-scale and glow animation.
// Action fires on TapDown for immediate game response.
// ---------------------------------------------------------------------------

class _DropButton extends StatefulWidget {
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
  State<_DropButton> createState() => _DropButtonState();
}

class _DropButtonState extends State<_DropButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 60),
    reverseDuration: const Duration(milliseconds: 240),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn, reverseCurve: Curves.easeOut),
  );

  late final Animation<double> _glowFraction = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _ctrl.forward();
    widget.onPressed();
  }

  void _onTapUp(TapUpDetails _) => _ctrl.reverse();
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.alignment == Alignment.centerLeft
        ? const Color(0xFF66E8FF)
        : const Color(0xFFFFC86D);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, _) {
        final double glow = _glowFraction.value;

        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.enabled
                      ? <Color>[
                          Color.lerp(const Color(0xFF1A647C),
                              accent.withOpacity(0.35), glow * 0.4)!,
                          const Color(0xFF0E3447),
                        ]
                      : const <Color>[Color(0xFF25323A), Color(0xFF11181D)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.enabled
                      ? accent.withOpacity(0.70 + glow * 0.28)
                      : const Color(0xFF35464E),
                  width: 1.0 + glow * 0.8,
                ),
                boxShadow: <BoxShadow>[
                  if (widget.enabled)
                    BoxShadow(
                      color: accent.withOpacity(0.18 + glow * 0.38),
                      blurRadius: 18 + glow * 22,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Top accent bar
                  Positioned(
                    top: 9,
                    left: widget.alignment == Alignment.centerLeft ? 18 : null,
                    right: widget.alignment == Alignment.centerRight ? 18 : null,
                    child: Container(
                      width: 96,
                      height: 3,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(
                            widget.enabled ? 0.85 + glow * 0.15 : 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Button label + icon
                  Align(
                    alignment: widget.alignment,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: widget.alignment == Alignment.centerLeft
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        children: <Widget>[
                          // Drop icon with glow
                          _GlowIcon(
                            icon: Icons.keyboard_double_arrow_down,
                            color: widget.enabled
                                ? accent
                                : const Color(0xFF6F7D84),
                            glowColor: accent,
                            glowFraction: widget.enabled ? glow : 0,
                            size: 30,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  color: widget.enabled
                                      ? const Color(0xFFBDEEFF)
                                      : const Color(0xFF6F7D84),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: widget.enabled
                                      ? Color.lerp(Colors.white, accent, glow * 0.6)
                                      : const Color(0xFF9AA5AA),
                                  fontSize: 26,
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
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Small helper: icon with optional bloom glow on press.
// ---------------------------------------------------------------------------

class _GlowIcon extends StatelessWidget {
  const _GlowIcon({
    required this.icon,
    required this.color,
    required this.glowColor,
    required this.glowFraction,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final Color glowColor;
  final double glowFraction;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (glowFraction > 0.01)
          Icon(
            icon,
            color: glowColor.withOpacity(glowFraction * 0.55),
            size: size + glowFraction * 8,
          ),
        Icon(icon, color: color, size: size),
      ],
    );
  }
}
