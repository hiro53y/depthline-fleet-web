import 'dart:ui';

import 'package:flutter/foundation.dart';
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
            Color(0xFF050D12),
            Color(0xFF0A1A22),
            Color(0xFF061018),
          ],
        ),
        border: Border(
          top: BorderSide(color: Color(0x7738D7FF), width: 1.5),
          bottom: BorderSide(color: Color(0x5538D7FF), width: 1),
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
    final Rect panel = Rect.fromLTWH(18, 9, size.width - 36, size.height - 18);
    final Paint panelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const <Color>[
          Color(0x331FD9FF),
          Color(0x081FD9FF),
          Color(0x2220F0B4),
        ],
      ).createShader(panel);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(8)),
      panelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(8)),
      Paint()
        ..color = const Color(0x884EDFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final Paint gridPaint = Paint()
      ..color = const Color(0x4468E7FF)
      ..strokeWidth = 1;
    final Paint baselinePaint = Paint()
      ..color = const Color(0xAA7DE3F5)
      ..strokeWidth = 1.35;

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
    for (int i = 1; i < 3; i += 1) {
      final double y = 12 + ((size.height - 24) * (i / 3));
      canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), gridPaint);
    }

    final Paint sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: const <Color>[Color(0x0033FFCC), Color(0x5533FFCC), Color(0x0033FFCC)],
      ).createShader(Rect.fromLTWH(size.width * 0.40, 10, size.width * 0.22, size.height - 20));
    canvas.drawRect(Rect.fromLTWH(size.width * 0.48, 10, size.width * 0.04, size.height - 20), sweepPaint);

    _drawLabel(canvas, 'TACTICAL SONAR', Offset(30, 14), const Color(0x887DE3F5));
    _drawLabel(canvas, 'RANGE ${contacts.length}', Offset(size.width - 116, 14), const Color(0x887DE3F5));

    for (final RadarContact contact in contacts) {
      final Offset point = mapper.project(
        worldX: contact.worldX,
        worldY: contact.worldY,
      );
      final Paint paint = Paint()
        ..color = switch (contact.type) {
          RadarContactType.submarine => const Color(0xFFFFC36B),
          RadarContactType.depthCharge => const Color(0xFF9DE9FF),
          RadarContactType.powerup => const Color(0xFFA5F28C),
        };
      canvas.drawCircle(point, 10, Paint()..color = paint.color.withOpacity(0.12));

      switch (contact.type) {
        case RadarContactType.submarine:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: point, width: 16, height: 8),
              const Radius.circular(4),
            ),
            paint,
          );
          break;
        case RadarContactType.depthCharge:
          canvas.drawCircle(point, 5, paint);
          canvas.drawCircle(
            point,
            8,
            Paint()
              ..color = paint.color.withOpacity(0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
          break;
        case RadarContactType.powerup:
          canvas.drawCircle(point, 6, paint);
          canvas.drawCircle(
            point,
            2.5,
            Paint()..color = const Color(0xFF071018),
          );
          break;
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

  void _drawLabel(Canvas canvas, String text, Offset offset, Color color) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.contacts != contacts || oldDelegate.status != status;
  }
}
