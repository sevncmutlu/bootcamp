import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_bloc.dart';
import 'package:maki_app/features/premium/presentation/bloc/premium_state.dart';
import 'package:maki_app/features/premium/presentation/pages/paywall_screen.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/mascot.dart';

class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.child,
    required this.lockedTitle,
    required this.lockedMessage,
    required this.unlockLabel,
  });

  final Widget child;
  final String lockedTitle;
  final String lockedMessage;
  final String unlockLabel;

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PremiumBloc, PremiumState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.isPremium) return child;

    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(pose: MascotPose.happy, size: 104),
            const SizedBox(height: AppSpacing.md),
            Text(
              lockedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              lockedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _openPaywall(context),
              icon: const Icon(Icons.workspace_premium),
              label: Text(unlockLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
