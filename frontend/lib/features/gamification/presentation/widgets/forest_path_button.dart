part of '../pages/forest_screen.dart';

class _ForestPathButton extends StatelessWidget {
  const _ForestPathButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label ormanına gir',
      child: Material(
        color: selected ? theme.colorScheme.primary : const Color(0xD91A2A22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        elevation: selected ? 6 : 2,
        shadowColor: Colors.black54,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 13,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 19 : 18, color: Colors.white),
                if (!compact) ...[
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.circle, size: 7, color: Color(0xFFB8F2D8)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
