import 'dart:math' as math;

import 'package:flutter/material.dart';

final AnimationStyle _defaultSheetAnimationStyle = AnimationStyle(
  duration: const Duration(milliseconds: 260),
  reverseDuration: const Duration(milliseconds: 200),
  curve: const Cubic(0.16, 1.0, 0.3, 1.0),
  reverseCurve: const Cubic(0.4, 0.0, 1.0, 1.0),
);

/// Opens a modal bottom sheet with Save Later's standardized transition
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

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.52),
    sheetAnimationStyle: _defaultSheetAnimationStyle,
    builder: builder,
  );
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
          final isCurrent = ModalRoute.of(innerContext)?.isCurrent ?? true;
          if (isCurrent || !widget.freezeWhenCovered) {
            _frozenBottomInset = MediaQuery.viewInsetsOf(innerContext).bottom;
          }
          final effectiveBottomInset = _frozenBottomInset;

          final view = View.maybeOf(innerContext);
          final windowPaddingTop = view != null
              ? MediaQueryData.fromView(view).padding.top
              : 0.0;
          final mediaPaddingTop = MediaQuery.paddingOf(innerContext).top;
          final statusBarHeight =
              windowPaddingTop > 0 ? windowPaddingTop : mediaPaddingTop;
          final topClearance = statusBarHeight + 16.0;
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
              top: topClearance,
              bottom: effectiveBottomInset,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
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
