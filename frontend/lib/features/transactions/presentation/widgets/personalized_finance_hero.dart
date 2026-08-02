part of 'personalized_finance_overview.dart';

class _FinanceHeroPager extends StatefulWidget {
  const _FinanceHeroPager({
    required this.financeCard,
    this.savingsGoal,
    this.onOpenSavingsGoal,
  });

  final Widget financeCard;
  final SavingsGoalView? savingsGoal;
  final VoidCallback? onOpenSavingsGoal;

  @override
  State<_FinanceHeroPager> createState() => _FinanceHeroPagerState();
}

class _FinanceHeroPagerState extends State<_FinanceHeroPager> {
  int _page = 0;

  void _showPage(int page) {
    if (page == _page || (page == 1 && widget.savingsGoal == null)) return;
    setState(() => _page = page);
  }

  @override
  void didUpdateWidget(covariant _FinanceHeroPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.savingsGoal == null && _page != 0) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.savingsGoal;
    if (goal == null) return widget.financeCard;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final theme = Theme.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';

    return Column(
      key: const ValueKey('finance-overview-pager'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -120) _showPage(1);
            if (velocity > 120) _showPage(0);
          },
          child: AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(_page == 0 ? -0.035 : 0.035, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _page == 0
                  ? KeyedSubtree(
                      key: const ValueKey('finance-overview-page'),
                      child: widget.financeCard,
                    )
                  : _SavingsGoalDashboardCard(
                      key: const ValueKey('savings-goal-page'),
                      goal: goal,
                      onOpenGoal: widget.onOpenSavingsGoal,
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: isTurkish ? 'Finans kartı sayfaları' : 'Finance card pages',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: 4,
            children: [
              _PagerChoice(
                key: const ValueKey('finance-page-dot-0'),
                selected: _page == 0,
                label: isTurkish ? 'Finans özeti' : 'Finance summary',
                onTap: () => _showPage(0),
              ),
              _PagerChoice(
                key: const ValueKey('finance-page-dot-1'),
                selected: _page == 1,
                label: isTurkish ? 'Hedefe kalan yol' : 'Goal journey',
                onTap: () => _showPage(1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isTurkish
              ? 'Kartı kaydırabilir veya sayfa adına dokunabilirsin.'
              : 'Swipe the card or tap a page name.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PagerChoice extends StatelessWidget {
  const _PagerChoice({
    super.key,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
