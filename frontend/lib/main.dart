import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/core/errors/app_error_reporter.dart';
import 'package:maki_app/core/persistence/coach_bubble_position_store.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/session/presentation/cubit/session_cubit.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:maki_app/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_theme.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/features/auth/presentation/pages/brand_splash_screen.dart';
import 'package:maki_app/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/features/transactions/presentation/pages/expense_entry_screen.dart';
import 'package:maki_app/features/transactions/presentation/pages/comparison_screen.dart';
import 'package:maki_app/features/coach/presentation/pages/chat_screen.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/simulator/presentation/pages/debt_simulator_screen.dart';
import 'package:maki_app/features/simulator/presentation/bloc/simulator_bloc.dart';
import 'package:maki_app/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:maki_app/features/gamification/presentation/pages/leaderboard_screen.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/insights/presentation/pages/insights_screen.dart';
import 'package:maki_app/features/profile/data/datasources/onboarding_local_data_source.dart';
import 'package:maki_app/core/widgets/app_navigation_drawer.dart';
import 'package:maki_app/core/widgets/draggable_coach_bubble.dart';
import 'package:maki_app/core/widgets/maki_adaptive_navigation.dart';
import 'package:maki_app/core/widgets/maki_lazy_indexed_stack.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = AppEnvironment.current;
  final dsn = environment.sentryDsn;
  if (dsn != null) {
    await SentryFlutter.init((options) {
      options
        ..dsn = dsn
        ..environment = environment.stageName
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..enableAutoPerformanceTracing = false
        ..tracesSampleRate = 0
        ..maxRequestBodySize = MaxRequestBodySize.never
        ..beforeSend = (event, hint) => sanitizeSentryEvent(event);
    }, appRunner: _startMaki);
    return;
  }
  _startMaki();
}

void _startMaki() {
  runApp(const _MakiBootstrap());
}

Future<void> _initializeMaki() async {
  await di.init();
  final reporter = di.sl<AppErrorReporter>();
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    unawaited(
      reporter.report(
        details.exception,
        details.stack ?? StackTrace.current,
        area: 'flutter_arayuzu',
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(reporter.report(error, stackTrace, area: 'platform'));
    return true;
  };
  ErrorWidget.builder = (_) => const _MakiSafeErrorView();
  await initializeDateFormatting();
}

class _MakiBootstrap extends StatefulWidget {
  const _MakiBootstrap();

  @override
  State<_MakiBootstrap> createState() => _MakiBootstrapState();
}

class _MakiBootstrapState extends State<_MakiBootstrap> {
  late Future<void> _initialization = _startInitialization();

  Future<void> _startInitialization() async {
    try {
      await _initializeMaki().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Maki yerel hizmetleri zamanında hazırlanamadı.',
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Maki başlangıç hatası: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _initialization = _startInitialization();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.error == null) {
          return const MyApp();
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(BrandAccents.defaultAccent.color),
          home: snapshot.hasError
              ? _MakiInitializationError(onRetry: _retry)
              : const _MakiInitializationView(),
        );
      },
    );
  }
}

class _MakiInitializationView extends StatelessWidget {
  const _MakiInitializationView();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF071A14),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Mascot.avatar(size: 96),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Maki hazırlanıyor',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'MakiDisplay',
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Yerel finans ormanın açılıyor…',
            style: TextStyle(color: Color(0xFFBFD0C5)),
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ],
      ),
    ),
  );
}

class _MakiInitializationError extends StatelessWidget {
  const _MakiInitializationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071A14),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot.avatar(size: 84),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Ormanı birlikte uyandıralım',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Yerel kayıt alanı bu kez açılamadı. Verilerin silinmedi; yeniden deneyebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFBFD0C5), height: 1.45),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MakiSafeErrorView extends StatelessWidget {
  const _MakiSafeErrorView();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F0E8),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 52,
                    color: Color(0xFF17624B),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Maki kısa bir mola verdi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF173C32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kayıtların güvende. Bu ekranı kapatıp yeniden deneyebilirsin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF49655D), height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  String _primaryGoal = 'track_spending';

  String get primaryGoal => _primaryGoal;

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
    final primaryGoal = await ds.getPrimaryGoal();

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
        _primaryGoal = primaryGoal ?? 'track_spending';
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

  void setPrimaryGoal(String goal) {
    setState(() {
      _primaryGoal = goal;
    });
  }

  void resetExperience() {
    setState(() {
      _hasCompletedOnboarding = false;
      _primaryGoal = 'track_spending';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(InitializeAuthEvent()),
        ),
        BlocProvider<SessionCubit>(
          create: (context) => di.sl<SessionCubit>()..initialize(),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) =>
              di.sl<TransactionBloc>()..add(LoadCategoriesEvent()),
        ),
        BlocProvider<PremiumBloc>(
          create: (context) =>
              di.sl<PremiumBloc>()..add(CheckPremiumStatusEvent()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        theme: AppTheme.light(_accent),
        darkTheme: AppTheme.dark(_accent),
        themeMode: _themeMode,
        builder: (context, child) {
          if (!AppEnvironment.current.isWebPreview) {
            return child ?? const SizedBox.shrink();
          }
          return Column(
            children: [
              const _WebPreviewBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
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
            ? MainNavigationScreen(primaryGoal: _primaryGoal)
            : OnboardingScreen(
                onCompleted: (selectedGoal) async {
                  final ds = di.sl<OnboardingLocalDataSource>();
                  await ds.setPrimaryGoal(selectedGoal);
                  await ds.setCompletedOnboarding(true);
                  if (mounted) {
                    setState(() {
                      _primaryGoal = selectedGoal;
                      _hasCompletedOnboarding = true;
                    });
                  }
                },
              ),
      ),
    );
  }
}

class _WebPreviewBanner extends StatelessWidget {
  const _WebPreviewBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE8A3),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.science_outlined, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Web önizleme • Yalnızca sentetik veri • '
                  'Kayıtlar sekme kapanınca silinir',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF493600),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.primaryGoal = 'track_spending'});

  final String primaryGoal;

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
  static const _destinationCount = 5;
  static const _defaultCoachPosition = Offset(1, 0.62);

  final _insightsKey = GlobalKey<InsightsScreenState>();

  late final CoachBubblePositionStore _coachPositionStore;
  late Offset _coachPosition;

  @override
  void initState() {
    super.initState();
    _coachPositionStore = CoachBubblePositionStore(di.sl<SharedPreferences>());
    _coachPosition = _coachPositionStore.read() ?? _defaultCoachPosition;
  }

  void _saveCoachPosition(Offset position) {
    _coachPosition = position;
    unawaited(_coachPositionStore.write(position));
  }

  Widget _createScreen(BuildContext context, int index) {
    return switch (index) {
      0 => ExpenseEntryScreen(primaryGoal: widget.primaryGoal),
      1 => BlocProvider(
        create: (_) => di.sl<SimulatorBloc>(),
        child: DebtSimulatorScreen(primaryGoal: widget.primaryGoal),
      ),
      2 => ComparisonScreen(primaryGoal: widget.primaryGoal),
      3 => InsightsScreen(key: _insightsKey, primaryGoal: widget.primaryGoal),
      4 => BlocProvider(
        create: (_) => di.sl<GamificationBloc>(),
        child: const LeaderboardScreen(userLevel: 1),
      ),
      _ => throw RangeError.index(index, List.filled(_destinationCount, null)),
    };
  }

  Future<void> _onTabSelected(int index) async {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });

      if (index == 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentIndex == 3) {
            _insightsKey.currentState?.refresh();
          }
        });
      }
    }
  }

  Future<void> _openCoach() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => di.sl<CoachBloc>(),
          child: ChatScreen(primaryGoal: widget.primaryGoal),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.wallet_outlined),
        selectedIcon: const Icon(Icons.wallet_rounded),
        label: l10n.navIncomeExpense,
      ),
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
        label: l10n.navSimulator,
      ),
      NavigationDestination(
        icon: const Icon(Icons.compare_arrows_rounded),
        selectedIcon: const Icon(Icons.compare_arrows_rounded),
        label: l10n.navCompare,
      ),
      NavigationDestination(
        icon: const Icon(Icons.donut_large_outlined),
        selectedIcon: const Icon(Icons.donut_large_rounded),
        label: l10n.navInsights,
      ),
      NavigationDestination(
        icon: const Icon(Icons.leaderboard_outlined),
        selectedIcon: const Icon(Icons.leaderboard_rounded),
        label: l10n.navLeaderboard,
      ),
    ];
    final screenStack = Stack(
      children: [
        Positioned.fill(
          child: MakiLazyIndexedStack(
            index: _currentIndex,
            itemCount: _destinationCount,
            itemBuilder: _createScreen,
            rebuildKeys: <Object?>[
              widget.primaryGoal,
              widget.primaryGoal,
              widget.primaryGoal,
              widget.primaryGoal,
              null,
            ],
            reduceMotion: reduceMotion,
          ),
        ),
        Positioned.fill(
          child: DraggableCoachBubble(
            initialPosition: _coachPosition,
            onPositionChanged: _saveCoachPosition,
            onTap: _openCoach,
            tooltip: l10n.navCoach,
            child: const Mascot.avatar(size: 46),
          ),
        ),
      ],
    );
    return MakiAdaptiveNavigation(
      scaffoldKey: MainNavigationScreen.scaffoldKey,
      drawer: const AppNavigationDrawer(),
      body: screenStack,
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      destinations: destinations,
    );
  }
}
