import 'package:flutter/material.dart';
import 'package:maki_app/core/personalization/goal_experience.dart';
import 'package:maki_app/core/theme/app_tokens.dart';

enum GoalRouteSurface { comparison, simulator, analysis }

class GoalRouteBanner extends StatelessWidget {
  const GoalRouteBanner({
    super.key,
    required this.primaryGoal,
    required this.surface,
  });

  final String primaryGoal;
  final GoalRouteSurface surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final profile = GoalExperience.forKey(primaryGoal);
    final isTurkish = locale.languageCode == 'tr';
    final copy = _copy(profile, locale, isTurkish);

    return Card(
      key: ValueKey('goal-route-banner-${surface.name}-$primaryGoal'),
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.48),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              child: Icon(profile.icon, size: 21),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.species(locale)} · ${profile.route(locale)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copy,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.38),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _copy(GoalExperience profile, Locale locale, bool isTurkish) {
    return switch (surface) {
      GoalRouteSurface.analysis =>
        isTurkish
            ? 'Bu ekranda önce ${profile.analysis(locale).toLowerCase()} öne çıkar. Diğer analizler erişilebilir kalır.'
            : 'This screen prioritizes ${profile.analysis(locale).toLowerCase()}. Other analyses stay available.',
      GoalRouteSurface.comparison =>
        isTurkish
            ? '${profile.metric(locale)} değişimini görünür kılmak için dönemleri bu rotaya göre yorumluyoruz.'
            : 'Periods are interpreted around changes in ${profile.metric(locale).toLowerCase()}.',
      GoalRouteSurface.simulator =>
        isTurkish
            ? '${profile.mission(locale)} Araçlar aynı kalır; Maki sonucu bu amaca göre açıklar.'
            : '${profile.mission(locale)} Tools stay shared; Maki explains the result for this goal.',
    };
  }
}
