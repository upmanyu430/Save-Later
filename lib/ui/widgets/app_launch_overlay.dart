import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Coordinates cold-launch animation timing across the app so grid items can
/// synchronize their entrance stagger with the launch curtain lift.
class LaunchTransitionCoordinator {
  LaunchTransitionCoordinator._();

  static DateTime? _coldLaunchStart;
  static bool _isLaunchActive = false;

  /// Marks the start of a cold-launch overlay animation.
  static void markLaunchStarted() {
    _coldLaunchStart = DateTime.now();
    _isLaunchActive = true;
  }

  /// Marks the cold-launch overlay as finished or skipped.
  static void markLaunchCompleted() {
    _isLaunchActive = false;
  }

  /// Resets coordinator state (for tests).
  @visibleForTesting
  static void reset() {
    _coldLaunchStart = null;
    _isLaunchActive = false;
  }

  /// Returns the remaining delay until [targetDelay] (~450ms) from cold launch,
  /// or [Duration.zero] once the curtain has cleared or when no launch overlay
  /// is active.
  static Duration remainingCardSlamDelay({
    Duration targetDelay = const Duration(milliseconds: 450),
  }) {
    if (!_isLaunchActive || _coldLaunchStart == null) {
      return Duration.zero;
    }
    final elapsed = DateTime.now().difference(_coldLaunchStart!);
    final remaining = targetDelay - elapsed;
    if (remaining <= Duration.zero) {
      return Duration.zero;
    }
    return remaining;
  }
}

/// Overlay-based 3-stage neo-brutalist launch transition rendered above the live
/// initial route inside [MaterialApp.router]'s `builder`.
class AppLaunchOverlay extends StatefulWidget {
  final Widget child;
  final bool hapticFeedback;
  final bool skipAnimation;
  final VoidCallback? onFirstFrame;

  /// Logical size of the centered emblem, matching the 448px @4x native splash
  /// asset (112dp).
  static const double emblemSize = 112.0;
  static const Duration totalDuration = Duration(milliseconds: 720);

  const AppLaunchOverlay({
    super.key,
    required this.child,
    this.hapticFeedback = true,
    this.skipAnimation = false,
    this.onFirstFrame,
  });

  @override
  State<AppLaunchOverlay> createState() => _AppLaunchOverlayState();
}

class _AppLaunchOverlayState extends State<AppLaunchOverlay>
    with SingleTickerProviderStateMixin {
  static const double _dipEnd = 130.0 / 720.0;
  static const double _popEnd = 390.0 / 720.0;
  static const double _curtainStart = 430.0 / 720.0;

  AnimationController? _controller;
  late final ValueNotifier<double> _childScale;

  bool _isOverlayMounted = true;
  bool _hasEvaluatedDependencies = false;
  bool _hasFiredPopHaptic = false;
  bool _hasNotifiedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    _childScale = ValueNotifier<double>(widget.skipAnimation ? 1.0 : 0.96);

    if (widget.skipAnimation) {
      _isOverlayMounted = false;
      LaunchTransitionCoordinator.markLaunchCompleted();
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: AppLaunchOverlay.totalDuration,
      )
        ..addListener(_handleTick)
        ..addStatusListener(_handleStatusChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeNativeSplashOnce();
      if (!mounted) return;
      if (_isOverlayMounted && _controller != null && !_controller!.isAnimating) {
        LaunchTransitionCoordinator.markLaunchStarted();
        _controller!.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasEvaluatedDependencies) return;
    _hasEvaluatedDependencies = true;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations || widget.skipAnimation) {
      _skipImmediately();
    }
  }

  void _removeNativeSplashOnce() {
    if (_hasNotifiedFirstFrame) return;
    _hasNotifiedFirstFrame = true;
    if (widget.onFirstFrame != null) {
      widget.onFirstFrame!();
    } else {
      FlutterNativeSplash.remove();
    }
  }

  void _skipImmediately() {
    _controller?.stop();
    _disposeController();
    _childScale.value = 1.0;
    LaunchTransitionCoordinator.markLaunchCompleted();
    if (_isOverlayMounted) {
      _isOverlayMounted = false;
    }
  }

  void _handleTick() {
    final controller = _controller;
    if (controller == null) return;
    final t = controller.value;

    // Stage 2 pop frame: fire a single light impact haptic if enabled.
    if (t >= _dipEnd && !_hasFiredPopHaptic) {
      _hasFiredPopHaptic = true;
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }

    // Stage 3: scale live screen underneath from 0.96 -> 1.0.
    if (t >= _curtainStart) {
      final p = ((t - _curtainStart) / (1.0 - _curtainStart)).clamp(0.0, 1.0);
      final eased = Curves.easeInOutCubic.transform(p);
      _childScale.value = lerpDouble(0.96, 1.0, eased)!;
    } else {
      _childScale.value = 0.96;
    }
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _childScale.value = 1.0;
      LaunchTransitionCoordinator.markLaunchCompleted();
      _disposeController();
      setState(() {
        _isOverlayMounted = false;
      });
    }
  }

  void _disposeController() {
    final controller = _controller;
    if (controller != null) {
      _controller = null;
      controller.removeListener(_handleTick);
      controller.removeStatusListener(_handleStatusChanged);
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    _childScale.dispose();
    super.dispose();
  }

  double _computeEmblemScale(double t) {
    if (t < _dipEnd) {
      // Stage 1 (0-130ms): Anticipation Dip (1.0 -> 0.90)
      final p = (t / _dipEnd).clamp(0.0, 1.0);
      final eased = Curves.easeOut.transform(p);
      return lerpDouble(1.0, 0.90, eased)!;
    } else if (t < _popEnd) {
      // Stage 2 (130-390ms): Mechanical Pop (0.90 -> 1.0 with easeOutBack)
      final p = ((t - _dipEnd) / (_popEnd - _dipEnd)).clamp(0.0, 1.0);
      final eased = Curves.easeOutBack.transform(p);
      return lerpDouble(0.90, 1.0, eased)!;
    } else if (t < _curtainStart) {
      // Hold (390-430ms)
      return 1.0;
    } else {
      // Stage 3 (430-720ms): Curtain Lift subtle scale-up (1.0 -> 1.12)
      final p = ((t - _curtainStart) / (1.0 - _curtainStart)).clamp(0.0, 1.0);
      final eased = Curves.easeInOutCubic.transform(p);
      return lerpDouble(1.0, 1.12, eased)!;
    }
  }

  double _computeWordmarkProgress(double t) {
    if (t < _dipEnd) return 0.0;
    if (t >= _popEnd) return 1.0;
    final p = ((t - _dipEnd) / (_popEnd - _dipEnd)).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(p);
  }

  double _computeBackdropOpacity(double t) {
    if (t <= _curtainStart) return 1.0;
    final p = ((t - _curtainStart) / (1.0 - _curtainStart)).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(p);
    return (1.0 - eased).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fixed slot for the live screen underneath so it never remounts when
        // the launch overlay completes and unmounts.
        RepaintBoundary(
          child: ValueListenableBuilder<double>(
            valueListenable: _childScale,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
        if (_isOverlayMounted && controller != null)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final t = controller.value;
                final backdropOpacity = _computeBackdropOpacity(t);
                final emblemScale = _computeEmblemScale(t);
                final showHardShadow = t >= _dipEnd;
                final wordmarkProgress = _computeWordmarkProgress(t);
                final wordmarkOpacity = wordmarkProgress.clamp(0.0, 1.0);
                final wordmarkOffsetY = 10.0 * (1.0 - wordmarkProgress);

                return IgnorePointer(
                  ignoring: t >= _curtainStart,
                  child: Opacity(
                    opacity: backdropOpacity,
                    child: ColoredBox(
                      color: AppTheme.background,
                      child: Center(
                        child: SizedBox(
                          width: AppLaunchOverlay.emblemSize,
                          height: AppLaunchOverlay.emblemSize,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: emblemScale,
                                alignment: Alignment.center,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // Stage 2: #1C1C1C hard drop shadow (Offset(4, 4))
                                    Transform.translate(
                                      offset: const Offset(4.0, 4.0),
                                      child: Opacity(
                                        opacity: showHardShadow ? 1.0 : 0.0,
                                        child: Container(
                                          width: AppLaunchOverlay.emblemSize * 0.92,
                                          height: AppLaunchOverlay.emblemSize * 0.92,
                                          decoration: BoxDecoration(
                                            color: AppTheme.border,
                                            borderRadius: BorderRadius.circular(
                                              AppLaunchOverlay.emblemSize * 0.22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/splash_emblem.png',
                                      width: AppLaunchOverlay.emblemSize,
                                      height: AppLaunchOverlay.emblemSize,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: AppLaunchOverlay.emblemSize * 0.92,
                                        height: AppLaunchOverlay.emblemSize * 0.92,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent,
                                          borderRadius: BorderRadius.circular(
                                            AppLaunchOverlay.emblemSize * 0.22,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.border,
                                            width: 4.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.bookmark_rounded,
                                          size: 56,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // SAVE LATER wordmark positioned below the centered
                              // emblem so it never shifts the emblem's Frame 1 center.
                              Positioned(
                                top: AppLaunchOverlay.emblemSize + 20.0,
                                left: -100.0,
                                right: -100.0,
                                child: Center(
                                  child: Opacity(
                                    opacity: wordmarkOpacity,
                                    child: Transform.translate(
                                      offset: Offset(0.0, wordmarkOffsetY),
                                      child: Text(
                                        'SAVE LATER',
                                        textScaler: TextScaler.noScaling,
                                        style: GoogleFonts.bricolageGrotesque(
                                          fontSize: 28.0,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: AppTheme.border,
                                          height: 1.0,
                                          decoration: TextDecoration.none,
                                        ).copyWith(
                                          fontFamilyFallback: const ['Gabarito'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
