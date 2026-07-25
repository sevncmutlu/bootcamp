import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/screens/notification_settings_dialog.dart';
import 'package:maki_app/screens/paywall_screen.dart';
import 'package:maki_app/screens/profile_screen.dart';
import 'package:maki_app/screens/settings_screen.dart';
import 'package:maki_app/services/auth_service.dart';
import 'package:maki_app/services/onboarding_service.dart';
import 'package:maki_app/services/premium_service.dart';
import 'package:maki_app/theme/app_tokens.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  bool _isPremium = false;
  String _selectedTheme = 'system';
  String _selectedLanguage = 'system';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final isPrem = await PremiumService.instance.isPremium();
    final theme = await OnboardingService.instance.getThemeMode();
    final lang = await OnboardingService.instance.getLanguage();
    if (mounted) {
      setState(() {
        _isPremium = isPrem;
        _selectedTheme = theme;
        _selectedLanguage = lang;
      });
    }
  }

  Future<void> _updateTheme(String mode) async {
    await OnboardingService.instance.setThemeMode(mode);
    if (!mounted) return;
    setState(() => _selectedTheme = mode);
    ThemeMode themeMode;
    switch (mode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    MyApp.of(context)?.setThemeMode(themeMode);
  }

  Future<void> _updateLanguage(String lang) async {
    await OnboardingService.instance.setLanguage(lang);
    if (!mounted) return;
    setState(() => _selectedLanguage = lang);
    Locale? locale;
    if (lang == 'tr') {
      locale = const Locale('tr');
    } else if (lang == 'en') {
      locale = const Locale('en');
    }
    MyApp.of(context)?.setLocale(locale);
  }

  void _showThemeSelector(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.settingsThemeTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto_outlined),
              title: Text(l10n.settingsThemeSystem),
              trailing: _selectedTheme == 'system'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateTheme('system');
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: Text(l10n.settingsThemeLight),
              trailing: _selectedTheme == 'light'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateTheme('light');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.settingsThemeDark),
              trailing: _selectedTheme == 'dark'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateTheme('dark');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.settingsLanguageTitle,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.settingsLanguageSystem),
              trailing: _selectedLanguage == 'system'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateLanguage('system');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.settingsLanguageTr),
              trailing: _selectedLanguage == 'tr'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateLanguage('tr');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.settingsLanguageEn),
              trailing: _selectedLanguage == 'en'
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _updateLanguage('en');
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(AppLocalizations l10n) {
    switch (_selectedTheme) {
      case 'light':
        return l10n.settingsThemeLight;
      case 'dark':
        return l10n.settingsThemeDark;
      default:
        return l10n.settingsThemeSystem;
    }
  }

  String _getLanguageLabel(AppLocalizations l10n) {
    switch (_selectedLanguage) {
      case 'tr':
        return l10n.settingsLanguageTr;
      case 'en':
        return l10n.settingsLanguageEn;
      default:
        return l10n.settingsLanguageSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    ListenableBuilder(
                      listenable: AuthService.instance,
                      builder: (context, _) {
                        final u = AuthService.instance.currentUser;
                        final name = u?.displayName;
                        final email = u?.email;

                        return Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                image: DecorationImage(
                                  image: UserProfile.getAvatarImage(u?.avatarUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name != null && name.isNotEmpty
                                        ? name
                                        : (email != null && email.isNotEmpty
                                            ? email
                                            : l10n.guestUser),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (email != null && email.isNotEmpty)
                                    Text(
                                      email,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isPremium
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isPremium ? l10n.tierPro : l10n.tierFree,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _isPremium
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!_isPremium)
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final purchased = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute<bool>(
                                    builder: (_) => const PaywallScreen(),
                                  ),
                                );
                            if (purchased == true) {
                              _loadState();
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                l10n.upgradeButton,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.profileTitle),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.notifications_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.notificationsTitle),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog<void>(
                        context: context,
                        builder: (_) => const NotificationSettingsDialog(),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsThemeTitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getThemeLabel(l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () => _showThemeSelector(context, l10n),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.language_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsLanguageTitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getLanguageLabel(l10n),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    onTap: () => _showLanguageSelector(context, l10n),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(l10n.settingsTitle),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.appVersionLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
