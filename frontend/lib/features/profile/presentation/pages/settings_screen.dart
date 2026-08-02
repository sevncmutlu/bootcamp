import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/profile/presentation/widgets/notification_settings_dialog.dart';
import 'package:maki_app/features/premium/presentation/pages/paywall_screen.dart';
import 'package:maki_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/presentation/utils/avatar_utils.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_event.dart';
import 'package:maki_app/features/profile/presentation/bloc/settings_state.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/features/coach/data/datasources/coach_connection_data_source.dart';
import 'package:maki_app/features/reports/presentation/pages/report_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CoachConnectionDataSource? get _coachConnection =>
      di.sl.isRegistered<CoachConnectionDataSource>()
      ? di.sl<CoachConnectionDataSource>()
      : null;

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
      builder: (dialogContext) {
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
                    context.read<SettingsBloc>().add(
                      UpdatePrimaryGoalEvent(val),
                    );
                    MyApp.of(context)?.setPrimaryGoal(val);
                    Navigator.of(dialogContext).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showCoachConnectionDialog() async {
    final connection = _coachConnection;
    if (connection == null) return;
    final controller = TextEditingController();
    var hasKey = await connection.hasGeminiApiKey();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Maki Koç bağlantısı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasKey
                      ? 'Gemini anahtarı bu cihazın güvenli alanında kayıtlı.'
                      : 'Anahtar olmadan yerel rehber çalışır. İstersen Gemini anahtarını ekleyebilirsin.',
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API anahtarı',
                    hintText: 'Anahtarı buraya yapıştır',
                    prefixIcon: Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Anahtar Maki veritabanına veya loglara yazılmaz. Yalnızca koç isteğinde kullanılır.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            if (hasKey)
              TextButton(
                onPressed: () async {
                  await connection.clearGeminiApiKey();
                  controller.clear();
                  setDialogState(() => hasKey = false);
                  if (mounted) setState(() {});
                },
                child: const Text('Anahtarı sil'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Kapat'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await connection.saveGeminiApiKey(controller.text);
                } on FormatException {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Geçerli bir Gemini anahtarı gir.'),
                    ),
                  );
                  return;
                }
                if (!dialogContext.mounted) return;
                setDialogState(() => hasKey = true);
                controller.clear();
                if (mounted) setState(() {});
              },
              child: const Text('Güvenle kaydet'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _changeLanguageDialog(String currentLang) async {
    final l10n = AppLocalizations.of(context)!;
    final languages = {
      'system': l10n.settingsLanguageSystem,
      'tr': l10n.settingsLanguageTr,
      'en': l10n.settingsLanguageEn,
    };

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                    Navigator.of(dialogContext).pop();
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
        return l10n.settingsLanguageTr;
      case 'en':
        return l10n.settingsLanguageEn;
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
      builder: (dialogContext) {
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
                    Navigator.of(dialogContext).pop();
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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.settingsAccentTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settingsAccentDesc,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                child: Center(
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: BrandAccents.all.map((accent) {
                      final selected = accent.key == currentAccent;
                      return GestureDetector(
                        onTap: () {
                          context.read<SettingsBloc>().add(
                            UpdateAccentColorEvent(accent.key),
                          );
                          final myAppState = MyApp.of(context);
                          myAppState?.setAccent(accent.color);
                          Navigator.of(dialogContext).pop();
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: [
                                  if (selected)
                                    BoxShadow(
                                      color: accent.color.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: selected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getAccentLabel(accent.key, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.resetDataTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.resetDataConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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
        title: MakiAppBarTitle(title: l10n.settingsTitle),
        centerTitle: false,
      ),
      body: MakiBackground(
        maxContentWidth: 720,
        child: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            final l10n = AppLocalizations.of(context)!;
            if (state.error != null) {
              String errorMsg = state.error!;
              switch (state.error) {
                case 'errLoadSettings':
                  errorMsg = l10n.errLoadSettings;
                  break;
                case 'errUpdateGoal':
                  errorMsg = l10n.errUpdateGoal;
                  break;
                case 'errUpdateTheme':
                  errorMsg = l10n.errUpdateTheme;
                  break;
                case 'errUpdateAccent':
                  errorMsg = l10n.errUpdateAccent;
                  break;
                case 'errUpdateLang':
                  errorMsg = l10n.errUpdateLang;
                  break;
                case 'errUpdatePremium':
                  errorMsg = l10n.errUpdatePremium;
                  break;
                case 'errClearData':
                  errorMsg = l10n.errClearData;
                  break;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(errorMsg)));
            }
            if (state.dataCleared) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsDataClearedMsg)),
              );
              context.read<AuthBloc>().add(DeleteProfileEvent());
              context.read<PremiumBloc>().add(CheckPremiumStatusEvent());
              final myAppState = MyApp.of(context);
              myAppState?.setLocale(null);
              myAppState?.setThemeMode(ThemeMode.system);
              myAppState?.resetExperience();
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final settings = state.settings;
            if (settings == null) {
              return Center(child: Text(l10n.errLoadSettings));
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
                        backgroundImage: AvatarUtils.getAvatarImage(
                          user?.avatarUrl,
                        ),
                      ),
                      title: Text(user?.displayName ?? l10n.guestUser),
                      subtitle: Text(
                        user == null
                            ? l10n.deviceProfileEmptyTitle
                            : user.email.isEmpty
                            ? l10n.deviceProfilePrivacy
                            : user.email,
                      ),
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
                  title: l10n.settingsSectionPreferences,
                  children: [
                    _SettingsItem(
                      icon: Icons.flag_outlined,
                      title: l10n.settingsGoalTitle,
                      subtitle: _getGoalLabel(settings.primaryGoal, l10n),
                      onTap: () => _changeGoalDialog(settings.primaryGoal),
                    ),
                    FutureBuilder<bool>(
                      future:
                          _coachConnection?.hasGeminiApiKey() ??
                          Future.value(false),
                      builder: (context, snapshot) => _SettingsItem(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Maki Koç bağlantısı',
                        subtitle: snapshot.data == true
                            ? 'Gemini bağlı · yerel rehber yedekte'
                            : 'Yerel rehber çalışıyor · Gemini isteğe bağlı',
                        trailing: Icon(
                          snapshot.data == true
                              ? Icons.verified_rounded
                              : Icons.eco_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: _showCoachConnectionDialog,
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.star_outline_rounded,
                      title: l10n.settingsProTitle,
                      subtitle: context.watch<PremiumBloc>().state.isPremium
                          ? l10n.settingsProActive
                          : l10n.settingsProInactive,
                      trailing: context.watch<PremiumBloc>().state.isPremium
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
                    if (kDebugMode)
                      SwitchListTile(
                        secondary: const Icon(Icons.bug_report_outlined),
                        title: Text(l10n.settingsDevProAccess),
                        value: context.watch<PremiumBloc>().state.isPremium,
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(
                            UpdatePremiumStatusEvent(val),
                          );
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              context.read<PremiumBloc>().add(
                                CheckPremiumStatusEvent(),
                              );
                            }
                          });
                        },
                      ),
                    _SettingsItem(
                      icon: Icons.notifications_outlined,
                      title: l10n.settingsNotificationsTitle,
                      subtitle: l10n.settingsNotificationsSubtitle,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) =>
                              const NotificationSettingsDialog(),
                        );
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Raporlarım',
                      subtitle: 'Günlük, haftalık veya aylık cihaz içi PDF',
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ReportCenterScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                _SettingsSection(
                  title: l10n.settingsSectionAppearance,
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
                  title: l10n.settingsSectionAdvanced,
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
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

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
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
