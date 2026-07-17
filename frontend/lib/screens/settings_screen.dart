import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/onboarding_service.dart';
import 'package:maki_app/services/premium_service.dart';
import 'package:maki_app/screens/notification_settings_dialog.dart';
import 'package:maki_app/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedGoal = 'track_spending';
  bool _isPremium = false;
  String _selectedTheme = 'system';
  String? _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final goal = await OnboardingService.instance.getPrimaryGoal();
    final premium = await PremiumService.instance.isPremium();
    final themeMode = await OnboardingService.instance.getThemeMode();
    final langStr = await OnboardingService.instance.getAppLocale();
    setState(() {
      _selectedGoal = goal ?? 'track_spending';
      _isPremium = premium;
      _selectedTheme = themeMode;
      _selectedLanguage = langStr;
    });
  }

  String _getGoalLabel(String goalKey, AppLocalizations l10n) {
    switch (goalKey) {
      case 'track_spending':
        return l10n.goalTrack;
      case 'save_goal':
        return l10n.goalSave;
      case 'pay_debt':
        return l10n.goalDebt;
      case 'learn_invest':
        return l10n.goalInvest;
      default:
        return l10n.goalTrack;
    }
  }

  Future<void> _changeGoalDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final goals = {
      'track_spending': l10n.goalTrack,
      'save_goal': l10n.goalSave,
      'pay_debt': l10n.goalDebt,
      'learn_invest': l10n.goalInvest,
    };

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.onboardingSubtitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: goals.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: _selectedGoal,
                onChanged: (val) async {
                  if (val != null) {
                    final navigator = Navigator.of(context);
                    await OnboardingService.instance.setPrimaryGoal(val);
                    setState(() {
                      _selectedGoal = val;
                    });
                    navigator.pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getThemeLabel(String themeKey, AppLocalizations l10n) {
    switch (themeKey) {
      case 'light':
        return l10n.settingsThemeLight;
      case 'dark':
        return l10n.settingsThemeDark;
      default:
        return l10n.settingsThemeSystem;
    }
  }

  String _getLanguageLabel(String? langCode, AppLocalizations l10n) {
    final code = langCode ?? Localizations.localeOf(context).languageCode;
    if (code == 'tr') return l10n.settingsLanguageTurkish;
    return l10n.settingsLanguageEnglish;
  }

  Future<void> _changeThemeDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final activeThemeStr = await OnboardingService.instance.getThemeMode();

    final themes = {
      'system': l10n.settingsThemeSystem,
      'light': l10n.settingsThemeLight,
      'dark': l10n.settingsThemeDark,
    };

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.settingsThemeTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: themes.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: activeThemeStr,
                onChanged: (val) async {
                  if (val != null) {
                    final navigator = Navigator.of(context);
                    final myAppState = MyApp.of(context);
                    await OnboardingService.instance.setThemeMode(val);
                    ThemeMode mode;
                    switch (val) {
                      case 'light':
                        mode = ThemeMode.light;
                        break;
                      case 'dark':
                        mode = ThemeMode.dark;
                        break;
                      default:
                        mode = ThemeMode.system;
                    }
                    myAppState?.setThemeMode(mode);
                    navigator.pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
    _loadSettings();
  }

  Future<void> _changeLanguageDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final activeLangStr = await OnboardingService.instance.getAppLocale();

    final languages = {
      'en': l10n.settingsLanguageEnglish,
      'tr': l10n.settingsLanguageTurkish,
    };

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.settingsLanguageTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: activeLangStr ?? 'en',
                onChanged: (val) async {
                  if (val != null) {
                    final navigator = Navigator.of(context);
                    final myAppState = MyApp.of(context);
                    await OnboardingService.instance.setAppLocale(val);
                    myAppState?.setLocale(Locale(val));
                    navigator.pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
    _loadSettings();
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.resetDataTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.resetDataConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.clearButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.resetButtonLabel),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await AppDatabase.instance.clearAllData();
      await OnboardingService.instance.setCompletedOnboarding(false);
      await OnboardingService.instance.setPrimaryGoal('track_spending');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MyApp()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Onboarding Goal
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: Text(l10n.settingsGoalTitle),
            subtitle: Text(_getGoalLabel(_selectedGoal, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeGoalDialog,
          ),
          const Divider(height: 1),

          // App Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsThemeTitle),
            subtitle: Text(_getThemeLabel(_selectedTheme, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeThemeDialog,
          ),
          const Divider(height: 1),

          // Language Setting
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(_getLanguageLabel(_selectedLanguage, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLanguageDialog,
          ),
          const Divider(height: 1),

          // Notifications Alerts (Bandit)
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsNotificationsTitle),
            subtitle: Text(l10n.settingsNotificationsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const NotificationSettingsDialog(),
              );
            },
          ),
          const Divider(height: 1),

          // Subscription Toggle
          SwitchListTile(
            secondary: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Maki Pro'),
            subtitle: Text(_isPremium ? l10n.settingsProActive : l10n.settingsProInactive),
            value: _isPremium,
            onChanged: (val) async {
              await PremiumService.instance.setPremium(value: val);
              setState(() {
                _isPremium = val;
              });
            },
          ),
          const Divider(height: 1),

          // Reset Data Section
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
            title: Text(
              l10n.settingsResetTitle,
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(l10n.settingsResetSubtitle),
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }
}
