import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/utils/currency.dart';

class NetBalanceCard extends StatelessWidget {
  final double netBalance;
  final double totalIncome;
  final double totalExpenses;

  const NetBalanceCard({
    super.key,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  primaryColor.withValues(alpha: 0.45),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                ]
              : [
                  primaryColor.withValues(alpha: 0.85),
                  primaryColor.withValues(alpha: 0.60),
                ],
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CardRiverWavePainter(
                  color: isDark ? primaryColor : Colors.white,
                  isDark: isDark,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.netBalance,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isDark ? primaryColor : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTL(netBalance, context: context),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: netBalance >= 0
                          ? (isDark ? primaryColor : Colors.white)
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: (isDark ? primaryColor : Colors.white).withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_downward_outlined,
                                size: 16,
                                color: isDark ? Colors.green : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.totalIncome,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? theme.textTheme.bodySmall?.color
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTL(totalIncome, context: context),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.green : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_upward_outlined,
                                size: 16,
                                color: isDark ? Colors.red : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.totalExpense,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? theme.textTheme.bodySmall?.color
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatTL(totalExpenses, context: context),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.red : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardRiverWavePainter extends CustomPainter {
  final Color color;
  final bool isDark;

  const _CardRiverWavePainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path1 = Path();
    path1.moveTo(0, h * 0.45);
    path1.cubicTo(w * 0.15, h * 0.30, w * 0.35, h * 0.35, w * 0.50, h * 0.60);
    path1.cubicTo(w * 0.65, h * 0.85, w * 0.40, h, w * 0.20, h);
    path1.lineTo(0, h);
    path1.close();

    final paint1 = Paint()
      ..color = color.withValues(alpha: isDark ? 0.15 : 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path1, paint1);

    final path2 = Path();
    path2.moveTo(w, h * 0.30);
    path2.cubicTo(w * 0.80, h * 0.20, w * 0.55, h * 0.45, w * 0.60, h * 0.75);
    path2.cubicTo(w * 0.65, h * 0.95, w * 0.85, h, w, h);
    path2.lineTo(w, h);
    path2.close();

    final paint2 = Paint()
      ..color = color.withValues(alpha: isDark ? 0.08 : 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);

    final path3 = Path();
    path3.moveTo(w * 0.30, 0);
    path3.cubicTo(w * 0.50, 0, w * 0.70, h * 0.25, w, h * 0.15);
    path3.lineTo(w, 0);
    path3.close();

    final paint3 = Paint()
      ..color = color.withValues(alpha: isDark ? 0.06 : 0.10)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(_CardRiverWavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isDark != isDark;
}
