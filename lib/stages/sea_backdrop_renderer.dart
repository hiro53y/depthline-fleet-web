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

    final Paint linePaint = Paint()
      ..color = palette.waterline.withOpacity(0.85)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, stageDefinition.waterlineY),
      Offset(GameConstants.logicalWidth, stageDefinition.waterlineY),
      linePaint,
    );

    final Paint lanePaint = Paint()
      ..color = palette.lane.withOpacity(0.08)
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

class _StagePalette {
  const _StagePalette({
    required this.fullGradient,
    required this.skyGradient,
    required this.seaGradient,
    required this.waterline,
    required this.lane,
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
        );
    }
  }

  final List<Color> fullGradient;
  final List<Color> skyGradient;
  final List<Color> seaGradient;
  final Color waterline;
  final Color lane;
}
