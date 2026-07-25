import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/maki_api_client.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/widgets/mascot.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({
    required this.scoreBasisPoints,
    required this.userLevel,
    super.key,
  });

  final int scoreBasisPoints;
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
        scoreBasisPoints: scoreBasisPoints,
        userLevel: userLevel,
      ),
    );
  }
}

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({
    required this.scoreBasisPoints,
    required this.userLevel,
    super.key,
  });

  final int scoreBasisPoints;
  final int userLevel;

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView>
    with AutomaticKeepAliveClientMixin {
  static const _storage = FlutterSecureStorage();
  static const _ageBandKey = 'maki_leaderboard_age_band';
  static const _householdKey = 'maki_leaderboard_household_band';

  String _ageBand = '25-34';
  String _householdBand = '1';
  LeaderboardStanding? _standing;
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  @override
  void didUpdateWidget(covariant LeaderboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scoreBasisPoints != widget.scoreBasisPoints) {
      _loadStanding();
    }
  }

  Future<void> _initAndLoad() async {
    try {
      final savedAge = await _storage.read(key: _ageBandKey);
      final savedHousehold = await _storage.read(key: _householdKey);
      if (mounted) {
        setState(() {
          if (savedAge != null) _ageBand = savedAge;
          if (savedHousehold != null) _householdBand = savedHousehold;
        });
      }
    } catch (_) {}
    await _loadStanding();
  }

  Future<void> _onAgeBandChanged(String? value) async {
    if (value == null || value == _ageBand) return;
    setState(() => _ageBand = value);
    await _storage.write(key: _ageBandKey, value: value);
    await _loadStanding();
  }

  Future<void> _onHouseholdBandChanged(String? value) async {
    if (value == null || value == _householdBand) return;
    setState(() => _householdBand = value);
    await _storage.write(key: _householdKey, value: value);
    await _loadStanding();
  }

  bool _isEstimated = false;

  int _estimatePercentile(int scoreBasisPoints) {
    if (scoreBasisPoints <= 0) return 25;
    final savingsPercent = (scoreBasisPoints / 100).round();
    final raw = (100 - savingsPercent * 0.85).clamp(5, 95).round();
    return (raw / 5).round() * 5;
  }

  Future<void> _loadStanding() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final standing = await MakiApi.instance.leaderboard(
        ageBand: _ageBand,
        householdBand: _householdBand,
        scoreBasisPoints: widget.scoreBasisPoints,
      );
      if (mounted) {
        if (!standing.available) {
          final estimatedPercentile = _estimatePercentile(widget.scoreBasisPoints);
          setState(() {
            _standing = LeaderboardStanding(
              available: true,
              percentile: estimatedPercentile,
              cohortSize: standing.cohortSize,
            );
            _isEstimated = true;
          });
        } else {
          setState(() {
            _standing = standing;
            _isEstimated = false;
          });
        }
      }
    } on MakiApiException catch (error, stackTrace) {
      developer.log(
        'Anonim karşılaştırma tamamlanamadı.',
        error: error.code,
        stackTrace: stackTrace,
        name: 'LeaderboardView',
      );
      if (mounted) {
        final estimatedPercentile = _estimatePercentile(widget.scoreBasisPoints);
        setState(() {
          _standing = LeaderboardStanding(
            available: true,
            percentile: estimatedPercentile,
            cohortSize: '50-99',
          );
          _isEstimated = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        final estimatedPercentile = _estimatePercentile(widget.scoreBasisPoints);
        setState(() {
          _standing = LeaderboardStanding(
            available: true,
            percentile: estimatedPercentile,
            cohortSize: '50-99',
          );
          _isEstimated = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trees = widget.userLevel <= 1
        ? 0
        : widget.userLevel == 2
        ? 1
        : widget.userLevel == 3
        ? 2
        : widget.userLevel - 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.leaderboardSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.leaderboardAgeBandLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final band in const ['18-24', '25-34', '35-44', '45-54', '55+']) ...[
                  ChoiceChip(
                    label: Text(band),
                    selected: _ageBand == band,
                    onSelected: (selected) {
                      if (selected) _onAgeBandChanged(band);
                    },
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.leaderboardHouseholdBandLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                label: Text(l10n.personSingle),
                selected: _householdBand == '1',
                onSelected: (selected) {
                  if (selected) _onHouseholdBandChanged('1');
                },
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.personDouble),
                selected: _householdBand == '2',
                onSelected: (selected) {
                  if (selected) _onHouseholdBandChanged('2');
                },
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.personMultiple),
                selected: _householdBand == '3+',
                onSelected: (selected) {
                  if (selected) _onHouseholdBandChanged('3+');
                },
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_standing case final standing?)
            _StandingCard(
              standing: standing,
              trees: trees,
              level: widget.userLevel,
              isEstimated: _isEstimated,
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

  final LeaderboardStanding standing;
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
            if (isEstimated) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.leaderboardEstimateNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

