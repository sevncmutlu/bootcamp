import 'package:flutter/material.dart';
import 'package:maki_app/core/theme/app_tokens.dart';

class DraggableCoachBubble extends StatefulWidget {
  const DraggableCoachBubble({
    super.key,
    required this.onTap,
    required this.onPositionChanged,
    required this.child,
    required this.tooltip,
    this.initialPosition = const Offset(1, 0.62),
    this.size = 64,
  });

  final VoidCallback onTap;
  final ValueChanged<Offset> onPositionChanged;
  final Widget child;
  final String tooltip;
  final Offset initialPosition;
  final double size;

  @override
  State<DraggableCoachBubble> createState() => _DraggableCoachBubbleState();
}

class _DraggableCoachBubbleState extends State<DraggableCoachBubble> {
  static const _edgeInset = 12.0;
  static const _appBarClearance = kToolbarHeight + 12;

  late Offset _normalizedPosition;
  Rect _movementBounds = Rect.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _normalizedPosition = _sanitize(widget.initialPosition);
  }

  @override
  void didUpdateWidget(covariant DraggableCoachBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.initialPosition != widget.initialPosition) {
      _normalizedPosition = _sanitize(widget.initialPosition);
    }
  }

  Offset _sanitize(Offset value) {
    if (!value.dx.isFinite || !value.dy.isFinite) {
      return const Offset(1, 0.62);
    }
    return Offset(value.dx.clamp(0.0, 1.0), value.dy.clamp(0.0, 1.0));
  }

  Offset _absolutePosition(Offset normalized) {
    return Offset(
      _movementBounds.left + normalized.dx * _movementBounds.width,
      _movementBounds.top + normalized.dy * _movementBounds.height,
    );
  }

  Offset _normalizedFromAbsolute(Offset absolute) {
    final x = _movementBounds.width <= 0
        ? 0.0
        : (absolute.dx - _movementBounds.left) / _movementBounds.width;
    final y = _movementBounds.height <= 0
        ? 0.0
        : (absolute.dy - _movementBounds.top) / _movementBounds.height;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  Offset _clampAbsolute(Offset value) {
    return Offset(
      value.dx.clamp(_movementBounds.left, _movementBounds.right),
      value.dy.clamp(_movementBounds.top, _movementBounds.bottom),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final next = _clampAbsolute(
      _absolutePosition(_normalizedPosition) + details.delta,
    );
    setState(() => _normalizedPosition = _normalizedFromAbsolute(next));
  }

  void _finishDrag() {
    final snapped = Offset(
      _normalizedPosition.dx < 0.5 ? 0 : 1,
      _normalizedPosition.dy,
    );
    setState(() {
      _isDragging = false;
      _normalizedPosition = snapped;
    });
    widget.onPositionChanged(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minLeft = _edgeInset;
        final maxLeft = (constraints.maxWidth - widget.size - _edgeInset).clamp(
          minLeft,
          double.infinity,
        );
        final minTop = media.padding.top + _appBarClearance;
        final maxTop =
            (constraints.maxHeight -
                    widget.size -
                    media.padding.bottom -
                    _edgeInset)
                .clamp(minTop, double.infinity);
        _movementBounds = Rect.fromLTRB(minLeft, minTop, maxLeft, maxTop);
        final position = _absolutePosition(_normalizedPosition);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              key: const ValueKey('maki-coach-bubble-position'),
              left: position.dx,
              top: position.dy,
              duration: _isDragging || reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                key: const ValueKey('maki-coach-bubble'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: (_) => _finishDrag(),
                onPanCancel: _finishDrag,
                child: Semantics(
                  button: true,
                  label: widget.tooltip,
                  child: Tooltip(
                    message: widget.tooltip,
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLowest,
                      elevation: 0,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: widget.onTap,
                        customBorder: const CircleBorder(),
                        focusColor: theme.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        child: Container(
                          width: widget.size,
                          height: widget.size,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            boxShadow: AppShadows.soft(
                              theme.brightness,
                              theme.colorScheme.primary,
                            ),
                          ),
                          child: Center(child: widget.child),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
