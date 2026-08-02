import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/brand_wordmark.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_event.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<PremiumBloc, PremiumState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        }
        if (state.purchaseSuccess) {
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<PremiumBloc, PremiumState>(
        builder: (context, state) {
          final isPurchasing = state.isLoading;
          return Scaffold(
            body: MakiBackground(
              maxContentWidth: 720,
              child: Stack(
                children: [
                  SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: BrandWordmark(
                                fontSize: 23,
                                showTagline: false,
                                alignment: CrossAxisAlignment.start,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(context).pop(false),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PremiumHero(title: l10n.paywallTitle),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.paywallSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              children: [
                                _FeatureRow(
                                  icon: Icons.forum_outlined,
                                  title: l10n.paywallBenefit1,
                                ),
                                const Divider(height: AppSpacing.xl),
                                _FeatureRow(
                                  icon: Icons.query_stats_rounded,
                                  title: l10n.paywallBenefit2,
                                ),
                                const Divider(height: AppSpacing.xl),
                                _FeatureRow(
                                  icon: Icons.route_outlined,
                                  title: l10n.paywallBenefit3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: AppRadius.card,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                state.localizedPrice ?? l10n.paywallPriceLabel,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              FilledButton.icon(
                                onPressed: isPurchasing
                                    ? null
                                    : () => context.read<PremiumBloc>().add(
                                        PurchasePremiumEvent(),
                                      ),
                                icon: const Icon(Icons.eco_rounded),
                                label: Text(l10n.paywallCtaButton),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: isPurchasing
                                    ? null
                                    : () => context.read<PremiumBloc>().add(
                                        RestorePremiumEvent(),
                                      ),
                                child: Text(l10n.paywallRestoreButton),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPurchasing)
                    Positioned.fill(
                      child: ColoredBox(
                        color: ForestColors.night.withValues(alpha: 0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      image: true,
      label: title,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/maki_financial_forest_v3.webp',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x08000000),
                      Color(0x24071A14),
                      Color(0xE6071A14),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              const Positioned(
                right: 10,
                bottom: 0,
                child: Mascot(
                  pose: MascotPose.celebrate,
                  size: 116,
                  withBadge: true,
                ),
              ),
              Positioned(
                left: AppSpacing.xl,
                right: 118,
                bottom: AppSpacing.xl,
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.03,
                    shadows: const [
                      Shadow(color: Color(0x99000000), blurRadius: 10),
                    ],
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSecondaryContainer,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Icon(
          Icons.check_circle_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ],
    );
  }
}
