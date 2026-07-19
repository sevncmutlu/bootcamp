import 'package:flutter/material.dart';
import 'package:maki_app/widgets/brand_wordmark.dart';
import 'package:maki_app/widgets/mascot.dart';

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({
    super.key,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 1700),
  });

  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _mascotEntrance;
  late final Animation<double> _wordmarkEntrance;
  late final Animation<Offset> _mascotPosition;
  late final Animation<Offset> _wordmarkPosition;
  bool _started = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _complete();
        }
      });
    _mascotEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    _wordmarkEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.78, curve: Curves.easeOutCubic),
    );
    _mascotPosition = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(_mascotEntrance);
    _wordmarkPosition = Tween<Offset>(
      begin: const Offset(0, 0.24),
      end: Offset.zero,
    ).animate(_wordmarkEntrance);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
      return;
    }
    _controller.forward();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onCompleted();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            container: true,
            label: 'MakiKoç açılış ekranı',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.68,
                    end: 1,
                  ).animate(_mascotEntrance),
                  child: FadeTransition(
                    opacity: _mascotEntrance,
                    child: SlideTransition(
                      position: _mascotPosition,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 224,
                            height: 224,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  scheme.primary.withValues(alpha: 0.18),
                                  scheme.primary.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                          const Mascot(
                            pose: MascotPose.wave,
                            size: 168,
                            withBadge: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _wordmarkEntrance,
                  child: SlideTransition(
                    position: _wordmarkPosition,
                    child: const BrandWordmark(fontSize: 42),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
