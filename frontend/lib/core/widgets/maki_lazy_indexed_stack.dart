import 'package:flutter/material.dart';

/// Keeps visited destinations alive while building each destination only when
/// it is selected for the first time.
class MakiLazyIndexedStack extends StatefulWidget {
  const MakiLazyIndexedStack({
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    this.rebuildKeys = const <Object?>[],
    this.reduceMotion = false,
    this.transitionDuration = const Duration(milliseconds: 160),
    super.key,
  });

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final List<Object?> rebuildKeys;
  final bool reduceMotion;
  final Duration transitionDuration;

  @override
  State<MakiLazyIndexedStack> createState() => _MakiLazyIndexedStackState();
}

class _MakiLazyIndexedStackState extends State<MakiLazyIndexedStack>
    with SingleTickerProviderStateMixin {
  late List<Widget?> _items;
  late List<Object?> _itemRevisions;
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _validateConfiguration();
    _items = List<Widget?>.filled(widget.itemCount, null);
    _itemRevisions = List<Object?>.generate(widget.itemCount, _rebuildKeyAt);
    _items[widget.index] = _buildItem(widget.index);
    _controller = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
      value: 1,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0.94, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.008),
      end: Offset.zero,
    ).animate(curve);
  }

  @override
  void didUpdateWidget(covariant MakiLazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateConfiguration();

    if (oldWidget.itemCount != widget.itemCount) {
      _items = List<Widget?>.filled(widget.itemCount, null);
      _itemRevisions = List<Object?>.generate(widget.itemCount, _rebuildKeyAt);
    } else {
      for (var index = 0; index < widget.itemCount; index++) {
        final nextRevision = _rebuildKeyAt(index);
        if (_itemRevisions[index] != nextRevision) {
          _itemRevisions[index] = nextRevision;
          _items[index] = null;
        }
      }
    }

    _items[widget.index] ??= _buildItem(widget.index);

    if (oldWidget.transitionDuration != widget.transitionDuration) {
      _controller.duration = widget.transitionDuration;
    }
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  void _validateConfiguration() {
    assert(widget.itemCount > 0);
    assert(widget.index >= 0 && widget.index < widget.itemCount);
    assert(
      widget.rebuildKeys.isEmpty ||
          widget.rebuildKeys.length == widget.itemCount,
    );
  }

  Object? _rebuildKeyAt(int index) =>
      widget.rebuildKeys.isEmpty ? null : widget.rebuildKeys[index];

  Widget _buildItem(int index) {
    return _CachedDestination(
      key: ValueKey<Object?>(('maki-destination', index, _rebuildKeyAt(index))),
      index: index,
      builder: widget.itemBuilder,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stack = IndexedStack(
      index: widget.index,
      sizing: StackFit.expand,
      children: [
        for (var index = 0; index < widget.itemCount; index++)
          TickerMode(
            enabled: widget.index == index,
            child: _items[index] ?? const SizedBox.shrink(),
          ),
      ],
    );

    if (widget.reduceMotion) return stack;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: stack),
    );
  }
}

class _CachedDestination extends StatefulWidget {
  const _CachedDestination({
    required this.index,
    required this.builder,
    super.key,
  });

  final int index;
  final IndexedWidgetBuilder builder;

  @override
  State<_CachedDestination> createState() => _CachedDestinationState();
}

class _CachedDestinationState extends State<_CachedDestination> {
  Widget? _child;

  @override
  Widget build(BuildContext context) {
    return _child ??= widget.builder(context, widget.index);
  }
}
