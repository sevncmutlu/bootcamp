import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/lints_bandit_service.dart';
import 'package:maki_app/theme/app_tokens.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  final _db = AppDatabase.instance;
  late final LintsBanditService _banditService;

  bool _isSmartEnabled = true;
  int _optimalHour = 9;
  String _selectedSimArm = 'morning';

  Map<String, BanditArmParams> _armParams = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _banditService = LintsBanditService(_db);
    _loadParams();
  }

  Future<void> _loadParams() async {
    setState(() => _isLoading = true);

    int hour = 9;
    final Map<String, BanditArmParams> params = {};

    try {
      hour = await _banditService.predictOptimalHour(DateTime.now());

      final states = await _db.getBanditStates();

      for (final arm in LintsBanditService.arms) {
        final match = states.firstWhere(
          (s) => s.arm == arm,
          orElse: () => NotificationBanditState(
            arm: arm,
            precisionMatrixJson: '[[1.0, 0.0], [0.0, 1.0]]',
            projectionVectorJson: '[0.0, 0.0]',
          ),
        );

        _parseBanditParams(match, params);
      }
    } catch (e) {
      developer.log(
        'Bildirim zamanlama parametreleri yüklenemedi.',
        error: e,
        name: 'NotificationSettingsDialog',
      );

      for (final arm in LintsBanditService.arms) {
        params[arm] = BanditArmParams(
          A: [
            [1.0, 0.0],
            [0.0, 1.0],
          ],
          b: [0.0, 0.0],
        );
      }
    }

    setState(() {
      _optimalHour = hour;
      _armParams = params;
      _isLoading = false;
    });
  }

  void _parseBanditParams(
    NotificationBanditState state,
    Map<String, BanditArmParams> params,
  ) {
    params[state.arm] = BanditArmParams.fromJson(
      precisionMatrixJson: state.precisionMatrixJson,
      projectionVectorJson: state.projectionVectorJson,
    );
  }

  Future<void> _simulateReward() async {
    final now = DateTime.now();

    await _banditService.updateFeedback(_selectedSimArm, now, 1.0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.rewardSuccess),
          backgroundColor: ForestColors.emerald,
        ),
      );
    }

    await _loadParams();
  }

  String _getArmDisplayName(BuildContext context, String arm) {
    final l10n = AppLocalizations.of(context)!;
    switch (arm) {
      case 'morning':
        return l10n.morningArm;
      case 'afternoon':
        return l10n.afternoonArm;
      case 'evening':
        return l10n.eveningArm;
      default:
        return arm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(
        l10n.settingsTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: Text(
                l10n.smartOptimizationEnable,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                l10n.smartOptimizationDesc,
                style: theme.textTheme.bodySmall,
              ),
              value: _isSmartEnabled,
              onChanged: (val) {
                setState(() {
                  _isSmartEnabled = val;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24),

            if (_isSmartEnabled) ...[
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.preferredTriggerHour,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.preferredTriggerHourValue(_optimalHour),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 20),

                Text(
                  l10n.precisionMatrixLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...LintsBanditService.arms.map((arm) {
                  final p = _armParams[arm];
                  if (p == null) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getArmDisplayName(context, arm),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "[b = [${p.b[0].toStringAsFixed(1)}, ${p.b[1].toStringAsFixed(1)}]]",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),

                Text(
                  l10n.simulationSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.simulationDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSimArm,
                        items: LintsBanditService.arms.map((arm) {
                          return DropdownMenuItem<String>(
                            value: arm,
                            child: Text(_getArmDisplayName(context, arm)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSimArm = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _simulateReward,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                      ),
                      child: Text(l10n.simulateOpenButton),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.closeButton),
        ),
      ],
    );
  }
}
