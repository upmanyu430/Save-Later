import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeoPressable extends StatefulWidget {
  final VoidCallback? onTap;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final VoidCallback? onLongPressCancel;
  final double shadowOffset;
  final double scaleSquash;
  final HitTestBehavior behavior;
  final bool enableFeedback;
  final double minTouchTargetSize;
  final double borderRadius;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget Function(
      BuildContext context, double t, double currentShadowOffset) builder;

  const NeoPressable({
    super.key,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onLongPressCancel,
    this.shadowOffset = 2.0,
    this.scaleSquash = 0.025,
    this.behavior = HitTestBehavior.opaque,
    this.enableFeedback = true,
    this.minTouchTargetSize = 44.0,
    this.borderRadius = 12.0,
    this.focusNode,
    this.autofocus = false,
    required this.builder,
  });

  @override
  State<NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<NeoPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;
  FocusNode? _internalFocusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _isPressable =>
      widget.onTap != null || widget.onLongPressStart != null;

  @override
  void initState() {
    super.initState();
    // Snappy 60ms press-down, 110ms spring release for immediate tactile feedback.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 110),
    );
    // Never use easeIn for UI animations (starts slow/sluggish). Use easeOut for instant responsiveness.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant NeoPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null && widget.focusNode != null) {
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      }
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isPressable) return;
    _pointerDownPosition = event.position;
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerDownPosition != null) {
      final delta = (event.position - _pointerDownPosition!).distance;
      // Spring back up if finger drags beyond threshold (e.g. scroll gesture)
      if (delta > 20.0) {
        _controller.reverse();
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    _controller.reverse();
  }

  void _handleTap() {
    _pointerDownPosition = null;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _pointerDownPosition = null;
    _controller.reverse();
  }

  void _handleActivate() {
    if (!_isPressable) return;
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reverse();
      }
    });
    widget.onTap?.call();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _pointerDownPosition = null;
    _controller.reverse();
    widget.onLongPressStart?.call(details);
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    widget.onLongPressMoveUpdate?.call(details);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    widget.onLongPressEnd?.call(details);
  }

  void _handleLongPressCancel() {
    _controller.reverse();
    widget.onLongPressCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPressable) {
      return widget.builder(context, 0.0, widget.shadowOffset);
    }

    return Semantics(
      button: true,
      enabled: _isPressable,
      child: FocusableActionDetector(
        enabled: _isPressable,
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            _isPressable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) {
          if (_isFocused != value) {
            setState(() => _isFocused = value);
          }
        },
        onFocusChange: (value) {
          if (_isFocused != value) {
            setState(() => _isFocused = value);
          }
        },
        onShowHoverHighlight: (value) {
          if (_isHovered != value) {
            setState(() => _isHovered = value);
          }
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ButtonActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _handleActivate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _handleActivate(),
          ),
        },
        child: Listener(
          behavior: widget.behavior,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            behavior: widget.behavior,
            onTapDown: (_) {
              if (!_controller.isAnimating && _controller.value == 0.0) {
                _controller.forward();
              }
            },
            onTap: widget.onTap != null ? _handleTap : null,
            onTapCancel: _handleTapCancel,
            onLongPressStart:
                widget.onLongPressStart != null ? _handleLongPressStart : null,
            onLongPressMoveUpdate: widget.onLongPressMoveUpdate != null
                ? _handleLongPressMoveUpdate
                : null,
            onLongPressEnd:
                widget.onLongPressEnd != null ? _handleLongPressEnd : null,
            onLongPressCancel:
                widget.onLongPressCancel != null ? _handleLongPressCancel : null,
            child: _NeoTouchTarget(
              minSize: widget.minTouchTargetSize,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  final t = _animation.value;
                  final offset = t * widget.shadowOffset;
                  final currentShadow =
                      (1.0 - t).clamp(0.0, 1.0) * widget.shadowOffset;
                  final scale = 1.0 - (t * widget.scaleSquash);

                  Widget content = Transform.translate(
                    offset: Offset(offset, offset),
                    child: Transform.scale(
                      scale: scale,
                      child: widget.builder(context, t, currentShadow),
                    ),
                  );

                  if (_isFocused) {
                    content = Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.border,
                            offset: Offset.zero,
                            spreadRadius: 4.0,
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: AppTheme.primary,
                            offset: Offset.zero,
                            spreadRadius: 2.5,
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: content,
                    );
                  }

                  return content;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoTouchTarget extends SingleChildRenderObjectWidget {
  final double minSize;

  const _NeoTouchTarget({
    required this.minSize,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderNeoTouchTarget(minSize: minSize);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderNeoTouchTarget renderObject) {
    renderObject.minSize = minSize;
  }
}

class _RenderNeoTouchTarget extends RenderProxyBox {
  _RenderNeoTouchTarget({
    RenderBox? child,
    required double minSize,
  })  : _minSize = minSize,
        super(child);

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (_minSize != value) {
      _minSize = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints, parentUsesSize: true);
      final double width = math.max(child!.size.width, constraints.minWidth);
      final double height = math.max(child!.size.height, constraints.minHeight);
      final double targetWidth =
          constraints.constrainWidth(math.max(width, minSize));
      final double targetHeight =
          constraints.constrainHeight(math.max(height, minSize));
      size = Size(targetWidth, targetHeight);
    } else {
      size = constraints.constrain(Size(minSize, minSize));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final double dx = (size.width - child!.size.width) / 2.0;
      final double dy = (size.height - child!.size.height) / 2.0;
      context.paintChild(child!, offset + Offset(dx, dy));
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final double extraWidth = math.max(0.0, minSize - size.width);
    final double extraHeight = math.max(0.0, minSize - size.height);
    final Rect hitBounds = Rect.fromLTWH(
      -extraWidth / 2.0,
      -extraHeight / 2.0,
      size.width + extraWidth,
      size.height + extraHeight,
    );

    if (hitBounds.contains(position)) {
      final Offset childOffset = Offset(
        (size.width - (child?.size.width ?? size.width)) / 2.0,
        (size.height - (child?.size.height ?? size.height)) / 2.0,
      );
      final Offset transformedPosition = position - childOffset;
      if (child != null &&
          child!.hitTest(result, position: transformedPosition)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
      if (hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;
}
