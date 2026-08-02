import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/features/gamification/domain/entities/living_forest_snapshot.dart';

class GoalWorldMapScreen extends StatefulWidget {
  const GoalWorldMapScreen({
    super.key,
    required this.goal,
    required this.seedBalance,
    required this.onContribute,
  });

  final SavingsGoalView goal;
  final int seedBalance;
  final Future<void> Function() onContribute;

  @override
  State<GoalWorldMapScreen> createState() => _GoalWorldMapScreenState();
}

class _GoalWorldMapScreenState extends State<GoalWorldMapScreen> {
  final ScrollController _scrollController = ScrollController();
  var _didInitialScroll = false;

  static const _positions = <Offset>[
    Offset(.55, .975),
    Offset(.68, .945),
    Offset(.52, .915),
    Offset(.68, .885),
    Offset(.33, .855),
    Offset(.48, .825),
    Offset(.66, .795),
    Offset(.35, .765),
    Offset(.50, .735),
    Offset(.66, .705),
    Offset(.34, .675),
    Offset(.51, .645),
    Offset(.69, .615),
    Offset(.39, .585),
    Offset(.61, .555),
    Offset(.73, .525),
    Offset(.49, .495),
    Offset(.66, .465),
    Offset(.41, .435),
    Offset(.54, .405),
    Offset(.35, .375),
    Offset(.56, .345),
    Offset(.40, .315),
    Offset(.66, .285),
    Offset(.52, .255),
    Offset(.37, .225),
    Offset(.59, .195),
    Offset(.45, .165),
    Offset(.60, .125),
    Offset(.49, .075),
  ];

  int get _currentLevel {
    final progress = widget.goal.progress;
    if (!progress.isFinite) return 1;
    return ((progress.clamp(0.0, 1.0) * (_positions.length - 1)).floor() + 1)
        .clamp(1, _positions.length);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent(
    double mapHeight,
    double viewportHeight,
    double mapTopInset,
  ) {
    if (_didInitialScroll) return;
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final currentY =
          mapTopInset + mapHeight * _positions[_currentLevel - 1].dy;
      final target = (currentY - viewportHeight * .58).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(target);
    });
  }

  Future<void> _contribute() async {
    await widget.onContribute();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showNode(int level) {
    final unlocked = level <= _currentLevel;
    final milestone = _milestoneForLevel(level);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: unlocked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: unlocked
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      child: Icon(
                        unlocked ? Icons.eco_rounded : Icons.lock_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patika durağı $level',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            milestone == null
                                ? _nodeMessage(level, unlocked)
                                : '$milestone kilometre taşı',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  unlocked
                      ? level == _currentLevel
                            ? 'Maki burada seni bekliyor. Sonraki durağa ilerlemek için hedef katkını güncelle.'
                            : 'Bu durağı gerçek finans davranışlarınla açtın. Kazanılan görsel ormanında kalıcıdır.'
                      : 'Bu durak henüz puslu. Yolunu açmak için banka bakiyeni değiştirmeden doğrulanmış bir hedef katkısı ekleyebilirsin.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                if (!unlocked || level == _currentLevel) ...[
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _contribute();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Hedefe katkı ekle'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final viewport = media.size;
    final mapHeight = math.max(viewport.height * 1.65, viewport.width * 1.55);
    final mapTopInset = math.max(media.padding.top + 72, 92).toDouble();
    final contentHeight = mapHeight + mapTopInset;
    final imageWidth = mapHeight * 942 / 1674;
    _scrollToCurrent(mapHeight, viewport.height, mapTopInset);

    return Scaffold(
      backgroundColor: const Color(0xFF183A2E),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                height: contentHeight,
                width: viewport.width,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: (viewport.width - imageWidth) / 2,
                      top: mapTopInset,
                      width: imageWidth,
                      height: mapHeight,
                      child: Image.asset(
                        'assets/images/maki_goal_world_map_v1.png',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF6FAF64),
                                    Color(0xFFCCE7A5),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    ),
                    ...List.generate(_positions.length, (index) {
                      final level = index + 1;
                      final position = _positions[index];
                      final x =
                          (viewport.width - imageWidth) / 2 +
                          imageWidth * position.dx;
                      final y = mapTopInset + mapHeight * position.dy;
                      return Positioned(
                        left: x - 25,
                        top: y - 25,
                        child: _MapNode(
                          key: ValueKey('goal-map-node-$level'),
                          level: level,
                          completed: level < _currentLevel,
                          current: level == _currentLevel,
                          milestone: _milestoneForLevel(level) != null,
                          onTap: () => _showNode(level),
                        ),
                      );
                    }),
                    if (_currentLevel <= _positions.length)
                      Positioned(
                        left:
                            ((viewport.width - imageWidth) / 2 +
                                imageWidth * _positions[_currentLevel - 1].dx) -
                            23,
                        top:
                            mapTopInset +
                            mapHeight * _positions[_currentLevel - 1].dy -
                            75,
                        child: const IgnorePointer(
                          child: Mascot.avatar(size: 46),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _MapTopBar(
              goal: widget.goal,
              seedBalance: widget.seedBalance,
              onBack: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: media.padding.bottom + AppSpacing.md,
            child: Card(
              color: theme.colorScheme.surface.withValues(alpha: 0.94),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Durak $_currentLevel / ${_positions.length}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${formatTL(widget.goal.remaining, context: context)} kaldı',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _contribute,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Katkı'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _milestoneForLevel(int level) => switch (level) {
    4 => '%10',
    8 => '%25',
    15 => '%50',
    23 => '%75',
    30 => '%100',
    _ => null,
  };

  String _nodeMessage(int level, bool unlocked) {
    if (!unlocked) return 'Puslu rota';
    if (level == _currentLevel) return 'Maki burada';
    return 'Tamamlanan durak';
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.goal,
    required this.seedBalance,
    required this.onBack,
  });

  final SavingsGoalView goal;
  final int seedBalance;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        MediaQuery.paddingOf(context).top + AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE817352B), Color(0x0017352B)],
        ),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Geri',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Yaşayan hedef haritası',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xD9F2E8C8),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                const Icon(Icons.grass_rounded, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$seedBalance',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    super.key,
    required this.level,
    required this.completed,
    required this.current,
    required this.milestone,
    required this.onTap,
  });

  final int level;
  final bool completed;
  final bool current;
  final bool milestone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = completed || current;
    final fill = current
        ? theme.colorScheme.tertiary
        : completed
        ? theme.colorScheme.primary
        : const Color(0xFF6E7771);
    return Semantics(
      button: true,
      label:
          'Patika durağı $level, ${current
              ? 'şimdiki durak'
              : completed
              ? 'tamamlandı'
              : 'kilitli'}',
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: current ? 56 : 50,
          height: current ? 56 : 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(
              color: milestone ? const Color(0xFFFFD76A) : Colors.white,
              width: milestone ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .26),
                blurRadius: current ? 12 : 7,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: unlocked
                ? Text(
                    '$level',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: current
                          ? theme.colorScheme.onTertiary
                          : theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : const Icon(
                    Icons.lock_rounded,
                    size: 19,
                    color: Colors.white70,
                  ),
          ),
        ),
      ),
    );
  }
}
