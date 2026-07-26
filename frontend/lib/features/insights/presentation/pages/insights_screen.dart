import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/di/injection_container.dart';
import 'package:maki_app/features/insights/presentation/pages/forecast_screen.dart';
import 'package:maki_app/features/insights/presentation/pages/inflation_screen.dart';
import 'package:maki_app/features/insights/presentation/bloc/forecast_bloc.dart';
import 'package:maki_app/features/insights/presentation/bloc/inflation_bloc.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text(
          _tabController.index == 0
              ? l10n.forecastTitle
              : l10n.inflationTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: theme.colorScheme.onPrimary,
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
                        Text(l10n.forecastTitle),
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
                        Text(l10n.inflationTitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocProvider(
            create: (_) => sl<ForecastBloc>(),
            child: ForecastScreen(key: _forecastKey, showAppBar: false),
          ),
          BlocProvider(
            create: (_) => sl<InflationBloc>(),
            child: InflationScreen(key: _inflationKey, showAppBar: false),
          ),
        ],
      ),
    );
  }
}
