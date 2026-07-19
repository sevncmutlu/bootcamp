import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/maki_api_client.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/widgets/mascot.dart';
import 'package:maki_app/widgets/privacy_notice.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    required this.scoreBasisPoints,
    required this.userLevel,
    super.key,
  });

  final int scoreBasisPoints;
  final int userLevel;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String? _ageBand;
  String? _householdBand;
  LeaderboardStanding? _standing;
  bool _isLoading = false;
  String? _error;

  Future<void> _loadStanding() async {
    if (_ageBand == null || _householdBand == null) {
      setState(() {
        _error = 'Anonim karşılaştırma için yaş ve hane grubunu seçin.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final standing = await MakiApi.instance.leaderboard(
        ageBand: _ageBand!,
        householdBand: _householdBand!,
        scoreBasisPoints: widget.scoreBasisPoints,
      );
      if (mounted) {
        setState(() => _standing = standing);
      }
    } on MakiApiException catch (error, stackTrace) {
      developer.log(
        'Anonim karşılaştırma tamamlanamadı.',
        error: error.code,
        stackTrace: stackTrace,
        name: 'LeaderboardScreen',
      );
      if (mounted) {
        setState(() => _error = error.userMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trees = widget.userLevel <= 1
        ? 0
        : widget.userLevel == 2
        ? 1
        : widget.userLevel == 3
        ? 2
        : widget.userLevel - 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.leaderboardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrivacyNotice(
              title: l10n.leaderboardPrivacyTitle,
              message: l10n.leaderboardSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _ageBand,
                      decoration: const InputDecoration(
                        labelText: 'Yaş grubu',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: '18-24', child: Text('18–24')),
                        DropdownMenuItem(value: '25-34', child: Text('25–34')),
                        DropdownMenuItem(value: '35-44', child: Text('35–44')),
                        DropdownMenuItem(value: '45-54', child: Text('45–54')),
                        DropdownMenuItem(value: '55+', child: Text('55+')),
                      ],
                      onChanged: (value) => setState(() => _ageBand = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _householdBand,
                      decoration: const InputDecoration(
                        labelText: 'Hane büyüklüğü',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('1 kişi')),
                        DropdownMenuItem(value: '2', child: Text('2 kişi')),
                        DropdownMenuItem(value: '3+', child: Text('3+ kişi')),
                      ],
                      onChanged: (value) =>
                          setState(() => _householdBand = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _loadStanding,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.query_stats_outlined),
                      label: const Text('Anonim durumumu hesapla'),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (_standing case final standing?)
              _StandingCard(
                standing: standing,
                trees: trees,
                level: widget.userLevel,
              )
            else
              Card(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const Mascot(pose: MascotPose.thinking, size: 44),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          l10n.leaderboardCohortPending,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({
    required this.standing,
    required this.trees,
    required this.level,
  });

  final LeaderboardStanding standing;
  final int trees;
  final int level;

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
            Text(
              l10n.leaderboardYourStanding,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              standing.available && percentile != null
                  ? l10n.leaderboardPercentile(percentile)
                  : 'Kohort henüz yeterli değil',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Anonim kohort: ${standing.cohortSize}',
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
