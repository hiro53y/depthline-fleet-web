import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/game_constants.dart';
import 'stage_definition.dart';

class SeaBackdropRenderer {
  const SeaBackdropRenderer(this.stageDefinition);

  final StageDefinition stageDefinition;

  void render(Canvas canvas) {
    final _StagePalette palette = _StagePalette.forStage(stageDefinition.stageNumber);
    final Rect fullRect = Rect.fromLTWH(
      0,
      0,
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );

    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.fullGradient,
        ).createShader(fullRect),
    );

    final Rect skyRect = Rect.fromLTWH(
      0,
      GameConstants.playTop,
      GameConstants.logicalWidth,
      stageDefinition.waterlineY - GameConstants.playTop,
    );
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.skyGradient,
        ).createShader(skyRect),
    );
    _drawSkyDetails(canvas, skyRect, palette);

    final Rect seaRect = Rect.fromLTWH(
      0,
      stageDefinition.waterlineY,
      GameConstants.logicalWidth,
      stageDefinition.playBottomY - stageDefinition.waterlineY,
    );
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: palette.seaGradient,
        ).createShader(seaRect),
    );
    _drawSeaDetails(canvas, seaRect, palette);

    _drawWaterline(canvas, palette);

    final Paint lanePaint = Paint()
      ..color = palette.lane.withOpacity(0.11)
      ..strokeWidth = 1.2;
    for (int i = 0; i < stageDefinition.depthLanes.length; i += 1) {
      final double lane = stageDefinition.depthLanes[i];
      canvas.drawLine(
        Offset(0, lane),
        Offset(GameConstants.logicalWidth, lane),
        lanePaint,
      );
      _drawDepthLabel(canvas, lane, i + 1, palette);
    }

    final Rect vignetteRect = Rect.fromLTWH(
      0,
      GameConstants.playTop,
      GameConstants.logicalWidth,
      GameConstants.playBottom - GameConstants.playTop,
    );
    canvas.drawRect(
      vignetteRect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: const <Color>[
            Color(0x00000000),
            Color(0x33000000),
          ],
        ).createShader(vignetteRect),
    );
  }

  void _drawSkyDetails(Canvas canvas, Rect skyRect, _StagePalette palette) {
    final Rect sunRect = Rect.fromCircle(
      center: Offset(GameConstants.logicalWidth * 0.78, skyRect.top + 34),
      radius: 92,
    );
    canvas.drawCircle(
      sunRect.center,
      92,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            palette.horizonGlow.withOpacity(0.38),
            palette.horizonGlow.withOpacity(0.0),
          ],
        ).createShader(sunRect),
    );

    _drawCloud(canvas, Offset(210, skyRect.top + 40), palette.cloud.withOpacity(0.17), 1.0);
    _drawCloud(canvas, Offset(955, skyRect.top + 54), palette.cloud.withOpacity(0.13), 1.25);

    final Paint islandPaint = Paint()..color = const Color(0x44101B22);
    final Path island = Path()
      ..moveTo(0, stageDefinition.waterlineY - 4)
      ..lineTo(170, stageDefinition.waterlineY - 4)
      ..quadraticBezierTo(235, stageDefinition.waterlineY - 42, 330, stageDefinition.waterlineY - 8)
      ..lineTo(450, stageDefinition.waterlineY - 5)
      ..quadraticBezierTo(524, stageDefinition.waterlineY - 30, 638, stageDefinition.waterlineY - 6)
      ..lineTo(GameConstants.logicalWidth, stageDefinition.waterlineY - 4)
      ..lineTo(GameConstants.logicalWidth, stageDefinition.waterlineY)
      ..lineTo(0, stageDefinition.waterlineY)
      ..close();
    canvas.drawPath(island, islandPaint);
  }

  void _drawCloud(Canvas canvas, Offset anchor, Color color, double scale) {
    final Paint paint = Paint()..color = color;
    canvas.drawOval(Rect.fromCenter(center: anchor, width: 128 * scale, height: 18 * scale), paint);
    canvas.drawCircle(anchor.translate(-34 * scale, -3 * scale), 18 * scale, paint);
    canvas.drawCircle(anchor.translate(0, -9 * scale), 23 * scale, paint);
    canvas.drawCircle(anchor.translate(38 * scale, -5 * scale), 16 * scale, paint);
  }

  void _drawSeaDetails(Canvas canvas, Rect seaRect, _StagePalette palette) {
    for (int i = 0; i < 9; i += 1) {
      final double y = seaRect.top + 38.0 + (i * 38.0);
      final double alpha = (0.13 - (i * 0.008)).clamp(0.035, 0.13).toDouble();
      final Path wave = Path()..moveTo(-40, y);
      for (int x = -40; x <= GameConstants.logicalWidth + 80; x += 80) {
        wave.relativeQuadraticBezierTo(40, i.isEven ? -7 : 7, 80, 0);
      }
      canvas.drawPath(
        wave,
        Paint()
          ..color = palette.lane.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    for (int i = 0; i < 7; i += 1) {
      final double x = 90.0 + (i * 172.0);
      final Path shaft = Path()
        ..moveTo(x, seaRect.top)
        ..lineTo(x + 88, seaRect.bottom)
        ..lineTo(x + 132, seaRect.bottom)
        ..lineTo(x + 34, seaRect.top)
        ..close();
      canvas.drawPath(
        shaft,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              palette.caustic.withOpacity(0.10),
              palette.caustic.withOpacity(0.00),
            ],
          ).createShader(seaRect),
      );
    }
  }

  void _drawWaterline(Canvas canvas, _StagePalette palette) {
    final double y = stageDefinition.waterlineY;
    final Path crest = Path()..moveTo(0, y);
    for (int x = 0; x <= GameConstants.logicalWidth + 40; x += 40) {
      crest.relativeQuadraticBezierTo(20, -5, 40, 0);
    }

    canvas.drawLine(
      Offset(0, y + 4),
      Offset(GameConstants.logicalWidth, y + 4),
      Paint()
        ..color = const Color(0x66000000)
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      crest,
      Paint()
        ..color = palette.waterline.withOpacity(0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      crest.shift(const Offset(0, -4)),
      Paint()
        ..color = Colors.white.withOpacity(0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  void _drawDepthLabel(Canvas canvas, double lane, int index, _StagePalette palette) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: 'DEPTH $index',
        style: TextStyle(
          color: palette.lane.withOpacity(0.20),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(28, lane - 18));
  }
}

class _StagePalette {
  const _StagePalette({
    required this.fullGradient,
    required this.skyGradient,
    required this.seaGradient,
    required this.waterline,
    required this.lane,
    required this.cloud,
    required this.horizonGlow,
    required this.caustic,
  });

  factory _StagePalette.forStage(int stageNumber) {
    switch (stageNumber) {
      case 4:
        return const _StagePalette(
          fullGradient: <Color>[
            Color(0xFF050611),
            Color(0xFF15102A),
            Color(0xFF183D4A),
            Color(0xFF060A17),
          ],
          skyGradient: <Color>[
            Color(0xFF231B38),
            Color(0xFF33505A),
          ],
          seaGradient: <Color>[
            Color(0xFF0F7C97),
            Color(0xFF123B68),
            Color(0xFF080D20),
          ],
          waterline: Color(0xFFFFD56B),
          lane: Color(0xFFFFF0B0),
          cloud: Color(0xFFFFE7B0),
          horizonGlow: Color(0xFFFFC75A),
          caustic: Color(0xFFFFF2A8),
        );
      case 2:
        return const _StagePalette(
          fullGradient: <Color>[
            Color(0xFF11131C),
            Color(0xFF24343B),
            Color(0xFF2A5961),
            Color(0xFF103944),
          ],
          skyGradient: <Color>[
            Color(0xFF31424D),
            Color(0xFF4C6770),
          ],
          seaGradient: <Color>[
            Color(0xFF2FA0AC),
            Color(0xFF176C79),
            Color(0xFF0A3441),
          ],
          waterline: Color(0xFFF1E8C7),
          lane: Color(0xFFFFFFFF),
          cloud: Color(0xFFE7F6F7),
          horizonGlow: Color(0xFFFFD8A8),
          caustic: Color(0xFFCFFBFF),
        );
      case 3:
        return const _StagePalette(
          fullGradient: <Color>[
            Color(0xFF050A11),
            Color(0xFF111B2C),
            Color(0xFF172D48),
            Color(0xFF071528),
          ],
          skyGradient: <Color>[
            Color(0xFF1B2536),
            Color(0xFF2E3A4A),
          ],
          seaGradient: <Color>[
            Color(0xFF0E6E8B),
            Color(0xFF084D67),
            Color(0xFF04172C),
          ],
          waterline: Color(0xFFC4F2FF),
          lane: Color(0xFFE4F8FF),
          cloud: Color(0xFFB4C7D7),
          horizonGlow: Color(0xFF8FD8FF),
          caustic: Color(0xFFB8E8FF),
        );
      default:
        return const _StagePalette(
          fullGradient: <Color>[
            Color(0xFF08141B),
            Color(0xFF0A2834),
            Color(0xFF0E4B63),
            Color(0xFF0A3145),
          ],
          skyGradient: <Color>[
            Color(0xFF17394B),
            Color(0xFF24566C),
          ],
          seaGradient: <Color>[
            Color(0xFF1593B6),
            Color(0xFF0B607E),
            Color(0xFF073149),
          ],
          waterline: Color(0xFFE2F6FA),
          lane: Color(0xFFFFFFFF),
          cloud: Color(0xFFDEF7FF),
          horizonGlow: Color(0xFFAEEFFF),
          caustic: Color(0xFFB6F5FF),
        );
    }
  }

  final List<Color> fullGradient;
  final List<Color> skyGradient;
  final List<Color> seaGradient;
  final Color waterline;
  final Color lane;
  final Color cloud;
  final Color horizonGlow;
  final Color caustic;
}
