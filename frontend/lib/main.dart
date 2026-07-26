import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/features/auth/presentation/pages/brand_splash_screen.dart';
import 'package:maki_app/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:maki_app/features/transactions/presentation/pages/expense_entry_screen.dart';
import 'package:maki_app/features/coach/presentation/pages/chat_screen.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/simulator/presentation/pages/debt_simulator_screen.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/gamification/presentation/pages/forest_screen.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/premium/presentation/pages/paywall_screen.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/insights/presentation/pages/insights_screen.dart';
import 'package:maki_app/features/profile/data/datasources/onboarding_local_data_source.dart';
import 'package:maki_app/core/widgets/app_navigation_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await initializeDateFormatting();
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
  bool _showSplash = true;
  ThemeMode _themeMode = ThemeMode.system;
  Color _accent = BrandAccents.defaultAccent.color;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final ds = di.sl<OnboardingLocalDataSource>();
    final completed = await ds.hasCompletedOnboarding();
    final themeStr = await ds.getThemeMode();
    final accentStr = await ds.getAccent();
    final langStr = await ds.getLanguage();

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
    if (langStr == 'tr') {
      loc = const Locale('tr');
    } else if (langStr == 'en') {
      loc = const Locale('en');
    }

    if (loc != null) {
      Intl.defaultLocale = loc.toString();
    }

    if (mounted) {
      setState(() {
        _hasCompletedOnboarding = completed;
        _themeMode = mode;
        _accent = BrandAccents.colorForKey(accentStr);
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

  void setAccent(Color color) {
    setState(() {
      _accent = color;
    });
  }

  void setLocale(Locale? locale) {
    if (locale != null) {
      Intl.defaultLocale = locale.toString();
    }
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(InitializeAuthEvent()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => di.sl<TransactionBloc>()..add(LoadCategoriesEvent()),
        ),
        BlocProvider<PremiumBloc>(
          create: (context) => di.sl<PremiumBloc>()..add(CheckPremiumStatusEvent()),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        theme: AppTheme.light(_accent),
        darkTheme: AppTheme.dark(_accent),
        themeMode: _themeMode,
        home: _isLoading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _showSplash
            ? BrandSplashScreen(
                onCompleted: () {
                  if (mounted) {
                    setState(() {
                      _showSplash = false;
                    });
                  }
                },
              )
            : _hasCompletedOnboarding
            ? const MainNavigationScreen()
            : OnboardingScreen(
                onCompleted: (selectedGoal) async {
                  final ds = di.sl<OnboardingLocalDataSource>();
                  await ds.setPrimaryGoal(selectedGoal);
                  await ds.setCompletedOnboarding(true);
                  if (mounted) {
                    setState(() {
                      _hasCompletedOnboarding = true;
                    });
                  }
                },
              ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  static void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

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
      BlocProvider(
        create: (_) => di.sl<SimulatorBloc>(),
        child: const DebtSimulatorScreen(),
      ),
      BlocProvider(
        create: (_) => di.sl<GamificationBloc>(),
        child: ForestScreen(key: _forestKey),
      ),
      BlocProvider(
        create: (_) => di.sl<CoachBloc>(),
        child: const ChatScreen(),
      ),
    ];
  }

  static const int _debtTabIndex = 2;
  static const int _coachTabIndex = 4;

  Future<void> _onTabSelected(int index) async {
    if (index == _debtTabIndex || index == _coachTabIndex) {
      final isPremium = context.read<PremiumBloc>().state.isPremium;
      if (!isPremium) {
        if (!mounted) return;
        final purchased = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const PaywallScreen()),
        );
        if (purchased != true) return;
      }
    }
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });

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
      key: MainNavigationScreen.scaffoldKey,
      drawer: const AppNavigationDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_outlined),
              label: AppLocalizations.of(context)!.navExpenses,
            ),
            NavigationDestination(
              icon: const Icon(Icons.donut_large_outlined),
              selectedIcon: const Icon(Icons.donut_large_outlined),
              label: AppLocalizations.of(context)!.navInsights,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_outlined),
              label: AppLocalizations.of(context)!.navSimulator,
            ),
            NavigationDestination(
              icon: const Icon(Icons.flag_outlined),
              selectedIcon: const Icon(Icons.flag_outlined),
              label: AppLocalizations.of(context)!.navForest,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome_outlined),
              label: AppLocalizations.of(context)!.navCoach,
            ),
          ],
        ),
      ),
    );
  }
}
