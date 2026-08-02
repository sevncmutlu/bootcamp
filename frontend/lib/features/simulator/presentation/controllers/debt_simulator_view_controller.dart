part of '../pages/debt_simulator_screen.dart';

extension _DebtSimulatorViewController on _DebtSimulatorScreenState {
  Widget _buildSimulatorView(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: MakiAppBarTitle(title: l10n.simulatorTitle),
        centerTitle: false,
      ),
      body: MakiBackground(
        child: BlocConsumer<SimulatorBloc, SimulatorState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error ?? l10n.simulatorError)),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GoalRouteBanner(
                    primaryGoal: widget.primaryGoal,
                    surface: GoalRouteSurface.simulator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.simulatorSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.extraBudget,
                              prefixIcon: const Icon(
                                Icons.account_balance_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.labelStrategy,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StrategyOption(
                            title: l10n.strategyAvalanche,
                            description: l10n.strategyAvalancheDescription,
                            icon: Icons.trending_down_rounded,
                            selected: state.strategy == 'avalanche',
                            onTap: () {
                              context.read<SimulatorBloc>().add(
                                const UpdateStrategyEvent('avalanche'),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _StrategyOption(
                            title: l10n.strategySnowball,
                            description: l10n.strategySnowballDescription,
                            icon: Icons.snowing,
                            selected: state.strategy == 'snowball',
                            onTap: () {
                              context.read<SimulatorBloc>().add(
                                const UpdateStrategyEvent('snowball'),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _StrategyOption(
                            title: 'Aylık yükü hafiflet',
                            description:
                                'Yakında kapanacak ve aylık ödemesi yüksek borçlara öncelik verir.',
                            icon: Icons.air_rounded,
                            selected: state.strategy == 'relief',
                            onTap: () => context.read<SimulatorBloc>().add(
                              const UpdateStrategyEvent('relief'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StrategyOption(
                            title: 'Dengeli ilerle',
                            description:
                                'Faizi gözetir, artan parayı açık borçlara dengeli dağıtır.',
                            icon: Icons.balance_rounded,
                            selected: state.strategy == 'balanced',
                            onTap: () => context.read<SimulatorBloc>().add(
                              const UpdateStrategyEvent('balanced'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _StrategyOption(
                            title: 'Eklediğim sırayı izle',
                            description:
                                'Borçları listeye eklediğin sırayla kapatmaya çalışır.',
                            icon: Icons.format_list_numbered_rounded,
                            selected: state.strategy == 'manual',
                            onTap: () => context.read<SimulatorBloc>().add(
                              const UpdateStrategyEvent('manual'),
                            ),
                          ),
                          if (_customPlans.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Kaydettiğin yollar',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final plan in _customPlans) ...[
                              _StrategyOption(
                                title: plan.name,
                                description:
                                    '${_criterionLabels[plan.primary]} · ${_directionLabels[plan.primaryDirection]} · ${_allocationLabels[plan.allocation]}',
                                icon: Icons.route_rounded,
                                selected: state.strategy == plan.strategyCode,
                                onTap: () => context.read<SimulatorBloc>().add(
                                  UpdateStrategyEvent(plan.strategyCode),
                                ),
                                actions: [
                                  IconButton(
                                    tooltip: 'Kopyala',
                                    onPressed: () => _openPlanBuilder(
                                      existing: plan,
                                      duplicate: true,
                                    ),
                                    icon: const Icon(Icons.copy_rounded),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Plan seçenekleri',
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _openPlanBuilder(existing: plan);
                                      } else if (value == 'delete') {
                                        _deletePlan(plan, state);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Düzenle'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Sil'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _openPlanBuilder,
                            icon: const Icon(Icons.add_road_rounded),
                            label: const Text('Kendi yolunu çiz'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        l10n.debtListTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addDebtDialog,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addDebt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (state.debts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          l10n.noDebts,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...state.debts.map((debt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          key: ValueKey('borc-${debt.id}'),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        debt.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    IconButton(
                                      key: ValueKey('borc-sil-${debt.id}'),
                                      tooltip: l10n.deleteDebt,
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: () {
                                        context.read<SimulatorBloc>().add(
                                          RemoveDebtEvent(debt.id),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  formatTL(debt.balance, decimals: 0),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _DebtDetail(
                                      icon: Icons.payments_outlined,
                                      text:
                                          '${l10n.minPayment}: ${formatTL(debt.minPayment, decimals: 0)}',
                                    ),
                                    _DebtDetail(
                                      icon: Icons.percent_rounded,
                                      text:
                                          '${l10n.interestRateAbbr}: ${debt.interestRate}%',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: state.debts.isNotEmpty && !state.isLoading
                        ? () => context.read<SimulatorBloc>().add(
                            SimulatePayoffEvent(),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l10n.simulateButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),

                  if (state.result != null) ...[
                    const Divider(height: 40),
                    StatCard(
                      label: l10n.monthsToFree,
                      value: '${state.result!.monthsToFree}',
                      icon: Icons.event_available_outlined,
                      footer: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.totalInterest),
                          Text(
                            formatTL(state.result!.totalInterestPaid),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.result!.successProbability != null)
                      Card(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.psychology_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.feasibilityLabel,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Money.formatRatioAsPercent(
                                        state.result!.successProbability!,
                                      ),
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.predictedByLgbm,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    if (state.result!.schedule.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.result!.schedule.length > 12
                            ? 12
                            : state
                                  .result!
                                  .schedule
                                  .length, // Önizleme ilk 12 ayla sınırlıdır.
                        itemBuilder: (context, index) {
                          final item = state.result!.schedule[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${item.month}'),
                              ),
                              title: Text(l10n.payoffMonthLabel(item.month)),
                              trailing: Text(
                                formatTL(item.remainingBalance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
