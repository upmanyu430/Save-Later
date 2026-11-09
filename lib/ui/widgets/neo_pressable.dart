import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final Widget Function(BuildContext context, double t, double currentShadowOffset) builder;

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
    required this.builder,
  });

  @override
  State<NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<NeoPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;

  bool get _isPressable => widget.onTap != null || widget.onLongPressStart != null;

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
      reverseCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
    );
  }

  @override
  void dispose() {
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

    return Listener(
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
        onLongPressStart: widget.onLongPressStart != null ? _handleLongPressStart : null,
        onLongPressMoveUpdate: widget.onLongPressMoveUpdate != null ? _handleLongPressMoveUpdate : null,
        onLongPressEnd: widget.onLongPressEnd != null ? _handleLongPressEnd : null,
        onLongPressCancel: widget.onLongPressCancel != null ? _handleLongPressCancel : null,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            final offset = t * widget.shadowOffset;
            final currentShadow = (1.0 - t).clamp(0.0, 1.0) * widget.shadowOffset;
            final scale = 1.0 - (t * widget.scaleSquash);

            return Transform.translate(
              offset: Offset(offset, offset),
              child: Transform.scale(
                scale: scale,
                child: widget.builder(context, t, currentShadow),
              ),
            );
          },
        ),
      ),
    );
  }
}
