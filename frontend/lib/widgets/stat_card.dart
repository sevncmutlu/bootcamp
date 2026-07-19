import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';

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
    final brightness = Theme.of(context).brightness;
    final grad = gradient ?? AppGradients.hero(brightness);

    return Container(
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: AppRadius.card,
        boxShadow: AppShadows.soft(brightness),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CanopyMotifPainter())),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 60, paint);
    canvas.drawCircle(Offset(size.width * 1.02, size.height * 0.6), 80, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.9), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
