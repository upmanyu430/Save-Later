import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Wraps the application subtree and transitions between themes in a single
/// rebuild underneath a GPU-composited circular-reveal snapshot of the
/// previous frame, eliminating multi-frame `ThemeData.lerp` jank.
class ThemeTransitionScope extends StatefulWidget {
  final Widget child;

  const ThemeTransitionScope({
    super.key,
    required this.child,
  });

  static ThemeTransitionScopeState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ThemeTransitionScopeState>();
  }

  @override
  State<ThemeTransitionScope> createState() => ThemeTransitionScopeState();
}

class ThemeTransitionScopeState extends State<ThemeTransitionScope>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 340);
  static const Cubic _revealCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;
  late final Animation<double> _animation;

  ui.Image? _overlayImage;
  Offset? _revealOrigin;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: _revealCurve,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _clearOverlayImage();
      }
    });
  }

  @override
  void dispose() {
    final image = _overlayImage;
    _overlayImage = null;
    image?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _disposeAfterFrame(ui.Image? image) {
    if (image == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      image.dispose();
    });
  }

  void _clearOverlayImage() {
    final image = _overlayImage;
    if (image == null && mounted) return;
    if (mounted) {
      setState(() {
        _overlayImage = null;
        _revealOrigin = null;
      });
    } else {
      _overlayImage = null;
      _revealOrigin = null;
    }
    _disposeAfterFrame(image);
  }

  /// Captures the current rendered frame, executes [applyTheme] in a single
  /// frame underneath, and reveals it smoothly from [origin] (global coordinates).
  void runTransition({
    Offset? origin,
    required VoidCallback applyTheme,
  }) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (disableAnimations ||
        boundary == null ||
        !boundary.hasSize ||
        boundary.debugNeedsPaint) {
      applyTheme();
      return;
    }

    ui.Image? snapshot;
    try {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
      snapshot = boundary.toImageSync(pixelRatio: dpr);
    } catch (_) {
      applyTheme();
      return;
    }

    final localOrigin =
        origin != null ? boundary.globalToLocal(origin) : null;
    final previousImage = _overlayImage;

    setState(() {
      _overlayImage = snapshot;
      _revealOrigin = localOrigin;
    });
    _disposeAfterFrame(previousImage);

    applyTheme();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final overlayImage = _overlayImage;

    return RepaintBoundary(
      key: _boundaryKey,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (overlayImage != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final t = _animation.value;
                    final origin = _revealOrigin;
                    if (origin == null) {
                      return Opacity(
                        opacity: (1.0 - t).clamp(0.0, 1.0),
                        child: child,
                      );
                    }
                    return ClipPath(
                      clipper: _InvertedCircularRevealClipper(
                        center: origin,
                        progress: t,
                      ),
                      child: child,
                    );
                  },
                  child: RawImage(
                    image: overlayImage,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvertedCircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double progress;

  const _InvertedCircularRevealClipper({
    required this.center,
    required this.progress,
  });

  @override
  Path getClip(Size size) {
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    final maxRadius = math.sqrt((dx * dx) + (dy * dy));
    final holeRadius = maxRadius * progress;

    final path = Path()
      ..addRect(Offset.zero & size);
    if (holeRadius > 0) {
      path.addOval(Rect.fromCircle(center: center, radius: holeRadius));
    }
    return path..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(covariant _InvertedCircularRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}
