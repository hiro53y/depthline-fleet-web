import 'dart:ui';

import 'package:depthline_fleet/gameplay/collision_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rectsOverlap returns true for intersecting rectangles', () {
    final Rect a = Rect.fromLTWH(10, 10, 20, 20);
    final Rect b = Rect.fromLTWH(20, 20, 20, 20);

    expect(rectsOverlap(a, b), isTrue);
  });

  test('rectsOverlap returns false for separated rectangles', () {
    final Rect a = Rect.fromLTWH(10, 10, 20, 20);
    final Rect b = Rect.fromLTWH(40, 40, 10, 10);

    expect(rectsOverlap(a, b), isFalse);
  });
}
