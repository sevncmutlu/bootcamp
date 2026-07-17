import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class LeaderboardScreen extends StatelessWidget {
  final int userPercentile; // Calculated percentile rank, e.g. 92
  final int userLevel;       // User's current gamification level

  const LeaderboardScreen({
    super.key,
    required this.userPercentile,
    required this.userLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Calculate user's planted trees based on level
    final userTrees = userLevel <= 1 
        ? 0 
        : (userLevel == 2 ? 1 : (userLevel == 3 ? 2 : userLevel - 2));
    
    // Top rank is 100 - savings percentile
    final userTopPercentile = 100 - userPercentile;

    final List<LeaderboardRowData> staticRows = [
      LeaderboardRowData(percentile: 1, title: 'Eco Titan', level: 16, trees: 14, isUser: false),
      LeaderboardRowData(percentile: 5, title: 'Budget Master', level: 12, trees: 10, isUser: false),
      LeaderboardRowData(percentile: 10, title: 'Active Saver', level: 9, trees: 7, isUser: false),
      LeaderboardRowData(percentile: 25, title: 'Green Tracker', level: 6, trees: 4, isUser: false),
      LeaderboardRowData(percentile: 50, title: 'Daily Saver', level: 4, trees: 2, isUser: false),
      LeaderboardRowData(percentile: 75, title: 'Starter Sprout', level: 2, trees: 1, isUser: false),
      LeaderboardRowData(percentile: 100, title: 'Beginner', level: 1, trees: 0, isUser: false),
    ];

    // Build the sorted list including the user
    final List<LeaderboardRowData> allRows = [];
    bool inserted = false;
    final userRow = LeaderboardRowData(
      percentile: userTopPercentile,
      title: l10n.leaderboardYou,
      level: userLevel,
      trees: userTrees,
      isUser: true,
    );

    for (final row in staticRows) {
      if (!inserted && userTopPercentile < row.percentile) {
        allRows.add(userRow);
        inserted = true;
      }
      if (row.percentile == userTopPercentile) {
        // If user matches exactly, replace with the user's customized data
        allRows.add(userRow);
        inserted = true;
        continue;
      }
      allRows.add(row);
    }
    if (!inserted) {
      allRows.add(userRow);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.leaderboardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Privacy Shield Intro Card
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.leaderboardSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Leaderboard list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allRows.length,
              itemBuilder: (context, index) {
                final row = allRows[index];
                
                // Styling parameters based on rank
                Color rowBgColor = Colors.transparent;
                if (row.isUser) {
                  rowBgColor = theme.colorScheme.primary.withValues(alpha: 0.08);
                }

                Widget rankBadge;
                if (index == 0) {
                  rankBadge = const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
                } else if (index == 1) {
                  rankBadge = Icon(Icons.emoji_events, color: Colors.grey.shade400, size: 28);
                } else if (index == 2) {
                  rankBadge = const Icon(Icons.emoji_events, color: Colors.brown, size: 28);
                } else {
                  rankBadge = CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: rowBgColor,
                    borderRadius: BorderRadius.circular(16.0),
                    border: row.isUser 
                        ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                        : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: rankBadge,
                    title: Row(
                      children: [
                        Text(
                          row.isUser ? row.title : l10n.leaderboardAnonymous,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: row.isUser ? FontWeight.bold : FontWeight.w600,
                            color: row.isUser ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (row.isUser) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ]
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.forest_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.leaderboardTrees(row.trees),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.stars_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.currentLevel(row.level),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Text(
                      l10n.leaderboardPercentile(row.percentile),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: row.isUser ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardRowData {
  final int percentile;
  final String title;
  final int level;
  final int trees;
  final bool isUser;

  LeaderboardRowData({
    required this.percentile,
    required this.title,
    required this.level,
    required this.trees,
    required this.isUser,
  });
}
