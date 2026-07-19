import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/screens/forecast_screen.dart';
import 'package:maki_app/screens/inflation_screen.dart';

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
        title: Text(
          l10n.navInsights,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(text: l10n.forecastTitle),
            Tab(text: l10n.inflationTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ForecastScreen(key: _forecastKey, showAppBar: false),
          InflationScreen(key: _inflationKey, showAppBar: false),
        ],
      ),
    );
  }
}
