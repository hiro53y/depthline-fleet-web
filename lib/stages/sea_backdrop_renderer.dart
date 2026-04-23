import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/game_constants.dart';
import 'stage_definition.dart';

class SeaBackdropRenderer {
  const SeaBackdropRenderer(this.stageDefinition);

  final StageDefinition stageDefinition;

  void render(Canvas canvas) {
    final Rect fullRect = Rect.fromLTWH(
      0,
      0,
      GameConstants.logicalWidth,
      GameConstants.logicalHeight,
    );

    canvas.drawRect(
      fullRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF08141B),
            Color(0xFF0A2834),
            Color(0xFF0E4B63),
            Color(0xFF0A3145),
          ],
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
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF17394B),
            Color(0xFF24566C),
          ],
        ).createShader(skyRect),
    );

    final Rect seaRect = Rect.fromLTWH(
      0,
      stageDefinition.waterlineY,
      GameConstants.logicalWidth,
      stageDefinition.playBottomY - stageDefinition.waterlineY,
    );
    canvas.drawRect(
      seaRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF1593B6),
            Color(0xFF0B607E),
            Color(0xFF073149),
          ],
        ).createShader(seaRect),
    );

    final Paint linePaint = Paint()
      ..color = const Color(0xFFE2F6FA).withOpacity(0.85)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, stageDefinition.waterlineY),
      Offset(GameConstants.logicalWidth, stageDefinition.waterlineY),
      linePaint,
    );

    final Paint lanePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.08)
      ..strokeWidth = 1.5;
    for (final double lane in stageDefinition.depthLanes) {
      canvas.drawLine(
        Offset(0, lane),
        Offset(GameConstants.logicalWidth, lane),
        lanePaint,
      );
    }
  }
}
