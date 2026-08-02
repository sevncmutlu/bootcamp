import 'package:flutter/material.dart';

class MakiAppBarTitle extends StatelessWidget {
  const MakiAppBarTitle({
    super.key,
    required this.title,
    this.eyebrow = 'MAKİKOÇ',
  });

  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          maxLines: 1,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.35,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
            height: 1,
          ),
        ),
      ],
    );
  }
}
