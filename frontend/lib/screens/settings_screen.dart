import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:maki_app/database/database.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/onboarding_service.dart';
import 'package:maki_app/services/premium_service.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/screens/notification_settings_dialog.dart';
import 'package:maki_app/screens/paywall_screen.dart';
import 'package:maki_app/screens/login_screen.dart';
import 'package:maki_app/screens/profile_screen.dart';
import 'package:maki_app/services/auth_service.dart';
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
  String _selectedAccent = 'forest';
  String _selectedLanguage = 'system';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final goal = await OnboardingService.instance.getPrimaryGoal();
    final premium = await PremiumService.instance.isPremium();
    final themeMode = await OnboardingService.instance.getThemeMode();
    final accent = await OnboardingService.instance.getAccent();
    final lang = await OnboardingService.instance.getLanguage();
    setState(() {
      _selectedGoal = goal ?? 'track_spending';
      _isPremium = premium;
      _selectedTheme = themeMode;
      _selectedAccent = accent;
      _selectedLanguage = lang;
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
          content: RadioGroup<String>(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: goals.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _getLanguageLabel(String langKey, AppLocalizations l10n) {
    switch (langKey) {
      case 'tr':
        return l10n.settingsLanguageTr;
      case 'en':
        return l10n.settingsLanguageEn;
      default:
        return l10n.settingsLanguageSystem;
    }
  }

  Future<void> _changeLanguageDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final languages = {
      'system': l10n.settingsLanguageSystem,
      'tr': l10n.settingsLanguageTr,
      'en': l10n.settingsLanguageEn,
    };

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.settingsLanguageTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: RadioGroup<String>(
            groupValue: _selectedLanguage,
            onChanged: (val) async {
              if (val != null) {
                final navigator = Navigator.of(context);
                final myAppState = MyApp.of(context);
                await OnboardingService.instance.setLanguage(val);
                Locale? loc;
                if (val == 'tr') loc = const Locale('tr');
                if (val == 'en') loc = const Locale('en');
                myAppState?.setLocale(loc);
                setState(() => _selectedLanguage = val);
                navigator.pop();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                );
              }).toList(),
            ),
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
          content: RadioGroup<String>(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: themes.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    _loadSettings();
  }

  String _getAccentLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'emerald':
        return l10n.accentEmerald;
      case 'sage':
        return l10n.accentSage;
      case 'navy':
        return l10n.accentNavy;
      case 'amber':
        return l10n.accentAmber;
      case 'purple':
        return l10n.accentPurple;
      case 'pink':
        return l10n.accentPink;
      case 'forest':
      default:
        return l10n.accentForest;
    }
  }

  Future<void> _changeAccentDialog() async {
    final l10n = AppLocalizations.of(context)!;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.settingsAccentTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settingsAccentDesc),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: BrandAccents.all.map((accent) {
                  final selected = accent.key == _selectedAccent;
                  return GestureDetector(
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final myAppState = MyApp.of(context);
                      await OnboardingService.instance.setAccent(accent.key);
                      myAppState?.setAccent(accent.color);
                      setState(() => _selectedAccent = accent.key);
                      navigator.pop();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accent.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _getAccentLabel(accent.key, l10n),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
    _loadSettings();
  }

  Future<void> _confirmReset() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final myAppState = MyApp.of(context);

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
      await OnboardingService.instance.resetAllSettings();
      await AuthService.instance.logout();
      myAppState?.setLocale(null);
      myAppState?.setThemeMode(ThemeMode.system);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MyApp()),
          (route) => false,
        );
      }
    }
  }

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/mascot/maki_avatar.webp');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }
    if (kIsWeb || avatarUrl.startsWith('blob:') || avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    }
    final file = File(avatarUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/mascot/maki_avatar.webp');
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
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              final user = AuthService.instance.currentUser;
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: _getAvatarImage(user?.avatarUrl),
                ),
                title: Text(
                  user?.displayName ?? l10n.guestUser,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  user?.email ?? l10n.loginSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  if (AuthService.instance.isLoggedIn) {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  } else {
                    await Navigator.of(context).push<bool?>(
                      MaterialPageRoute<bool?>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  }
                  if (mounted) setState(() {});
                },
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.track_changes_outlined),
            title: Text(l10n.settingsGoalTitle),
            subtitle: Text(_getGoalLabel(_selectedGoal, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeGoalDialog,
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.settingsLanguageTitle),
            subtitle: Text(_getLanguageLabel(_selectedLanguage, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeLanguageDialog,
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.settingsThemeTitle),
            subtitle: Text(_getThemeLabel(_selectedTheme, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeThemeDialog,
          ),
          const Divider(height: 1),

          ListTile(
            leading: Icon(
              Icons.format_color_fill_outlined,
              color: BrandAccents.colorForKey(_selectedAccent),
            ),
            title: Text(l10n.settingsAccentTitle),
            subtitle: Text(_getAccentLabel(_selectedAccent, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeAccentDialog,
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsNotificationsTitle),
            subtitle: Text(l10n.settingsNotificationsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => const NotificationSettingsDialog(),
              );
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Maki Pro'),
            subtitle: Text(
              _isPremium ? l10n.settingsProActive : l10n.settingsProInactive,
            ),
            trailing: _isPremium ? null : const Icon(Icons.chevron_right),
            onTap: () async {
              if (!_isPremium) {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
                if (result == true) {
                  _loadSettings();
                }
              }
            },
          ),
          if (kDebugMode)
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.settingsDevProAccess),
              value: _isPremium,
              onChanged: (val) async {
                await PremiumService.instance.setPremium(value: val);
                setState(() {
                  _isPremium = val;
                });
              },
            ),
          const Divider(height: 1),

          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              l10n.settingsResetTitle,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(l10n.settingsResetSubtitle),
            onTap: _confirmReset,
          ),
        ],
      ),
    );
  }
}
