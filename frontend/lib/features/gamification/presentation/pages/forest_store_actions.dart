part of 'forest_screen.dart';

extension _ForestStoreActions on ForestScreenState {
  Future<void> _buyStoreItem(ForestStoreItemView item) async {
    try {
      await di.sl<LivingForestService>().buyItem(item.key);
      await _loadLivingForest();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} ormanına eklendi.')),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showForestStore() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Orman mağazası',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontFamily: 'MakiDisplay',
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      _ForestPointsBadge(balance: _livingForest.seedBalance),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kazandığın tohumlarla ormanına kalıcı dokunuşlar ekle.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ForestStorePanel(
                    snapshot: _livingForest,
                    onBuyItem: (item) async {
                      await _buyStoreItem(item);
                      if (sheetContext.mounted) setSheetState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCalendar() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const FinanceCalendarScreen()),
    );
  }

  Future<void> _openGoalMap(SavingsGoalView goal) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GoalWorldMapScreen(
          goal: goal,
          seedBalance: _livingForest.seedBalance,
          onContribute: () => _showContribution(goal),
        ),
      ),
    );
    if (changed == true) await _loadLivingForest();
  }

  void _claimXP(DailyChallengeEntity challenge) {
    if (!challenge.isCompleted || challenge.xpReward == 0) return;
    context.read<GamificationBloc>().add(ClaimXPEvent(challenge));
  }
}
