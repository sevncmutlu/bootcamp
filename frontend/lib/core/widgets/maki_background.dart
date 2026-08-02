import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A quiet, responsive canvas shared by Maki's top-level product screens.
///
/// The rings are not decoration for decoration's sake: they repeat the
/// product's core metaphor of small financial actions becoming visible growth.
class MakiBackground extends StatelessWidget {
  const MakiBackground({
    super.key,
    required this.child,
    this.maxContentWidth = 760,
    this.showRings = true,
  });

  final Widget child;
  final double maxContentWidth;
  final bool showRings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.min(maxContentWidth, constraints.maxWidth);
          return Stack(
            fit: StackFit.expand,
            children: [
              if (showRings)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _GrowthRingPainter(
                      ringColor: scheme.primary,
                      glowColor: scheme.tertiary,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GrowthRingPainter extends CustomPainter {
  const _GrowthRingPainter({required this.ringColor, required this.glowColor});

  final Color ringColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final topRight = Offset(size.width + 30, -18);
    for (var radius = 72.0; radius <= 260; radius += 34) {
      canvas.drawCircle(topRight, radius, ringPaint);
    }

    final lowerLeft = Offset(-28, size.height * 0.76);
    for (var radius = 56.0; radius <= 180; radius += 31) {
      canvas.drawCircle(lowerLeft, radius, ringPaint);
    }

    canvas.save();
    canvas.translate(size.width * 0.12, size.height * 0.18);
    canvas.rotate(-0.48);
    canvas.drawOval(const Rect.fromLTWH(-34, -9, 68, 18), accentPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GrowthRingPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.glowColor != glowColor;
}
