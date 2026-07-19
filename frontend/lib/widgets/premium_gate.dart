import 'package:flutter/material.dart';
import 'package:maki_app/services/premium_service.dart';
import 'package:maki_app/screens/paywall_screen.dart';
import 'package:maki_app/theme/app_tokens.dart';
import 'package:maki_app/widgets/mascot.dart';

class PremiumGate extends StatefulWidget {
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

  @override
  State<PremiumGate> createState() => _PremiumGateState();
}

class _PremiumGateState extends State<PremiumGate> {
  bool? _isPremium;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final premium = await PremiumService.instance.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _openPaywall() async {
    final purchased = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PaywallScreen()),
    );
    if (purchased == true) _check();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isPremium!) return widget.child;

    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(pose: MascotPose.happy, size: 104),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.lockedTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.lockedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: _openPaywall,
              icon: const Icon(Icons.workspace_premium_outlined),
              label: Text(widget.unlockLabel),
            ),
          ],
        ),
      ),
    );
  }
}
