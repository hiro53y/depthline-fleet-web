import 'package:flutter/material.dart';

class MovementInputOverlay extends StatelessWidget {
  const MovementInputOverlay({
    required this.showTouchZones,
    super.key,
  });

  final bool showTouchZones;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
            ? const Row(
                children: <Widget>[
                  Expanded(
                    child: _ZoneHint(
                      icon: Icons.gamepad_rounded,
                      label: '左下の操艦ボタンで移動',
                    ),
                  ),
                  Expanded(
                    child: _ZoneHint(
                      icon: Icons.keyboard_double_arrow_down,
                      label: '右下の投下ボタンで爆雷',
                    ),
                  ),
                ],
              )
            : const SizedBox.expand(),
      ),
    );
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
