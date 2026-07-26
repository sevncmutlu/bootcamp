import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:maki_app/features/gamification/domain/entities/leaderboard_entity.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    required this.userLevel,
    super.key,
  });
  final int userLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.leaderboardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: LeaderboardView(
        userLevel: userLevel,
      ),
    );
  }
}

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    required this.userLevel,
    super.key,
  });

  final int userLevel;

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<GamificationBloc>().add(const LoadLeaderboardEvent());
  }



  Widget _buildFilters(
      BuildContext context, AppLocalizations l10n, ThemeData theme, String ageBand, String householdBand) {
    return Row(
      children: [
        Expanded(
          child: _FilterDropdown(
            label: l10n.leaderboardAgeBandLabel,
            value: ageBand,
            items: const [
              DropdownMenuItem(value: '18-24', child: Text('18-24')),
              DropdownMenuItem(value: '25-34', child: Text('25-34')),
              DropdownMenuItem(value: '35-44', child: Text('35-44')),
              DropdownMenuItem(value: '45-54', child: Text('45-54')),
              DropdownMenuItem(value: '55+', child: Text('55+')),
            ],
            onChanged: (v) {
              context.read<GamificationBloc>().add(
                UpdateLeaderboardFiltersEvent(ageBand: v),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FilterDropdown(
            label: l10n.leaderboardHouseholdBandLabel,
            value: householdBand,
            items: const [
              DropdownMenuItem(value: '1', child: Text('1')),
              DropdownMenuItem(value: '2', child: Text('2')),
              DropdownMenuItem(value: '3+', child: Text('3+')),
            ],
            onChanged: (v) {
              context.read<GamificationBloc>().add(
                UpdateLeaderboardFiltersEvent(householdBand: v),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, state) {
        final leaderboard = state.leaderboard;
        final isLoading = state.isLeaderboardLoading;
        final ageBand = state.leaderboardAgeBand;
        final householdBand = state.leaderboardHouseholdBand;

        bool isEstimated = false;

        if (leaderboard != null && !leaderboard.available) {
          isEstimated = true;
        }

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.leaderboardSelectDemographics,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.leaderboardSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilters(
                      context,
                      l10n,
                      theme,
                      ageBand,
                      householdBand,
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && leaderboard == null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<GamificationBloc>().add(const LoadLeaderboardEvent());
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.leaderboardCalculateCta),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (leaderboard != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _StandingCard(
                    standing: leaderboard,
                    trees: widget.userLevel,
                    level: widget.userLevel,
                    isEstimated: isEstimated,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({
    required this.standing,
    required this.trees,
    required this.level,
    this.isEstimated = false,
  });

  final LeaderboardEntity standing;
  final int trees;
  final int level;
  final bool isEstimated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final percentile = standing.percentile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            if (isEstimated)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.leaderboardEstimateNote,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            Text(
              l10n.leaderboardYourStanding,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              percentile != null
                  ? l10n.leaderboardPercentile(percentile)
                  : l10n.cohortNotEnough,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.anonymousCohort(standing.cohortSize),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.leaderboardTrees(trees)} · ${l10n.currentLevel(level)}',
              style: theme.textTheme.bodySmall,
            ),

          ],
        ),
      ),
    );
  }
}

