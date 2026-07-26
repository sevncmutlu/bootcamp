import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/core/theme/app_tokens.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    int score = 0;
    final bool hasMinLength = password.length >= 6;
    final bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final bool hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (hasMinLength) score++;
    if (hasNumber) score++;
    if (hasUpper) score++;
    if (hasSpecial) score++;

    Color color;
    String label;
    double progress;

    if (score <= 1) {
      color = Colors.red;
      label = l10n.passwordWeak;
      progress = 0.33;
    } else if (score <= 3) {
      color = Colors.orange;
      label = l10n.passwordMedium;
      progress = 0.66;
    } else {
      color = Colors.green;
      label = l10n.passwordStrong;
      progress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.passwordLabel}: $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$score/4',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 6,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        _buildRequirementRow(l10n.reqMinLength, hasMinLength, theme),
        _buildRequirementRow(l10n.reqNumber, hasNumber, theme),
        _buildRequirementRow(l10n.reqUpper, hasUpper, theme),
        _buildRequirementRow(l10n.reqSpecial, hasSpecial, theme),
      ],
    );
  }

  Widget _buildRequirementRow(
      String label, bool isMet, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
              decoration: isMet ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
