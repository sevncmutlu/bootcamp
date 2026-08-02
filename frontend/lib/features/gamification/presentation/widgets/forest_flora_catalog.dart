part of '../pages/forest_screen.dart';

class _FloraCatalog extends StatelessWidget {
  const _FloraCatalog({required this.primaryGoal});

  final String primaryGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plants = [
      (
        'pay_debt',
        l10n.floraMyrtleTitle,
        l10n.floraMyrtleBody,
        Icons.spa_rounded,
      ),
      (
        'track_spending',
        l10n.floraLaurelCherryTitle,
        l10n.floraLaurelCherryBody,
        Icons.eco_rounded,
      ),
      ('save_goal', l10n.floraOakTitle, l10n.floraOakBody, Icons.park_rounded),
      (
        'learn_invest',
        l10n.floraTamariskTitle,
        l10n.floraTamariskBody,
        Icons.nature_rounded,
      ),
    ];

    void openDistrict((String, String, String, IconData) plant) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _ForestDistrictScreen(
            goalKey: plant.$1,
            species: plant.$2,
            description: plant.$3,
            icon: plant.$4,
            isSelected: plant.$1 == primaryGoal,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localizations.localeOf(context).languageCode == 'tr'
              ? 'YEREL FLORA ATLASI'
              : 'LOCAL FLORA ATLAS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.floraCatalogTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: 'MakiDisplay',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.floraCatalogBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            return Semantics(
              container: true,
              label: l10n.floraAtlasSemantics,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: wide ? 16 / 6.2 : 16 / 8.8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/maki_forest_crossroads_v2.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.makiPalette.heroStart.withValues(
                                alpha: 0.74,
                              ),
                            ],
                            stops: [0.58, 1],
                          ),
                        ),
                      ),
                      for (var index = 0; index < plants.length; index++)
                        Align(
                          alignment: const [
                            Alignment(-0.72, -0.56),
                            Alignment(0.72, -0.56),
                            Alignment(-0.72, 0.58),
                            Alignment(0.72, 0.58),
                          ][index],
                          child: _ForestPathButton(
                            label: plants[index].$2,
                            icon: plants[index].$4,
                            selected: plants[index].$1 == primaryGoal,
                            compact: !wide,
                            onTap: () => openDistrict(plants[index]),
                          ),
                        ),
                      Positioned(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'tr'
                              ? 'Dört hedef, dört yerel tür, tek yaşayan ekosistem.'
                              : 'Four goals, four local species, one living ecosystem.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plants.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final plant = plants[index];
              final isSelected = plant.$1 == primaryGoal;
              return SizedBox(
                width: 176,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.card,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant
                                .withValues(alpha: 0.48),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('forest-district-${plant.$1}'),
                    onTap: () => openDistrict(plant),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            child: Icon(
                              plant.$4,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            plant.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              plant.$3,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: AppSpacing.xs),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'tr'
                                    ? 'Senin rotan'
                                    : 'Your route',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
