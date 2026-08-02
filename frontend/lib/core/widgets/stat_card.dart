import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.footer,
    this.gradient,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? footer;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final brightness = theme.brightness;
    final grad = gradient ?? AppGradients.hero(palette);

    return Container(
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        boxShadow: AppShadows.soft(brightness, theme.colorScheme.primary),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CanopyMotifPainter(theme.colorScheme.tertiary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      child: footer!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanopyMotifPainter extends CustomPainter {
  const _CanopyMotifPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.92, size.height * 0.2);
    for (var radius = 32.0; radius < size.width * 0.7; radius += 28) {
      canvas.drawCircle(center, radius, ring);
    }

    final trail = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.72,
        size.width * 0.76,
        size.height * 0.82,
        size.width,
        size.height * 0.5,
      );
    canvas.drawPath(
      trail,
      Paint()
        ..color = accent.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CanopyMotifPainter oldDelegate) =>
      accent != oldDelegate.accent;
}
