import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class NetBalanceCard extends StatelessWidget {
  const NetBalanceCard({
    super.key,
    required this.netBalance,
    required this.totalIncome,
    required this.totalExpenses,
  });

  final double netBalance;
  final double totalIncome;
  final double totalExpenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.makiPalette;
    final l10n = AppLocalizations.of(context)!;
    final positive = netBalance >= 0;

    return Semantics(
      container: true,
      label: '${l10n.netBalance}: ${formatTL(netBalance, context: context)}',
      child: Container(
        decoration: BoxDecoration(
          gradient: palette.heroGradient,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          boxShadow: AppShadows.soft(
            theme.brightness,
            theme.colorScheme.primary,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GrowthLedgerPainter(theme.colorScheme.tertiary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.netBalance,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.11),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(AppRadius.pill),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phonelink_lock_rounded,
                                size: 14,
                                color: Color(0xFFE7F4EA),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.localFirstLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFFE7F4EA),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatTL(netBalance, context: context),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: positive
                              ? Colors.white
                              : const Color(0xFFFFD9CE),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: _BalanceMetric(
                            icon: Icons.south_west_rounded,
                            label: l10n.totalIncome,
                            value: formatTL(totalIncome, context: context),
                            accent: Color.lerp(
                              palette.income,
                              Colors.white,
                              0.44,
                            )!,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _BalanceMetric(
                            icon: Icons.north_east_rounded,
                            label: l10n.totalExpense,
                            value: formatTL(totalExpenses, context: context),
                            accent: Color.lerp(
                              palette.expense,
                              Colors.white,
                              0.36,
                            )!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthLedgerPainter extends CustomPainter {
  const _GrowthLedgerPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final center = Offset(size.width * 0.92, size.height * 0.16);
    for (var radius = 34.0; radius < size.width * 0.72; radius += 28) {
      canvas.drawCircle(center, radius, ring);
    }

    final path = Path()
      ..moveTo(-12, size.height * 0.83)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.45,
        size.height * 1.08,
        size.width * 0.72,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.62,
        size.width * 0.88,
        size.height * 0.48,
        size.width + 16,
        size.height * 0.44,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GrowthLedgerPainter oldDelegate) =>
      accent != oldDelegate.accent;
}
