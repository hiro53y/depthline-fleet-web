import 'dart:ui';

import 'package:flutter/material.dart';

import '../gameplay/game_session_state.dart';
import 'radar_contact.dart';
import 'world_to_radar_mapper.dart';

class RadarStrip extends StatelessWidget {
  const RadarStrip({
    required this.contactsListenable,
    required this.mapper,
    required this.sessionListenable,
    super.key,
  });

  final ValueListenable<List<RadarContact>> contactsListenable;
  final WorldToRadarMapper mapper;
  final ValueListenable<GameSessionState> sessionListenable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF08121A),
            Color(0xFF0B1A25),
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0x553BB2D0), width: 1),
          bottom: BorderSide(color: Color(0x443BB2D0), width: 1),
        ),
      ),
      child: ValueListenableBuilder<GameSessionState>(
        valueListenable: sessionListenable,
        builder: (BuildContext context, GameSessionState state, _) {
          return ValueListenableBuilder<List<RadarContact>>(
            valueListenable: contactsListenable,
            builder: (BuildContext context, List<RadarContact> contacts, _) {
              return CustomPaint(
                painter: _RadarPainter(
                  contacts: contacts,
                  mapper: mapper,
                  status: state.status,
                ),
                child: const SizedBox.expand(),
              );
            },
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.contacts,
    required this.mapper,
    required this.status,
  });

  final List<RadarContact> contacts;
  final WorldToRadarMapper mapper;
  final GameStatus status;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = const Color(0x55A9D4E0)
      ..strokeWidth = 1;
    final Paint baselinePaint = Paint()
      ..color = const Color(0x777DE3F5)
      ..strokeWidth = 1.25;

    canvas.drawLine(
      Offset(12, size.height / 2),
      Offset(size.width - 12, size.height / 2),
      baselinePaint,
    );
    canvas.drawLine(
      const Offset(12, 12),
      Offset(size.width - 12, 12),
      gridPaint,
    );
    canvas.drawLine(
      Offset(12, size.height - 12),
      Offset(size.width - 12, size.height - 12),
      gridPaint,
    );

    for (int i = 1; i < 8; i += 1) {
      final double x = 12 + ((size.width - 24) * (i / 8));
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, size.height - 10),
        gridPaint,
      );
    }

    for (final RadarContact contact in contacts) {
      final Offset point = mapper.project(
        worldX: contact.worldX,
        worldY: contact.worldY,
      );
      final Paint paint = Paint()
        ..color = contact.type == RadarContactType.submarine
            ? const Color(0xFFFFC36B)
            : const Color(0xFF9DE9FF);

      if (contact.type == RadarContactType.submarine) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: point, width: 16, height: 8),
            const Radius.circular(4),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(point, 5, paint);
      }
    }

    if (status == GameStatus.gameOver || status == GameStatus.cleared) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: status == GameStatus.cleared ? 'CLEAR HOLD' : 'SIGNAL LOST',
          style: const TextStyle(
            color: Color(0xFFBEEAF7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(size.width - painter.width - 16, 8));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.contacts != contacts || oldDelegate.status != status;
  }
}
