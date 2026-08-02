import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/di/injection_container.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/personalization/goal_route_banner.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/insights/presentation/pages/forecast_screen.dart';
import 'package:maki_app/features/insights/presentation/pages/inflation_screen.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';
import 'package:maki_app/features/insights/data/services/price_basket_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, this.primaryGoal = 'track_spending'});

  final String primaryGoal;

  @override
  State<InsightsScreen> createState() => InsightsScreenState();
}

class InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _forecastKey = GlobalKey<ForecastScreenState>();
  final _inflationKey = GlobalKey<InflationScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.primaryGoal == 'learn_invest' ? 1 : 0,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void refresh() {
    _forecastKey.currentState?.refresh();
    _inflationKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: MakiAppBarTitle(
          title: _tabController.index == 0
              ? l10n.forecastTitle
              : l10n.inflationTitle,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.65,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.md - 4),
                  ),
                  boxShadow: AppShadows.soft(
                    theme.brightness,
                    theme.colorScheme.primary,
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.show_chart_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.forecastTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    height: 36,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.trending_up_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.inflationTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: MakiBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: GoalRouteBanner(
                primaryGoal: widget.primaryGoal,
                surface: GoalRouteSurface.analysis,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  BlocProvider(
                    create: (_) => sl<ForecastBloc>(),
                    child: ForecastScreen(key: _forecastKey, showAppBar: false),
                  ),
                  BlocProvider(
                    create: (_) => sl<InflationBloc>(),
                    child: InflationScreen(
                      key: _inflationKey,
                      showAppBar: false,
                      priceBasketService: sl.isRegistered<PriceBasketService>()
                          ? sl<PriceBasketService>()
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
