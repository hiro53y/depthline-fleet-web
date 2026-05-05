import 'dart:math' as math;
import 'dart:ui';

import '../config/game_constants.dart';
import '../gameplay/weapon_side.dart';

/// Player-controlled surface warship.
///
/// All visual elements are drawn with the dart:ui Canvas API so that this
/// class can be used inside a Flame game without any Flutter widget overhead.
class PlayerBattleship {
  PlayerBattleship({
    required double startX,
    required double startY,
  }) : _position = Offset(startX, startY);

  // ---- Size / hitbox (unchanged) ----
  static const Size _size = Size(148, 44);

  Offset _position;
  double _movementDirection = 0;
  double _invulnerabilityRemaining = 0;

  /// Accumulated time used for animations (smoke, radar, running lights).
  double _time = 0;

  // ---- Public API ----
  Offset get position => _position;
  bool get isInvulnerable => _invulnerabilityRemaining > 0;

  Rect get bounds => Rect.fromCenter(
        center: Offset(_position.dx, _position.dy + 4),
        width: _size.width * 0.8,
        height: _size.height * 0.58,
      );

  void setMovementDirection(double direction) {
    _movementDirection = direction.clamp(-1.0, 1.0);
  }

  void stop() {
    _movementDirection = 0;
  }

  void triggerInvulnerability() {
    _invulnerabilityRemaining = GameConstants.playerInvulnerabilitySeconds;
  }

  Offset dropPointFor(WeaponSide side) {
    final double offset = side == WeaponSide.left
        ? -GameConstants.depthChargeOffsetX
        : GameConstants.depthChargeOffsetX;
    return Offset(_position.dx + offset, _position.dy + 8);
  }

  void update(double dt, {required double minX, required double maxX}) {
    _time += dt;
    if (_invulnerabilityRemaining > 0) {
      _invulnerabilityRemaining = math.max(0, _invulnerabilityRemaining - dt);
    }
    final double nextX =
        (_position.dx + (_movementDirection * GameConstants.playerSpeed * dt))
            .clamp(minX + (_size.width / 2), maxX - (_size.width / 2))
            .toDouble();
    _position = Offset(nextX, _position.dy);
  }

  // ---- Rendering ----

  void render(Canvas canvas) {
    final double a = isInvulnerable
        ? ((_invulnerabilityRemaining * 12).floor().isEven ? 0.28 : 0.96)
        : 1.0;

    _drawWake(canvas, a);
    _drawBowWave(canvas, a);
    _drawHullShadow(canvas, a);
    _drawHull(canvas, a);
    _drawDeck(canvas, a);
    _drawSuperstructure(canvas, a);
    _drawFunnel(canvas, a);
    _drawSmoke(canvas, a);
    _drawTurret(canvas, Offset(_position.dx - 46, _position.dy - 11), -1, a);
    _drawTurret(canvas, Offset(_position.dx + 43, _position.dy - 10), 1, a);
    _drawMast(canvas, a);
    _drawRunningLights(canvas, a);
  }

  // ---- Hull ----

  void _drawHullShadow(Canvas canvas, double a) {
    canvas.drawPath(
      _buildHullPath(
        Rect.fromCenter(center: _position.translate(0, 10), width: 164, height: 32),
      ).shift(const Offset(3, 9)),
      Paint()
        ..color = const Color(0x88000000).withOpacity(0.44 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  void _drawHull(Canvas canvas, double a) {
    final Rect r =
        Rect.fromCenter(center: _position.translate(0, 10), width: 164, height: 32);
    final Path path = _buildHullPath(r);

    // Main gradient – light grey top → dark steel bottom
    canvas.drawPath(
      path,
      Paint()
        ..shader = Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          <Color>[
            const Color(0xFFDCEDF5).withOpacity(a),
            const Color(0xFFAABFC8).withOpacity(a),
            const Color(0xFF6B8A96).withOpacity(a),
            const Color(0xFF3D5D6B).withOpacity(a),
          ],
          <double>[0.0, 0.35, 0.70, 1.0],
        ),
    );

    // Dark boot-topping stripe at waterline
    canvas.drawPath(
      Path()
        ..moveTo(r.left + 22, r.center.dy + 5)
        ..lineTo(r.right - 16, r.center.dy + 3)
        ..lineTo(r.right - 14, r.center.dy + 12)
        ..lineTo(r.left + 24, r.center.dy + 14)
        ..close(),
      Paint()..color = const Color(0xFF1A2E38).withOpacity(0.86 * a),
    );

    // Subtle hull outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6090A0).withOpacity(0.25 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Horizontal plating seam
    canvas.drawLine(
      Offset(r.left + 28, r.top + 9),
      Offset(r.right - 20, r.top + 8),
      Paint()
        ..color = const Color(0x5598B8C8).withOpacity(0.55 * a)
        ..strokeWidth = 0.8,
    );
  }

  Path _buildHullPath(Rect r) => Path()
    ..moveTo(r.left + 8, r.top + 5)
    ..lineTo(r.right - 30, r.top + 3)
    ..quadraticBezierTo(r.right + 7, r.top + 12, r.right - 7, r.bottom - 4)
    ..lineTo(r.left + 26, r.bottom - 2)
    ..quadraticBezierTo(r.left - 6, r.bottom - 10, r.left + 8, r.top + 5)
    ..close();

  // ---- Deck ----

  void _drawDeck(Canvas canvas, double a) {
    final Rect deck =
        Rect.fromCenter(center: _position.translate(-4, -4), width: 122, height: 15);

    canvas.drawRRect(
      RRect.fromRectAndRadius(deck, const Radius.circular(5)),
      Paint()
        ..shader = Gradient.linear(
          deck.topCenter,
          deck.bottomCenter,
          <Color>[
            const Color(0xFF8FA5B0).withOpacity(a),
            const Color(0xFF4D6470).withOpacity(a),
          ],
        ),
    );

    // Deck plating lines
    final Paint lineP = Paint()
      ..color = const Color(0xFFB2C8D2).withOpacity(0.22 * a)
      ..strokeWidth = 0.8;
    for (int i = 0; i < 5; i++) {
      final double x = deck.left + 10 + (i * 22.0);
      canvas.drawLine(Offset(x, deck.top + 3), Offset(x, deck.bottom - 3), lineP);
    }

    // Anchor hawse on bow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(deck.right - 8, deck.center.dy), width: 10, height: 7),
      Paint()..color = const Color(0xFF233C49).withOpacity(0.78 * a),
    );

    // Depth-charge racks port & starboard
    _drawDCRack(canvas, Offset(deck.left + 12, deck.center.dy), a);
    _drawDCRack(canvas, Offset(deck.right - 12, deck.center.dy), a);
  }

  void _drawDCRack(Canvas canvas, Offset c, double a) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 10, height: 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFF99C0D0).withOpacity(0.55 * a),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, -4), width: 7, height: 4),
      Paint()..color = const Color(0xFFB0D0DC).withOpacity(0.50 * a),
    );
  }

  // ---- Superstructure ----

  void _drawSuperstructure(Canvas canvas, double a) {
    // Lower level
    final Rect low =
        Rect.fromCenter(center: _position.translate(2, -15), width: 70, height: 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(low, const Radius.circular(4)),
      Paint()
        ..shader = Gradient.linear(
          low.topCenter,
          low.bottomCenter,
          <Color>[
            const Color(0xFF8FA0AB).withOpacity(a),
            const Color(0xFF4A6270).withOpacity(a),
          ],
        ),
    );

    // Bridge (upper level)
    final Rect bridge =
        Rect.fromCenter(center: _position.translate(4, -28), width: 52, height: 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bridge, const Radius.circular(5)),
      Paint()
        ..shader = Gradient.linear(
          bridge.topLeft,
          bridge.bottomRight,
          <Color>[
            const Color(0xFFBFD3DC).withOpacity(a),
            const Color(0xFF8FA3AD).withOpacity(a),
            const Color(0xFF5A7280).withOpacity(a),
          ],
        ),
    );

    // Bridge windows
    final Paint winP = Paint()..color = const Color(0xFF1A3040).withOpacity(0.88 * a);
    final Paint glareP = Paint()..color = const Color(0xFF88DDFF).withOpacity(0.22 * a);
    for (int i = 0; i < 4; i++) {
      final Rect w = Rect.fromCenter(
          center: _position.translate(4 + (-15.0 + i * 10.0), -27), width: 7, height: 6);
      canvas.drawRRect(RRect.fromRectAndRadius(w, const Radius.circular(1)), winP);
      canvas.drawRect(Rect.fromLTWH(w.left + 1, w.top + 1, 2, 2), glareP);
    }

    // Bridge roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: _position.translate(4, -38), width: 40, height: 8),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF6E8894).withOpacity(a),
    );

    // Rangefinder / director on roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: _position.translate(4, -43), width: 22, height: 5),
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF8AAAB6).withOpacity(0.88 * a),
    );
  }

  // ---- Funnel ----

  void _drawFunnel(Canvas canvas, double a) {
    final Offset base = _position.translate(-10, -22);

    // Tapered body (wider at bottom)
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 11, base.dy + 6)
        ..lineTo(base.dx + 11, base.dy + 6)
        ..lineTo(base.dx + 8, base.dy - 16)
        ..lineTo(base.dx - 8, base.dy - 16)
        ..close(),
      Paint()
        ..shader = Gradient.linear(
          Offset(base.dx - 11, 0),
          Offset(base.dx + 11, 0),
          <Color>[
            const Color(0xFF3A5260).withOpacity(a),
            const Color(0xFF263D4B).withOpacity(a),
            const Color(0xFF3D5766).withOpacity(a),
          ],
        ),
    );

    // Top rim
    canvas.drawOval(
      Rect.fromCenter(center: base.translate(0, -16), width: 16, height: 6),
      Paint()..color = const Color(0xFF1C2E38).withOpacity(a),
    );

    // Band stripe
    canvas.drawRect(
      Rect.fromCenter(center: base.translate(0, -9), width: 20, height: 3),
      Paint()..color = const Color(0xFF1D3A4A).withOpacity(0.72 * a),
    );
  }

  // ---- Smoke ----

  void _drawSmoke(Canvas canvas, double a) {
    final Offset top = _position.translate(-10, -38);
    for (int i = 0; i < 4; i++) {
      final double phase = (_time * 0.85 + i * 0.42) % 1.68;
      final double smokeA = (1.0 - phase / 1.68) * 0.20 * a;
      if (smokeA < 0.01) continue;
      // Smoke drifts opposite to ship's movement direction
      final double dx = _movementDirection * -7 * phase;
      canvas.drawCircle(
        top.translate(dx, -(phase * 30.0)),
        5.0 + phase * 9.0,
        Paint()..color = const Color(0xFF99A8AE).withOpacity(smokeA),
      );
    }
  }

  // ---- Turrets ----

  void _drawTurret(Canvas canvas, Offset c, int dir, double a) {
    // Rounded base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 30, height: 14), const Radius.circular(7)),
      Paint()
        ..shader = Gradient.linear(
          c.translate(0, -7),
          c.translate(0, 7),
          <Color>[
            const Color(0xFFD0E4EC).withOpacity(a),
            const Color(0xFF8DAAB6).withOpacity(a),
          ],
        ),
    );

    // Face armour
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(3.0 * dir, -1), width: 14, height: 8),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF4E6E7C).withOpacity(0.65 * a),
    );

    // Upper barrel
    canvas.drawLine(
      c.translate(7.0 * dir, -3.5),
      c.translate(41.0 * dir, -6.5),
      Paint()
        ..color = const Color(0xFFCCDEE6).withOpacity(a)
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round,
    );
    // Lower barrel
    canvas.drawLine(
      c.translate(7.0 * dir, 0.5),
      c.translate(40.0 * dir, -1.0),
      Paint()
        ..color = const Color(0xFFBBCFD8).withOpacity(a)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // Muzzle caps
    for (final double by in <double>[-6.5, -1.0]) {
      canvas.drawCircle(
        c.translate(41.0 * dir, by),
        2.5,
        Paint()..color = const Color(0xFF44606E).withOpacity(a),
      );
    }
  }

  // ---- Mast ----

  void _drawMast(Canvas canvas, double a) {
    final Paint thick = Paint()
      ..color = const Color(0xFFCDD9E0).withOpacity(a)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final Paint thin = Paint()
      ..color = const Color(0xFFB8C8D0).withOpacity(a)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final Paint stay = Paint()
      ..color = const Color(0xFFAABEC6).withOpacity(0.35 * a)
      ..strokeWidth = 0.8;

    // Main mast pole
    canvas.drawLine(_position.translate(18, -42), _position.translate(18, -74), thick);

    // Upper yard arm
    canvas.drawLine(_position.translate(3, -62), _position.translate(34, -62), thin);

    // Lower yard arm
    canvas.drawLine(
      _position.translate(8, -51),
      _position.translate(29, -51),
      Paint()
        ..color = const Color(0xFFB8C8D0).withOpacity(0.70 * a)
        ..strokeWidth = 1.2,
    );

    // Stay cables
    canvas.drawLine(_position.translate(18, -74), _position.translate(-12, -44), stay);
    canvas.drawLine(_position.translate(18, -74), _position.translate(50, -42), stay);

    // Radar dome
    canvas.drawCircle(
      _position.translate(18, -77),
      5.5,
      Paint()..color = const Color(0xFFE8F4FA).withOpacity(a),
    );

    // Rotating radar arm (uses accumulated _time)
    final double angle = _time * 2.2;
    canvas.drawLine(
      _position.translate(18, -77),
      _position.translate(18 + math.cos(angle) * 8, -77 + math.sin(angle) * 5),
      Paint()
        ..color = const Color(0xFF55EEFF).withOpacity(0.72 * a)
        ..strokeWidth = 1.4,
    );
  }

  // ---- Running lights ----

  void _drawRunningLights(Canvas canvas, double a) {
    final double pulse = math.sin(_time * 3.2) * 0.12 + 0.88;

    // Port – red, left
    canvas.drawCircle(
      _position.translate(-72, -5),
      4.5,
      Paint()
        ..color = const Color(0xFFFF3333).withOpacity(0.68 * a * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      _position.translate(-72, -5),
      1.8,
      Paint()..color = const Color(0xFFFF9999).withOpacity(a),
    );

    // Starboard – green, right
    canvas.drawCircle(
      _position.translate(74, -4),
      4.5,
      Paint()
        ..color = const Color(0xFF33FF77).withOpacity(0.68 * a * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      _position.translate(74, -4),
      1.8,
      Paint()..color = const Color(0xFF88FFBB).withOpacity(a),
    );
  }

  // ---- Wake ----

  void _drawWake(Canvas canvas, double a) {
    // V-shaped wake lines spreading behind stern
    for (int i = 0; i < 4; i++) {
      final double spread = 20.0 + (i * 24.0);
      final double yBase = 19.0 + (i * 4.0);
      final double op = (0.28 - i * 0.055).clamp(0.03, 0.28);
      final Paint p = Paint()
        ..color = const Color(0xFFDDF6FF).withOpacity(op * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - (i * 0.4);
      canvas.drawLine(
        Offset(_position.dx - 70 - spread, _position.dy + yBase),
        Offset(_position.dx - 64, _position.dy + 18),
        p,
      );
      canvas.drawLine(
        Offset(_position.dx + 64, _position.dy + 18),
        Offset(_position.dx + 70 + spread, _position.dy + yBase),
        p,
      );
    }

    // Prop-wash ovals behind the stern
    for (int i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: _position.translate(-82 - (i * 16.0), 20),
          width: 14.0 + (i * 5.0),
          height: 5.0 + (i * 3.5),
        ),
        Paint()
          ..color = const Color(0xFFB8ECFF)
              .withOpacity((0.18 - i * 0.028).clamp(0.02, 0.18) * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  // ---- Bow wave ----

  void _drawBowWave(Canvas canvas, double a) {
    final Offset bow = _position.translate(81, 4);

    // Curved arcs fanning outward
    for (int i = 0; i < 3; i++) {
      final double sz = 16.0 + i * 10;
      canvas.drawArc(
        Rect.fromCenter(center: bow, width: sz, height: sz * 0.55),
        -math.pi * 0.30,
        math.pi * 0.60,
        false,
        Paint()
          ..color = const Color(0xFFEEF9FF)
              .withOpacity((0.55 - i * 0.15).clamp(0.1, 0.55) * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 - (i * 0.3),
      );
    }

    // Spray dots
    final Paint dot = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.28 * a);
    canvas.drawCircle(bow.translate(4, -7), 1.5, dot);
    canvas.drawCircle(bow.translate(8, -3), 1.0, dot);
    canvas.drawCircle(bow.translate(6, 2), 1.2, dot);
  }
}
