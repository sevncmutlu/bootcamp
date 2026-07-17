import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/theme/app_theme.dart';
import 'package:maki_app/screens/onboarding_screen.dart';
import 'package:maki_app/screens/expense_entry_screen.dart';
import 'package:maki_app/screens/chat_screen.dart';
import 'package:maki_app/screens/debt_simulator_screen.dart';
import 'package:maki_app/screens/forest_screen.dart';
import 'package:maki_app/screens/paywall_screen.dart';
import 'package:maki_app/services/premium_service.dart';
import 'package:maki_app/screens/insights_screen.dart';
import 'package:maki_app/services/onboarding_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();
}

class MyAppState extends State<MyApp> {
  bool _hasCompletedOnboarding = false;
  bool _isLoading = true;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final completed = await OnboardingService.instance.hasCompletedOnboarding();
    final themeStr = await OnboardingService.instance.getThemeMode();
    final localeStr = await OnboardingService.instance.getAppLocale();

    ThemeMode mode;
    switch (themeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }

    Locale? loc;
    if (localeStr != null && localeStr.isNotEmpty) {
      loc = Locale(localeStr);
    }

    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = completed;
        _themeMode = mode;
        _locale = loc;
        _isLoading = false;
      });
    }
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _hasCompletedOnboarding
              ? const MainNavigationScreen()
              : OnboardingScreen(
                  onCompleted: (selectedGoal) async {
                    await OnboardingService.instance.setPrimaryGoal(selectedGoal);
                    await OnboardingService.instance.setCompletedOnboarding(true);
                    if (mounted) {
                      setState(() {
                        _hasCompletedOnboarding = true;
                      });
                    }
                  },
                ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final _insightsKey = GlobalKey<InsightsScreenState>();
  final _forestKey = GlobalKey<ForestScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const ExpenseEntryScreen(),
      InsightsScreen(key: _insightsKey),
      const DebtSimulatorScreen(),
      ForestScreen(key: _forestKey),
      const ChatScreen(),
    ];
  }

  /// The tab index corresponding to the AI Coach feature.
  static const int _coachTabIndex = 4;

  /// Handles tab selection with a premium gate on the Coach tab.
  Future<void> _onTabSelected(int index) async {
    if (index == _coachTabIndex) {
      final isPremium = await PremiumService.instance.isPremium();
      if (!isPremium) {
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
          );
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
      
      // Auto-refresh tabs when selected to keep state in sync
      if (index == 1) {
        _insightsKey.currentState?.refresh();
      } else if (index == 3) {
        _forestKey.currentState?.refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: AppLocalizations.of(context)!.navExpenses,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: AppLocalizations.of(context)!.navInsights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calculate_outlined),
            selectedIcon: const Icon(Icons.calculate),
            label: AppLocalizations.of(context)!.navSimulator,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forest_outlined),
            selectedIcon: const Icon(Icons.forest),
            label: AppLocalizations.of(context)!.navForest,
          ),
          NavigationDestination(
            icon: const Icon(Icons.spa_outlined),
            selectedIcon: const Icon(Icons.spa),
            label: AppLocalizations.of(context)!.navCoach,
          ),
        ],
      ),
    );
  }
}
