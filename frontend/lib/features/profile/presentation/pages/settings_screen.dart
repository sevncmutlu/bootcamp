import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/features/profile/presentation/widgets/notification_settings_dialog.dart';
import 'package:maki_app/features/premium/presentation/pages/paywall_screen.dart';
import 'package:maki_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/presentation/utils/avatar_utils.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_state.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsBloc>().add(LoadSettingsEvent());
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

  Future<void> _changeGoalDialog(String currentGoal) async {
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
                // ignore: deprecated_member_use
                groupValue: currentGoal,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) {
                    context.read<SettingsBloc>().add(UpdatePrimaryGoalEvent(val));
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _changeLanguageDialog(String currentLang) async {
    final l10n = AppLocalizations.of(context)!;
    final languages = {
      'system': l10n.settingsLanguageSystem,
      'tr': 'Türkçe',
      'en': 'English',
    };

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
                // ignore: deprecated_member_use
                groupValue: currentLang,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) {
                    context.read<SettingsBloc>().add(UpdateLanguageEvent(val));
                    final myAppState = MyApp.of(context);
                    Locale? loc;
                    if (val == 'tr') loc = const Locale('tr');
                    if (val == 'en') loc = const Locale('en');
                    myAppState?.setLocale(loc);
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getLanguageLabel(String langKey, AppLocalizations l10n) {
    switch (langKey) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'system':
      default:
        return l10n.settingsLanguageSystem;
    }
  }

  Future<void> _changeThemeDialog(String currentTheme) async {
    final l10n = AppLocalizations.of(context)!;

    final themes = {
      'system': l10n.settingsThemeSystem,
      'light': l10n.settingsThemeLight,
      'dark': l10n.settingsThemeDark,
    };

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
                // ignore: deprecated_member_use
                groupValue: currentTheme,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  if (val != null) {
                    context.read<SettingsBloc>().add(UpdateThemeModeEvent(val));
                    final myAppState = MyApp.of(context);
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
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getAccentLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'forest':
        return 'Forest (Maki Yeşil)';
      case 'ocean':
        return 'Ocean (Mavi)';
      case 'sunset':
        return 'Sunset (Turuncu)';
      case 'berry':
        return 'Berry (Mor)';
      default:
        return 'Forest (Maki Yeşil)';
    }
  }

  String _getThemeLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'light':
        return l10n.settingsThemeLight;
      case 'dark':
        return l10n.settingsThemeDark;
      case 'system':
      default:
        return l10n.settingsThemeSystem;
    }
  }

  Future<void> _changeAccentDialog(String currentAccent) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.settingsAccentTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Center(
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: BrandAccents.all.map((accent) {
                  final selected = accent.key == currentAccent;
                  return GestureDetector(
                    onTap: () {
                      context.read<SettingsBloc>().add(UpdateAccentColorEvent(accent.key));
                      final myAppState = MyApp.of(context);
                      myAppState?.setAccent(accent.color);
                      Navigator.of(context).pop();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: accent.color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              if (selected)
                                BoxShadow(
                                  color: accent.color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                            ],
                          ),
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          accent.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
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
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.settingsResetTitle),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      context.read<SettingsBloc>().add(ClearAllDataEvent());
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
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
          if (state.dataCleared) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tüm veriler başarıyla silindi.')),
            );
            context.read<AuthBloc>().add(LogoutEvent());
            final myAppState = MyApp.of(context);
            myAppState?.setLocale(null);
            myAppState?.setThemeMode(ThemeMode.system);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;
          if (settings == null) {
            return const Center(child: Text('Veriler yüklenemedi'));
          }

          return ListView(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  final user = authState.user;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: AvatarUtils.getAvatarImage(user?.avatarUrl),
                      child: user?.avatarUrl == null
                          ? Icon(
                              Icons.person_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            )
                          : null,
                    ),
                    title: Text(user?.displayName ?? 'Misafir'),
                    subtitle: Text(user?.email ?? 'misafir@maki.app'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(),
              _SettingsSection(
                title: 'Tercihler',
                children: [
                  _SettingsItem(
                    icon: Icons.flag_outlined,
                    title: l10n.onboardingSubtitle,
                    subtitle: _getGoalLabel(settings.primaryGoal, l10n),
                    onTap: () => _changeGoalDialog(settings.primaryGoal),
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Premium',
                    subtitle:
                        settings.isPremium ? l10n.settingsProActive : l10n.settingsProInactive,
                    trailing: settings.isPremium
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                      if (result == true) {
                        if (!context.mounted) return;
                        context.read<SettingsBloc>().add(LoadSettingsEvent());
                      }
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: l10n.settingsNotificationsTitle,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => const NotificationSettingsDialog(),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              _SettingsSection(
                title: 'Görünüm',
                children: [
                  _SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.settingsThemeTitle,
                    subtitle: _getThemeLabel(settings.themeMode, l10n),
                    onTap: () => _changeThemeDialog(settings.themeMode),
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: l10n.settingsAccentTitle,
                    subtitle: _getAccentLabel(settings.accentColor, l10n),
                    onTap: () => _changeAccentDialog(settings.accentColor),
                  ),
                  _SettingsItem(
                    icon: Icons.language_outlined,
                    title: l10n.settingsLanguageTitle,
                    subtitle: _getLanguageLabel(settings.language, l10n),
                    onTap: () => _changeLanguageDialog(settings.language),
                  ),
                ],
              ),
              const Divider(),
              _SettingsSection(
                title: 'Gelişmiş',
                children: [
                  _SettingsItem(
                    icon: Icons.delete_outline,
                    title: l10n.settingsResetTitle,
                    subtitle: l10n.settingsResetSubtitle,
                    titleColor: theme.colorScheme.error,
                    iconColor: theme.colorScheme.error,
                    onTap: _confirmReset,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
