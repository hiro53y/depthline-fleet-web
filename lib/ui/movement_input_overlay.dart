import 'package:flutter/material.dart';

import '../config/game_constants.dart';

class MovementInputOverlay extends StatelessWidget {
  const MovementInputOverlay({
    required this.onDirectionChanged,
    required this.showTouchZones,
    super.key,
  });

  final ValueChanged<double> onDirectionChanged;
  final bool showTouchZones;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent event) => _handlePointer(event.localPosition.dx),
      onPointerMove: (PointerMoveEvent event) => _handlePointer(event.localPosition.dx),
      onPointerUp: (_) => onDirectionChanged(0),
      onPointerCancel: (_) => onDirectionChanged(0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.transparent,
              const Color(0x22081621),
            ],
          ),
        ),
        child: showTouchZones
            ? Row(
                children: const <Widget>[
                  Expanded(child: _ZoneHint(icon: Icons.keyboard_double_arrow_left, label: 'LEFT MANEUVER')),
                  Expanded(child: _ZoneHint(icon: Icons.keyboard_double_arrow_right, label: 'RIGHT MANEUVER')),
                ],
              )
            : const SizedBox.expand(),
      ),
    );
  }

  void _handlePointer(double localX) {
    onDirectionChanged(localX < (GameConstants.logicalWidth / 2) ? -1 : 1);
  }
}

class _ZoneHint extends StatelessWidget {
  const _ZoneHint({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x2210202C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x225DEAFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: const Color(0x44E4F5FB), size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0x44E4F5FB),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
