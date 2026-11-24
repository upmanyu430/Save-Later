import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? borderColor;
  final Color? shadowColor;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final Offset? customShadowOffset;
  final EdgeInsetsGeometry padding;
  final bool enableFeedback;
  final double minTouchTargetSize;
  final FocusNode? focusNode;
  final bool autofocus;

  const NeoButton({
    super.key,
    this.onPressed,
    required this.child,
    this.color = AppTheme.primary,
    this.borderColor,
    this.shadowColor,
    this.borderWidth = 3.0,
    this.borderRadius = 12.0,
    this.shadowOffset = 2.0,
    this.customShadowOffset,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXl, vertical: 14),
    this.enableFeedback = true,
    this.minTouchTargetSize = 44.0,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;
  FocusNode? _internalFocusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  bool get _isEnabled => widget.onPressed != null;

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
  void didUpdateWidget(covariant NeoButton oldWidget) {
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
    if (!_isEnabled) return;
    _pointerDownPosition = event.position;
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_pointerDownPosition != null) {
      final delta = (event.position - _pointerDownPosition!).distance;
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
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    _pointerDownPosition = null;
    _controller.reverse();
  }

  void _handleActivate() {
    if (!_isEnabled) return;
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reverse();
      }
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accentFocusColor = (widget.color == AppTheme.primary)
        ? const Color(0xFF3AC19F)
        : AppTheme.primary;

    final baseOffset = widget.customShadowOffset ??
        Offset(widget.shadowOffset, widget.shadowOffset);
    final hasShadow = baseOffset.dx != 0 || baseOffset.dy != 0;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: FocusableActionDetector(
        enabled: _isEnabled,
        focusNode: _effectiveFocusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
        child: Opacity(
          opacity: _isEnabled ? 1.0 : 0.5,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _isEnabled ? _onPointerDown : null,
            onPointerMove: _isEnabled ? _onPointerMove : null,
            onPointerCancel: _isEnabled ? _onPointerCancel : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _isEnabled
                  ? (_) {
                      if (!_controller.isAnimating &&
                          _controller.value == 0.0) {
                        _controller.forward();
                      }
                    }
                  : null,
              onTap: _isEnabled ? _handleTap : null,
              onTapCancel: _isEnabled ? _handleTapCancel : null,
              child: _NeoTouchTarget(
                minSize: widget.minTouchTargetSize,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final t = _animation.value;
                    final pressOffset = baseOffset * t;
                    final currentShadow =
                        baseOffset * (1.0 - t).clamp(0.0, 1.0);
                    // Subtle scale compression (0.97 at peak press) simulating mechanical depression.
                    final scale = 1.0 - (t * 0.03);

                    final List<BoxShadow> shadows = [];
                    // Solid crisp neo-brutalist focus rings when focused
                    if (_isFocused) {
                      shadows.addAll([
                        BoxShadow(
                          color: AppTheme.border,
                          offset: Offset.zero,
                          spreadRadius: 4.0,
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: accentFocusColor,
                          offset: Offset.zero,
                          spreadRadius: 2.5,
                          blurRadius: 0,
                        ),
                      ]);
                    }
                    if (hasShadow) {
                      shadows.add(
                        BoxShadow(
                          color: widget.shadowColor ?? AppTheme.border,
                          offset: currentShadow,
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      );
                    }

                    return Transform.translate(
                      offset: pressOffset,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: widget.padding,
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius:
                                BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: widget.borderColor ?? AppTheme.border,
                              width: widget.borderWidth,
                            ),
                            boxShadow: shadows.isNotEmpty ? shadows : null,
                          ),
                          child: Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: widget.child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
