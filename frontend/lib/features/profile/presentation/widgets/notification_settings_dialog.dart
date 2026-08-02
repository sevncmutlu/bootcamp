import 'package:flutter/material.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/features/profile/data/services/smart_notification_service.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
  late final SmartNotificationService _notificationService;
  bool _isSmartEnabled = false;
  int _optimalHour = 9;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService = di.sl<SmartNotificationService>();
    _loadState();
  }

  Future<void> _loadState() async {
    final hour = await _notificationService.currentOptimalHour();
    if (!mounted) return;
    setState(() {
      _optimalHour = hour;
      _isSmartEnabled = _notificationService.isEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggle(bool requested) async {
    final enabled = requested
        ? await _notificationService.requestAndEnable()
        : false;
    if (!requested) await _notificationService.disable();
    if (!mounted) return;
    setState(() => _isSmartEnabled = enabled);
    if (requested && !enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bildirim izni verilmedi; akıllı hatırlatmalar kapalı kaldı.',
          ),
        ),
      );
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
                'Maki, cihazındaki kullanım ritmine göre günde en fazla bir '
                'sakin hatırlatma planlar. Veriler cihazdan çıkmaz.',
                style: theme.textTheme.bodySmall,
              ),
              value: _isSmartEnabled,
              onChanged: _toggle,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 24),
            if (_isSmartEnabled)
              Card(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.2,
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sessiz saatler 21.00–09.00 arasında korunur.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.closeButton),
        ),
      ],
    );
  }
}
