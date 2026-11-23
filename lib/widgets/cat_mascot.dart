import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Entradas del gatito. Imitan las de la máquina de estados de Rive
// (SMIBool, SMINumber, SMITrigger) para que el Login se use igual que antes.
class MascotBool {
  bool value = false;
  void change(bool v) => value = v;
}

class MascotNumber {
  double value = 50.0; // 0 = mira a la izquierda, 100 = a la derecha
}

class MascotTrigger {
  int _count = 0;
  void fire() => _count++;
}

class CatController {
  final isChecking = MascotBool(); // mira lo que escribes en el correo
  final isHandsUp = MascotBool(); // se tapa los ojos (contraseña)
  final numLook = MascotNumber(); // hacia dónde mira
  final trigSuccess = MascotTrigger(); // festeja
  final trigFail = MascotTrigger(); // se pone triste
}

/// Gatito tendero dibujado con CustomPainter y animado con un Ticker.
class CatMascot extends StatefulWidget {
  const CatMascot({super.key, required this.controller, this.height = 200});

  final CatController controller;
  final double height;

  @override
  State<CatMascot> createState() => _CatMascotState();
}

class _CatMascotState extends State<CatMascot>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _random = math.Random();

  double _t = 0;
  double look = 0, checking = 0, hands = 0, happy = 0, sad = 0;
  double blink = 0, bounce = 0, shake = 0, tail = 0;

  int _seenSuccess = 0, _seenFail = 0;
  double? _successAt, _failAt, _blinkAt;
  double _nextBlink = 2.5;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  double _approach(double current, double target, double k) =>
      current + (target - current) * k;

  void _tick(Duration elapsed) {
    final now = elapsed.inMicroseconds / 1e6;
    final dt = (now - _t).clamp(0.0, 0.1);
    _t = now;
    final c = widget.controller;
    final k = 1 - math.exp(-dt * 12);

    // Disparadores
    if (c.trigSuccess._count != _seenSuccess) {
      _seenSuccess = c.trigSuccess._count;
      _successAt = now;
      _failAt = null;
    }
    if (c.trigFail._count != _seenFail) {
      _seenFail = c.trigFail._count;
      _failAt = now;
      _successAt = null;
    }

    final lookTarget = c.isChecking.value ? c.numLook.value / 50.0 - 1.0 : 0.0;
    look = _approach(look, lookTarget.clamp(-1.0, 1.0), k);
    checking = _approach(checking, c.isChecking.value ? 1 : 0, k);
    hands = _approach(hands, c.isHandsUp.value ? 1 : 0, k);

    final sinceSuccess = _successAt == null ? 99.0 : now - _successAt!;
    final sinceFail = _failAt == null ? 99.0 : now - _failAt!;
    happy = _approach(happy, sinceSuccess < 2.5 ? 1 : 0, k);
    sad = _approach(sad, sinceFail < 1.8 ? 1 : 0, k);

    bounce = sinceSuccess < 1.2
        ? (math.sin(sinceSuccess * math.pi * 3)).abs() *
              16 *
              (1 - sinceSuccess / 1.2)
        : 0;
    shake = sinceFail < 0.7
        ? math.sin(sinceFail * math.pi * 8) * 9 * (1 - sinceFail / 0.7)
        : 0;
    tail = math.sin(now * (happy > 0.5 ? 12 : 2)) * (0.25 + happy * 0.6);

    // Parpadeo aleatorio
    if (now > _nextBlink) {
      _blinkAt = now;
      _nextBlink = now + 2.5 + _random.nextDouble() * 2.5;
    }
    final sinceBlink = _blinkAt == null ? 99.0 : now - _blinkAt!;
    blink = sinceBlink < 0.16 ? math.sin(sinceBlink / 0.16 * math.pi) : 0;

    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRect(
        child: CustomPaint(
          painter: _CatPainter(
            look: look,
            checking: checking,
            hands: hands,
            happy: happy,
            sad: sad,
            blink: blink,
            bounce: bounce,
            shake: shake,
            tail: tail,
          ),
        ),
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  _CatPainter({
    required this.look,
    required this.checking,
    required this.hands,
    required this.happy,
    required this.sad,
    required this.blink,
    required this.bounce,
    required this.shake,
    required this.tail,
  });

  final double look, checking, hands, happy, sad, blink, bounce, shake, tail;

  static const fur = Color(0xFFF4A259);
  static const furDark = Color(0xFFD9822B);
  static const cream = Color(0xFFFFF1DC);
  static const pink = Color(0xFFF48FB1);
  static const ink = Color(0xFF3E2723);
  static const scarf = Color(0xFF2E7D32);
  static const iris = Color(0xFF7CB342);

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 200; // escala
    canvas.save();
    canvas.translate(size.width / 2 + shake * s, -bounce * s);
    canvas.scale(s);

    const hy = 92.0; // centro de la cabeza
    const base = 200.0;

    // Cola
    canvas.save();
    canvas.translate(50, base - 10);
    canvas.rotate(tail);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(55, -10, 45, -70);
    canvas.drawPath(tailPath, _stroke(furDark, 16));
    canvas.drawPath(tailPath, _stroke(fur, 11));
    canvas.restore();

    // Cuerpo
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, base + 35),
        width: 150,
        height: 120,
      ),
      _fill(fur),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, base + 40),
        width: 80,
        height: 90,
      ),
      _fill(cream),
    );

    // Orejas (se caen cuando está triste)
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side * 42, hy - 38);
      canvas.rotate(side * (0.15 + sad * 0.55));
      final ear = Path()
        ..moveTo(-24, 12)
        ..lineTo(side * 4, -48)
        ..lineTo(24, 12)
        ..close();
      canvas.drawPath(ear, _fill(fur));
      final inner = Path()
        ..moveTo(-12, 6)
        ..lineTo(side * 3, -30)
        ..lineTo(12, 6)
        ..close();
      canvas.drawPath(inner, _fill(pink));
      canvas.restore();
    }

    // Cabeza
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, hy), width: 150, height: 124),
      _fill(fur),
    );
    // Rayitas de gato atigrado
    for (final dx in [-14.0, 0.0, 14.0]) {
      canvas.drawLine(
        Offset(dx, hy - 58),
        Offset(dx * 0.8, hy - 42),
        _stroke(furDark, 5),
      );
    }
    // Hocico
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, hy + 26), width: 66, height: 42),
      _fill(cream),
    );
    // Mejillas
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(side * 48, hy + 18),
        10,
        _fill(pink.withValues(alpha: 0.3 + happy * 0.4)),
      );
    }

    // Ojos
    for (final side in [-1.0, 1.0]) {
      final ex = side * 30;
      const ey = hy - 4;
      if (happy > 0.5) {
        final p = Path()
          ..moveTo(ex - 13, ey + 5)
          ..quadraticBezierTo(ex, ey - 12, ex + 13, ey + 5);
        canvas.drawPath(p, _stroke(ink, 4.5));
        continue;
      }
      final open = (1 - blink).clamp(0.08, 1.0);
      final eyeRect = Rect.fromCenter(
        center: Offset(ex, ey),
        width: 30,
        height: 34 * open,
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(eyeRect));
      canvas.drawOval(eyeRect, _fill(Colors.white));
      final px = ex + look * 7;
      final py = ey + checking * 6;
      canvas.drawCircle(Offset(px, py), 10, _fill(iris));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py), width: 5, height: 14),
        _fill(ink),
      );
      canvas.drawCircle(Offset(px + 3, py - 4), 2.5, _fill(Colors.white));
      // Párpado triste
      if (sad > 0.02) {
        canvas.drawRect(
          Rect.fromLTWH(ex - 16, ey - 18, 32, sad * 13),
          _fill(fur),
        );
      }
      canvas.restore();
      canvas.drawOval(eyeRect, _stroke(ink, 2));
      // Cejas tristes
      if (sad > 0.05) {
        canvas.drawLine(
          Offset(ex - side * 12, ey - 22 + sad * 2),
          Offset(ex + side * 8, ey - 26 - sad * 4),
          _stroke(ink.withValues(alpha: sad), 3),
        );
      }
    }

    // Lágrima
    if (sad > 0.3) {
      final ty = hy + 14 + sad * 10;
      final tear = Path()
        ..moveTo(-36, ty - 8)
        ..quadraticBezierTo(-42, ty, -36, ty + 4)
        ..quadraticBezierTo(-30, ty, -36, ty - 8);
      canvas.drawPath(
        tear,
        _fill(const Color(0xFF4FC3F7).withValues(alpha: sad)),
      );
    }

    // Nariz
    final nose = Path()
      ..moveTo(-7, hy + 12)
      ..lineTo(7, hy + 12)
      ..lineTo(0, hy + 20)
      ..close();
    canvas.drawPath(nose, _fill(pink));

    // Boca
    if (happy > 0.5) {
      final mouth = Path()
        ..moveTo(-14, hy + 26)
        ..quadraticBezierTo(0, hy + 48, 14, hy + 26)
        ..close();
      canvas.drawPath(mouth, _fill(const Color(0xFFB71C1C)));
      canvas.drawCircle(const Offset(0, hy + 36), 5, _fill(pink));
    } else if (sad > 0.5) {
      final mouth = Path()
        ..moveTo(-11, hy + 34)
        ..quadraticBezierTo(0, hy + 24, 11, hy + 34);
      canvas.drawPath(mouth, _stroke(ink, 2.5));
    } else {
      final mouth = Path()
        ..moveTo(0, hy + 20)
        ..lineTo(0, hy + 25)
        ..moveTo(-11, hy + 27)
        ..quadraticBezierTo(-5, hy + 33, 0, hy + 25)
        ..quadraticBezierTo(5, hy + 33, 11, hy + 27);
      canvas.drawPath(mouth, _stroke(ink, 2.5));
    }

    // Bigotes
    for (final side in [-1.0, 1.0]) {
      for (final i in [-1.0, 0.0, 1.0]) {
        canvas.drawLine(
          Offset(side * 30, hy + 24 + i * 6),
          Offset(side * 76, hy + 16 + i * 11),
          _stroke(ink.withValues(alpha: 0.7), 1.6),
        );
      }
    }

    // Pañoleta verde de tendero
    final bandana = Path()
      ..moveTo(-58, hy + 52)
      ..quadraticBezierTo(0, hy + 70, 58, hy + 52)
      ..lineTo(0, hy + 100)
      ..close();
    canvas.drawPath(bandana, _fill(scarf));
    canvas.drawCircle(const Offset(-14, hy + 70), 3, _fill(Colors.white70));
    canvas.drawCircle(const Offset(12, hy + 64), 3, _fill(Colors.white70));
    canvas.drawCircle(const Offset(0, hy + 84), 3, _fill(Colors.white70));

    // Patitas: suben para taparse los ojos
    for (final side in [-1.0, 1.0]) {
      final rest = Offset(side * 50, base + 18);
      final up = Offset(side * 28, hy - 2);
      final paw = Offset.lerp(rest, up, hands)!;
      final shoulder = Offset(side * 60, base + 20);
      canvas.drawLine(shoulder, paw, _stroke(furDark, 30));
      canvas.drawLine(shoulder, paw, _stroke(fur, 25));
      canvas.drawCircle(paw, 22, _fill(fur));
      canvas.drawCircle(paw, 22, _stroke(furDark, 2));
      canvas.drawCircle(paw + const Offset(0, 5), 7, _fill(pink));
      for (final dx in [-9.0, 0.0, 9.0]) {
        canvas.drawCircle(paw + Offset(dx, -8), 3.5, _fill(pink));
      }
    }

    // Destellos al festejar
    if (happy > 0.05) {
      final spark = _fill(const Color(0xFFFFC107).withValues(alpha: happy));
      for (final o in const [
        Offset(-95, 40),
        Offset(92, 30),
        Offset(-82, 130),
        Offset(100, 115),
      ]) {
        final star = Path()
          ..moveTo(o.dx, o.dy - 9)
          ..lineTo(o.dx + 3, o.dy - 3)
          ..lineTo(o.dx + 9, o.dy)
          ..lineTo(o.dx + 3, o.dy + 3)
          ..lineTo(o.dx, o.dy + 9)
          ..lineTo(o.dx - 3, o.dy + 3)
          ..lineTo(o.dx - 9, o.dy)
          ..lineTo(o.dx - 3, o.dy - 3)
          ..close();
        canvas.drawPath(star, spark);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CatPainter old) => true;
}
