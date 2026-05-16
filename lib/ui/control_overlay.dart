import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gameplay/game_session_state.dart';

class ControlOverlay extends StatelessWidget {
  const ControlOverlay({
    required this.sessionListenable,
    required this.onMoveDirectionChanged,
    required this.onDropLeft,
    required this.onDropRight,
    super.key,
  });

  final ValueListenable<GameSessionState> sessionListenable;
  final ValueChanged<double> onMoveDirectionChanged;
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: _ControlGroup(
                    label: '操艦',
                    subtitle: 'LEFT HAND',
                    accent: const Color(0xFF66E8FF),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _MoveButton(
                            title: '←',
                            subtitle: '左移動',
                            direction: -1,
                            enabled: enabled,
                            onDirectionChanged: onMoveDirectionChanged,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MoveButton(
                            title: '→',
                            subtitle: '右移動',
                            direction: 1,
                            enabled: enabled,
                            onDirectionChanged: onMoveDirectionChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _ControlGroup(
                        label: '爆雷投下',
                        subtitle: 'RIGHT HAND',
                        accent: const Color(0xFFFFC86D),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: _DropButton(
                                title: '左投下',
                                subtitle: 'LEFT RACK',
                                alignment: Alignment.centerLeft,
                                enabled: enabled,
                                onPressed: onDropLeft,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DropButton(
                                title: '右投下',
                                subtitle: 'RIGHT RACK',
                                alignment: Alignment.centerRight,
                                enabled: enabled,
                                onPressed: onDropRight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: accent.withOpacity(0.95),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        accent.withOpacity(0.65),
                        accent.withOpacity(0.03),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7DB8C7),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    );
  }
}

// Stateful buttons use press-scale and glow animation.
// Drop actions fire on TapDown for immediate game response.

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

class _MoveButton extends StatefulWidget {
  const _MoveButton({
    required this.title,
    required this.subtitle,
    required this.direction,
    required this.enabled,
    required this.onDirectionChanged,
  });

  final String title;
  final String subtitle;
  final double direction;
  final bool enabled;
  final ValueChanged<double> onDirectionChanged;

  @override
  State<_MoveButton> createState() => _MoveButtonState();
}

class _MoveButtonState extends State<_MoveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 180),
  );

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.91).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn, reverseCurve: Curves.easeOut),
  );

  late final Animation<double> _glowFraction = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
  );

  @override
  void didUpdateWidget(covariant _MoveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      widget.onDirectionChanged(0);
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _start(TapDownDetails _) {
    if (!widget.enabled) return;
    _ctrl.forward();
    widget.onDirectionChanged(widget.direction);
  }

  void _stop() {
    if (widget.enabled) {
      widget.onDirectionChanged(0);
    }
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF66E8FF);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, _) {
        final double glow = _glowFraction.value;

        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _start,
            onTapUp: (_) => _stop(),
            onTapCancel: _stop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.enabled
                      ? <Color>[
                          Color.lerp(const Color(0xFF153D52),
                              accent.withOpacity(0.42), glow * 0.55)!,
                          const Color(0xFF082737),
                        ]
                      : const <Color>[Color(0xFF25323A), Color(0xFF11181D)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.enabled
                      ? accent.withOpacity(0.72 + glow * 0.24)
                      : const Color(0xFF35464E),
                  width: 1.0 + glow * 0.8,
                ),
                boxShadow: <BoxShadow>[
                  if (widget.enabled)
                    BoxShadow(
                      color: accent.withOpacity(0.16 + glow * 0.34),
                      blurRadius: 16 + glow * 20,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.enabled
                                ? Color.lerp(Colors.white, accent, glow * 0.55)
                                : const Color(0xFF9AA5AA),
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: widget.enabled
                                ? const Color(0xFFBDEEFF)
                                : const Color(0xFF6F7D84),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
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
