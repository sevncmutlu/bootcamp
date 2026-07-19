import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';

class SourceCard extends StatelessWidget {
  const SourceCard({
    super.key,
    required this.title,
    this.url,
    this.publishDate,
    this.dataPeriod,
    this.accessTime,
  });

  final String title;
  final String? url;
  final String? publishDate;
  final String? dataPeriod;
  final String? accessTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      if (publishDate != null) publishDate!,
      if (dataPeriod != null) dataPeriod!,
      if (accessTime != null) accessTime!,
    ].join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (url != null) ...[
                    const SizedBox(height: 2),
                    SelectableText(
                      url!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
