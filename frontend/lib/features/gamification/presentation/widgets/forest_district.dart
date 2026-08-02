part of '../pages/forest_screen.dart';

class _ForestDistrictScreen extends StatelessWidget {
  const _ForestDistrictScreen({
    required this.goalKey,
    required this.species,
    required this.description,
    required this.icon,
    required this.isSelected,
  });

  final String goalKey;
  final String species;
  final String description;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isTurkish = locale.languageCode == 'tr';
    final profile = GoalExperience.forKey(goalKey);
    final routeCardTop = (MediaQuery.sizeOf(context).height * 0.22)
        .clamp(132.0, 240.0)
        .toDouble();
    final impactItems = [
      (Icons.flag_rounded, profile.mission(locale)),
      (Icons.auto_graph_rounded, profile.analysis(locale)),
      (Icons.task_alt_rounded, profile.tasks(locale).join(' · ')),
    ];

    return Scaffold(
      key: ValueKey('forest-district-screen-$goalKey'),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton.filledTonal(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/maki_forest_crossroads_v2.png',
            fit: BoxFit.cover,
            alignment: _districtAlignment(goalKey),
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000000),
                  Color(0x66101A14),
                  Color(0xF20A1712),
                ],
                stops: [0, 0.42, 0.72],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                routeCardTop,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              child: Icon(icon, size: 27),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.route(locale).toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                  ),
                                  Text(
                                    species,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontFamily: 'MakiDisplay',
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Chip(
                                avatar: Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                ),
                                label: Text('Senin rotan'),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(description, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          isTurkish
                              ? 'Bu rota Maki’yi nasıl değiştirir?'
                              : 'How does this route change Maki?',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...impactItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _DistrictImpactTile(
                              icon: item.$1,
                              text: item.$2,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isSelected
                                ? Icons.task_alt_rounded
                                : Icons.settings_suggest_rounded,
                          ),
                          label: Text(
                            isSelected
                                ? (isTurkish
                                      ? 'Bugünün rota görevlerine dön'
                                      : 'Return to today’s route tasks')
                                : (isTurkish
                                      ? 'Ana hedef ayarından bu rotayı seç'
                                      : 'Choose this route in goal settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _districtAlignment(String key) => switch (key) {
    'pay_debt' => const Alignment(-0.76, -0.45),
    'track_spending' => const Alignment(0.4, -0.55),
    'save_goal' => const Alignment(-0.72, 0.72),
    'learn_invest' => const Alignment(0.75, 0.56),
    _ => Alignment.center,
  };
}

class _DistrictImpactTile extends StatelessWidget {
  const _DistrictImpactTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
