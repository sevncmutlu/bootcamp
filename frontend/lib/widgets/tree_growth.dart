import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';

class TreeGrowth extends StatelessWidget {
  const TreeGrowth({super.key, required this.level, this.size = 160});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _TreeGrowthPainter(level: level, isDark: isDark),
      ),
    );
  }
}

class _TreeGrowthPainter extends CustomPainter {
  _TreeGrowthPainter({required this.level, required this.isDark});

  final int level;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.82;

    final soil = Paint()
      ..color = ForestColors.bark.withValues(alpha: isDark ? 0.55 : 0.85);
    final moundPath = Path()
      ..moveTo(w * 0.12, groundY)
      ..quadraticBezierTo(w * 0.5, groundY - h * 0.10, w * 0.88, groundY)
      ..lineTo(w * 0.88, groundY + h * 0.06)
      ..lineTo(w * 0.12, groundY + h * 0.06)
      ..close();
    canvas.drawPath(moundPath, soil);

    final trunk = Paint()
      ..color = ForestColors.bark
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafDark = Paint()..color = ForestColors.canopy;
    final leafMid = Paint()..color = ForestColors.fern;
    final leafLight = Paint()..color = ForestColors.moss;

    void canopyCluster(Offset c, double r) {
      canvas.drawCircle(c, r, leafDark);
      canvas.drawCircle(c.translate(-r * 0.6, r * 0.1), r * 0.75, leafMid);
      canvas.drawCircle(c.translate(r * 0.6, r * 0.15), r * 0.7, leafMid);
      canvas.drawCircle(c.translate(0, -r * 0.5), r * 0.7, leafLight);
    }

    final cx = w * 0.5;

    if (level <= 1) {
      final seed = Paint()..color = ForestColors.emeraldDark;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, groundY - h * 0.02),
          width: w * 0.16,
          height: w * 0.22,
        ),
        seed,
      );
      canvas.drawCircle(Offset(cx, groundY - h * 0.14), w * 0.05, leafLight);
      return;
    }

    if (level == 2) {
      trunk.strokeWidth = w * 0.045;
      canvas.drawLine(
        Offset(cx, groundY),
        Offset(cx, groundY - h * 0.28),
        trunk,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx - w * 0.12, groundY - h * 0.24),
          width: w * 0.2,
          height: w * 0.12,
        ),
        leafMid,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + w * 0.12, groundY - h * 0.30),
          width: w * 0.2,
          height: w * 0.12,
        ),
        leafLight,
      );
      return;
    }

    if (level == 3) {
      trunk.strokeWidth = w * 0.06;
      canvas.drawLine(
        Offset(cx, groundY),
        Offset(cx, groundY - h * 0.42),
        trunk,
      );
      canopyCluster(Offset(cx, groundY - h * 0.52), w * 0.16);
      return;
    }

    if (level == 4) {
      trunk.strokeWidth = w * 0.09;
      canvas.drawLine(
        Offset(cx, groundY),
        Offset(cx, groundY - h * 0.46),
        trunk,
      );
      canopyCluster(Offset(cx, groundY - h * 0.54), w * 0.24);
      return;
    }

    trunk.strokeWidth = w * 0.05;
    canvas.drawLine(
      Offset(w * 0.28, groundY),
      Offset(w * 0.28, groundY - h * 0.30),
      trunk,
    );
    canvas.drawLine(
      Offset(w * 0.72, groundY),
      Offset(w * 0.72, groundY - h * 0.34),
      trunk,
    );
    trunk.strokeWidth = w * 0.09;
    canvas.drawLine(Offset(cx, groundY), Offset(cx, groundY - h * 0.46), trunk);
    canopyCluster(Offset(w * 0.28, groundY - h * 0.38), w * 0.15);
    canopyCluster(Offset(w * 0.72, groundY - h * 0.42), w * 0.15);
    canopyCluster(Offset(cx, groundY - h * 0.54), w * 0.22);
  }

  @override
  bool shouldRepaint(covariant _TreeGrowthPainter old) =>
      old.level != level || old.isDark != isDark;
}
