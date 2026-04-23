import 'package:flutter/material.dart';

import '../config/game_constants.dart';

class MovementInputOverlay extends StatelessWidget {
  const MovementInputOverlay({
    required this.onDirectionChanged,
    super.key,
  });

  final ValueChanged<double> onDirectionChanged;

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
        child: Row(
          children: const <Widget>[
            Expanded(child: _ZoneHint(icon: Icons.keyboard_double_arrow_left)),
            Expanded(child: _ZoneHint(icon: Icons.keyboard_double_arrow_right)),
          ],
        ),
      ),
    );
  }

  void _handlePointer(double localX) {
    onDirectionChanged(localX < (GameConstants.logicalWidth / 2) ? -1 : 1);
  }
}

class _ZoneHint extends StatelessWidget {
  const _ZoneHint({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Icon(
          icon,
          color: const Color(0x28E4F5FB),
          size: 30,
        ),
      ),
    );
  }
}
