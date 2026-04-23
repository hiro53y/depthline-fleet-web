import 'dart:ui';

import 'package:depthline_fleet/radar/world_to_radar_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WorldToRadarMapper projects world edges into radar margins', () {
    const WorldToRadarMapper mapper = WorldToRadarMapper(
      worldWidth: 1280,
      waterlineY: 170,
      playBottomY: 560,
      radarWidth: 1280,
      radarHeight: 64,
    );

    final Offset topLeft = mapper.project(worldX: 0, worldY: 170);
    final Offset bottomRight = mapper.project(worldX: 1280, worldY: 560);

    expect(topLeft.dx, 12);
    expect(topLeft.dy, 10);
    expect(bottomRight.dx, 1268);
    expect(bottomRight.dy, 54);
  });
}
