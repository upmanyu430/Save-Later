import 'package:flutter/material.dart';
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
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;

  bool get _isEnabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    // Emil Kowalski Design Engineering: Snappy 60ms press-down, 110ms spring release.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 110),
    );
    // Never use easeIn for UI animations (starts slow/sluggish). Use easeOut for instant responsiveness.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isEnabled) return;
    _pointerDownPosition = event.position;
    HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    return Opacity(
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
                  if (!_controller.isAnimating && _controller.value == 0.0) {
                    _controller.forward();
                  }
                }
              : null,
          onTap: _isEnabled ? _handleTap : null,
          onTapCancel: _isEnabled ? _handleTapCancel : null,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;
              final baseOffset = widget.customShadowOffset ??
                  Offset(widget.shadowOffset, widget.shadowOffset);
              final hasShadow = baseOffset.dx != 0 || baseOffset.dy != 0;
              final pressOffset = baseOffset * t;
              final currentShadow = baseOffset * (1.0 - t).clamp(0.0, 1.0);
              // Subtle scale (0.97 at peak press) per Emil Kowalski's guidelines
              final scale = 1.0 - (t * 0.03);

              return Transform.translate(
                offset: pressOffset,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: widget.borderColor ?? AppTheme.border,
                        width: widget.borderWidth,
                      ),
                      boxShadow: hasShadow
                          ? [
                              BoxShadow(
                                color: widget.shadowColor ?? AppTheme.border,
                                offset: currentShadow,
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
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
    );
  }
}
