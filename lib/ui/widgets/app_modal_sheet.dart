import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const Duration _defaultSheetEnterDuration = Duration(milliseconds: 260);
const Duration _defaultSheetExitDuration = Duration(milliseconds: 200);
const Curve _defaultSheetEnterCurve = Cubic(0.16, 1.0, 0.3, 1.0);
// Evaluated from 1.0 -> 0.0 during reverse: starts smoothly from rest at t=1.0
// and accelerates cleanly off-screen toward t=0.0 without an initial frame jump.
const Curve _defaultSheetExitCurve = Cubic(0.2, 0.85, 0.7, 1.0);
const double _minSheetFlingVelocity = 700.0;
const double _sheetCloseProgressThreshold = 0.5;

final AnimationStyle _defaultSheetAnimationStyle = AnimationStyle(
  duration: _defaultSheetEnterDuration,
  reverseDuration: _defaultSheetExitDuration,
  curve: _defaultSheetEnterCurve,
  reverseCurve: _defaultSheetExitCurve,
);

/// Opens a modal bottom sheet with Save Later's GPU-composited transition
/// curve, scrim, and optional pre-open focus dismissal.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
  bool unfocusBeforeOpen = true,
}) {
  if (unfocusBeforeOpen) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  final navigator = Navigator.of(context);
  final localizations = MaterialLocalizations.of(context);
  final themeBarrier = Theme.of(context).bottomSheetTheme.modalBarrierColor;

  return navigator.push<T>(
    _AppModalSheetRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint:
          localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      modalBarrierColor:
          barrierColor ?? themeBarrier ?? Colors.black.withValues(alpha: 0.52),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      animationStyle: _defaultSheetAnimationStyle,
    ),
  );
}

/// Marker inherited scope indicating a sheet is hosted inside
/// [_AppModalSheetRoute] where the route already handles bottom alignment and
/// screen-wide scrim dismissal.
class _AppModalRouteScope extends InheritedWidget {
  const _AppModalRouteScope({required super.child});

  static bool isHosted(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AppModalRouteScope>() != null;

  @override
  bool updateShouldNotify(_AppModalRouteScope oldWidget) => false;
}

/// Returns whether [context] is hosted inside [showAppModalSheet]'s route.
bool isAppModalRouteHosted(BuildContext context) =>
    _AppModalRouteScope.isHosted(context);

class _AppModalSheetRoute<T> extends PopupRoute<T> {
  _AppModalSheetRoute({
    required this.builder,
    this.capturedThemes,
    this.barrierLabel,
    this.barrierOnTapHint,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    this.animationStyle,
  });

  final WidgetBuilder builder;
  final CapturedThemes? capturedThemes;
  @override
  final String? barrierLabel;
  final String? barrierOnTapHint;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final AnimationStyle? animationStyle;

  AnimationController? _animationController;
  CurvedAnimation? _barrierAnimation;

  @override
  Duration get transitionDuration =>
      animationStyle?.duration ?? _defaultSheetEnterDuration;

  @override
  Duration get reverseTransitionDuration =>
      animationStyle?.reverseDuration ?? _defaultSheetExitDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      debugLabel: 'AppModalSheet',
      vsync: navigator!,
    );
    return _animationController!;
  }

  @override
  Animation<double> createAnimation() {
    final anim = super.createAnimation();
    _barrierAnimation = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return anim;
  }

  @override
  bool didPop(T? result) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.hasFocus) {
      primaryFocus.unfocus();
    }
    return super.didPop(result);
  }

  @override
  void dispose() {
    _barrierAnimation?.dispose();
    _barrierAnimation = null;
    super.dispose();
  }

  @override
  Widget buildModalBarrier() {
    final color = barrierColor;
    final hasVisibleScrim = color.a > 0 && !offstage;
    final barrier = ModalBarrier(
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      semanticsOnTapHint: barrierOnTapHint,
    );
    if (!hasVisibleScrim || _barrierAnimation == null) {
      return barrier;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: RepaintBoundary(
            child: FadeTransition(
              opacity: _barrierAnimation!,
              child: ColoredBox(color: color),
            ),
          ),
        ),
        barrier,
      ],
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final Widget content = _AppModalRouteScope(
      child: Material(
        type: MaterialType.transparency,
        child: Builder(builder: builder),
      ),
    );
    return capturedThemes?.wrap(content) ?? content;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final routeLabel = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => '',
      TargetPlatform.android ||
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows =>
        MaterialLocalizations.of(context).dialogLabel,
    };

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: routeLabel,
      explicitChildNodes: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _AppModalSheetTransition(
          controller: _animationController!,
          enterCurve: animationStyle?.curve ?? _defaultSheetEnterCurve,
          exitCurve: animationStyle?.reverseCurve ?? _defaultSheetExitCurve,
          enableDrag: enableDrag,
          onDismiss: () {
            if (isCurrent) {
              Navigator.of(context).pop();
            }
          },
          child: child,
        ),
      ),
    );
  }
}

class _SegmentCurve extends Curve {
  const _SegmentCurve({
    required this.fromT,
    required this.fromY,
    required this.toY,
    required this.curve,
  });

  final double fromT;
  final double fromY;
  final double toY;
  final Curve curve;

  @override
  double transformInternal(double t) {
    if (toY == 0.0) {
      if (fromT <= 0.0) return 0.0;
      final localT = (t / fromT).clamp(0.0, 1.0);
      return fromY * curve.transform(localT);
    }
    final span = 1.0 - fromT;
    if (span <= 0.0) return toY;
    final localT = ((t - fromT) / span).clamp(0.0, 1.0);
    return fromY + (toY - fromY) * curve.transform(localT);
  }
}

class _AppModalSheetTransition extends StatefulWidget {
  const _AppModalSheetTransition({
    required this.controller,
    required this.enterCurve,
    required this.exitCurve,
    required this.enableDrag,
    required this.onDismiss,
    required this.child,
  });

  final AnimationController controller;
  final Curve enterCurve;
  final Curve exitCurve;
  final bool enableDrag;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_AppModalSheetTransition> createState() =>
      _AppModalSheetTransitionState();
}

class _AppModalSheetTransitionState extends State<_AppModalSheetTransition> {
  final GlobalKey _sheetKey = GlobalKey(debugLabel: 'AppModalSheet child');
  late Curve _activeCurve;
  late AnimationStatus _lastStatus;
  bool _isDragging = false;
  double _dragHeight = 1.0;
  double _lastPaintedValue = 0.0;

  @override
  void initState() {
    super.initState();
    _activeCurve = widget.enterCurve;
    _lastStatus = widget.controller.status;
    widget.controller.addStatusListener(_handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant _AppModalSheetTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeStatusListener(_handleStatusChanged);
      _lastStatus = widget.controller.status;
      widget.controller.addStatusListener(_handleStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeStatusListener(_handleStatusChanged);
    super.dispose();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (_isDragging) {
      _lastStatus = status;
      return;
    }

    if (status == AnimationStatus.reverse &&
        _lastStatus != AnimationStatus.reverse) {
      final t = widget.controller.value;
      if (t >= 0.999) {
        _activeCurve = widget.exitCurve;
      } else if (t > 0.0) {
        _activeCurve = _SegmentCurve(
          fromT: t,
          fromY: _lastPaintedValue,
          toY: 0.0,
          curve: widget.exitCurve,
        );
      }
    } else if (status == AnimationStatus.forward &&
        _lastStatus != AnimationStatus.forward) {
      final t = widget.controller.value;
      if (t <= 0.001) {
        _activeCurve = widget.enterCurve;
      } else if (t < 1.0) {
        _activeCurve = _SegmentCurve(
          fromT: t,
          fromY: _lastPaintedValue,
          toY: 1.0,
          curve: widget.enterCurve,
        );
      }
    } else if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _activeCurve = widget.enterCurve;
    }

    _lastStatus = status;
  }

  void _handleDragStart(DragStartDetails details) {
    final renderBox =
        _sheetKey.currentContext?.findRenderObject() as RenderBox?;
    _dragHeight = math.max(1.0, renderBox?.size.height ?? 1.0);
    _isDragging = true;
    _activeCurve = Curves.linear;
    widget.controller.stop();
    widget.controller.value = _lastPaintedValue.clamp(0.0, 1.0);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || widget.controller.status == AnimationStatus.reverse) {
      return;
    }
    final delta = details.primaryDelta ?? 0.0;
    widget.controller.value =
        (widget.controller.value - delta / _dragHeight).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    final velocityY = details.velocity.pixelsPerSecond.dy;
    final currentValue = widget.controller.value;

    final isClosing = velocityY > _minSheetFlingVelocity ||
        currentValue < _sheetCloseProgressThreshold;

    if (isClosing) {
      _activeCurve = currentValue > 0.0
          ? _SegmentCurve(
              fromT: currentValue,
              fromY: currentValue,
              toY: 0.0,
              curve: Curves.easeOutCubic,
            )
          : Curves.linear;
      _lastStatus = AnimationStatus.reverse;
      widget.onDismiss();
    } else {
      _activeCurve = Split(currentValue, endCurve: widget.enterCurve);
      _lastStatus = AnimationStatus.forward;
      widget.controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget sheet = RepaintBoundary(
      key: _sheetKey,
      child: widget.child,
    );

    if (widget.enableDrag) {
      sheet = RawGestureDetector(
        excludeFromSemantics: true,
        gestures: <Type, GestureRecognizerFactory<GestureRecognizer>>{
          VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
              VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer(debugOwner: this),
            (VerticalDragGestureRecognizer instance) {
              instance
                ..onStart = _handleDragStart
                ..onUpdate = _handleDragUpdate
                ..onEnd = _handleDragEnd
                ..onlyAcceptDragOnThreshold = true;
            },
          ),
        },
        child: sheet,
      );
    }

    return AnimatedBuilder(
      animation: widget.controller,
      child: sheet,
      builder: (context, child) {
        final rawValue = widget.controller.value.clamp(0.0, 1.0);
        final visualValue = _isDragging
            ? rawValue
            : _activeCurve.transform(rawValue).clamp(0.0, 1.0);
        _lastPaintedValue = visualValue;

        return FractionalTranslation(
          translation: Offset(0.0, 1.0 - visualValue),
          child: child,
        );
      },
    );
  }
}

/// Dismisses an active modal sheet cleanly, unfocusing any active input
/// before popping so IME hide does not collide with the route exit transition.
void dismissAppModalSheet<T>(BuildContext context, [T? result]) {
  final primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus != null && primaryFocus.hasFocus) {
    primaryFocus.unfocus();
  }
  if (Navigator.canPop(context)) {
    Navigator.of(context).pop<T>(result);
  }
}

/// Requests focus on [node] after the enclosing [ModalRoute] entrance animation
/// completes (or on the next frame if no active entrance transition exists).
VoidCallback? requestFocusAfterTransition(
  BuildContext context,
  FocusNode node, {
  bool Function()? isMounted,
}) {
  bool canFocus() => (isMounted?.call() ?? true) && node.canRequestFocus;

  final animation = ModalRoute.of(context)?.animation;
  if (animation == null ||
      animation.isCompleted ||
      animation.status == AnimationStatus.completed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (canFocus()) {
        node.requestFocus();
      }
    });
    return null;
  }

  late void Function(AnimationStatus) listener;
  listener = (AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      animation.removeStatusListener(listener);
      if (canFocus()) {
        node.requestFocus();
      }
    } else if (status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
    }
  };
  animation.addStatusListener(listener);
  return () => animation.removeStatusListener(listener);
}

/// Mixin for modal sheet states that want to focus a [FocusNode] once the
/// modal route entrance transition has finished.
mixin AppModalDeferredFocusMixin<T extends StatefulWidget> on State<T> {
  FocusNode? _deferredFocusNode;
  VoidCallback? _cancelDeferredFocus;
  bool _deferredFocusAttached = false;

  /// Schedules [node] to receive focus once the modal entrance finishes.
  void scheduleDeferredFocus(FocusNode node) {
    _deferredFocusNode = node;
    if (_deferredFocusAttached || !mounted) return;
    _attachDeferredFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_deferredFocusAttached && _deferredFocusNode != null) {
      _attachDeferredFocus();
    }
  }

  void _attachDeferredFocus() {
    final node = _deferredFocusNode;
    if (node == null || _deferredFocusAttached) return;
    _deferredFocusAttached = true;
    _cancelDeferredFocus?.call();
    _cancelDeferredFocus = requestFocusAfterTransition(
      context,
      node,
      isMounted: () => mounted,
    );
  }

  @override
  void dispose() {
    _cancelDeferredFocus?.call();
    _cancelDeferredFocus = null;
    super.dispose();
  }
}

/// Resolves status bar top clearance without depending on `viewInsets`.
double resolveModalTopClearance(BuildContext context, {double extra = 16.0}) {
  final view = View.maybeOf(context);
  final windowPaddingTop =
      view != null ? MediaQueryData.fromView(view).padding.top : 0.0;
  final mediaPaddingTop = MediaQuery.paddingOf(context).top;
  final statusBarHeight =
      windowPaddingTop > 0 ? windowPaddingTop : mediaPaddingTop;
  return statusBarHeight + extra;
}

/// Rebuilds only its wrapper [builder] on IME `viewInsets` changes while
/// preserving [child] across frames and freezing `bottomInset` during route
/// exit animations so dismissal never fights the closing keyboard.
class AppModalImeBuilder extends StatefulWidget {
  final Widget child;
  final Widget Function(
    BuildContext context,
    double bottomInset,
    double safeBottom,
    Widget child,
  ) builder;

  const AppModalImeBuilder({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  State<AppModalImeBuilder> createState() => _AppModalImeBuilderState();
}

class _AppModalImeBuilderState extends State<AppModalImeBuilder> {
  double _frozenBottomInset = 0.0;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final isReversing = route?.animation?.status == AnimationStatus.reverse;
    final currentInset = MediaQuery.viewInsetsOf(context).bottom;
    if (!isReversing) {
      _frozenBottomInset = currentInset;
    }
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return widget.builder(context, _frozenBottomInset, safeBottom, widget.child);
  }
}

/// GPU-isolated keyboard lift wrapper for modal bottom sheets.
///
/// Wraps [child] in a [RepaintBoundary] outside the `MediaQuery.viewInsetsOf`
/// builder so IME animation ticks only reposition the cached layer without
/// rebuilding the card subtree.
class AppModalKeyboardLift extends StatefulWidget {
  final Widget child;
  final double maxWidth;
  final double horizontalPadding;
  final double? maxHeight;
  final bool freezeWhenCovered;
  final VoidCallback? onOutsideTap;

  const AppModalKeyboardLift({
    super.key,
    required this.child,
    this.maxWidth = 420.0,
    this.horizontalPadding = 5.0,
    this.maxHeight,
    this.freezeWhenCovered = true,
    this.onOutsideTap,
  });

  @override
  State<AppModalKeyboardLift> createState() => _AppModalKeyboardLiftState();
}

class _AppModalKeyboardLiftState extends State<AppModalKeyboardLift> {
  double _frozenBottomInset = 0.0;

  @override
  Widget build(BuildContext context) {
    final isHosted = isAppModalRouteHosted(context);
    final protectedChild = RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: widget.child,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onOutsideTap ?? () => dismissAppModalSheet(context),
      child: Builder(
        builder: (innerContext) {
          final route = ModalRoute.of(innerContext);
          final isCurrent = route?.isCurrent ?? true;
          final isReversing =
              route?.animation?.status == AnimationStatus.reverse;
          final currentInset = MediaQuery.viewInsetsOf(innerContext).bottom;
          if (!isReversing && (isCurrent || !widget.freezeWhenCovered)) {
            _frozenBottomInset = currentInset;
          }
          final effectiveBottomInset = _frozenBottomInset;

          final topClearance = resolveModalTopClearance(innerContext);
          final screenHeight = MediaQuery.sizeOf(innerContext).height;
          final availableHeight = math.max(
            0.0,
            screenHeight - topClearance - effectiveBottomInset,
          );
          final effectiveMaxHeight = widget.maxHeight != null
              ? math.min(availableHeight, widget.maxHeight!)
              : availableHeight;

          return Padding(
            padding: EdgeInsets.only(
              left: widget.horizontalPadding,
              right: widget.horizontalPadding,
              top: isHosted ? 0.0 : topClearance,
              bottom: effectiveBottomInset,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: isHosted ? 1.0 : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth,
                  maxHeight: effectiveMaxHeight,
                ),
                child: protectedChild,
              ),
            ),
          );
        },
      ),
    );
  }
}
