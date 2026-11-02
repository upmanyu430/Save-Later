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
  DateTime? _pointerDownTime;
  bool _isPointerPressed = false;
  bool _handledByPointer = false;
  bool _isLongPressed = false;

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
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap == null) return;
    _isPointerPressed = true;
    _handledByPointer = true;
    _isLongPressed = false;
    _pointerDownPosition = event.position;
    _pointerDownTime = DateTime.now();
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerPressed) return;
    if (_pointerDownPosition != null) {
      final delta = (event.position - _pointerDownPosition!).distance;
      if (delta > 14.0) {
        _isPointerPressed = false;
        _handledByPointer = false;
        _controller.reverse();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isPointerPressed || _isLongPressed) return;
    _isPointerPressed = false;

    final elapsed = DateTime.now().difference(_pointerDownTime ?? DateTime.now());
    final remainingHold = const Duration(milliseconds: 70) - elapsed;

    if (remainingHold > Duration.zero) {
      Future.delayed(remainingHold, () {
        if (!mounted || _isLongPressed) return;
        _controller.reverse().whenComplete(() {
          if (mounted && !_isLongPressed) {
            _handledByPointer = false;
            widget.onTap?.call();
          }
        });
      });
    } else {
      _controller.reverse().whenComplete(() {
        if (mounted && !_isLongPressed) {
          _handledByPointer = false;
          widget.onTap?.call();
        }
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isPointerPressed = false;
    _handledByPointer = false;
    _controller.reverse();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _isLongPressed = true;
    _isPointerPressed = false;
    _controller.stop();
    _controller.value = 0.0; // snap back to idle
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
      onPointerDown: widget.onTap != null ? _onPointerDown : null,
      onPointerMove: widget.onTap != null ? _onPointerMove : null,
      onPointerUp: widget.onTap != null ? _onPointerUp : null,
      onPointerCancel: widget.onTap != null ? _onPointerCancel : null,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap != null
            ? () {
                if (!_handledByPointer && !_isLongPressed) {
                  _controller.forward().whenComplete(() {
                    if (!mounted) return;
                    _controller.reverse().whenComplete(() {
                      if (mounted) {
                        widget.onTap?.call();
                      }
                    });
                  });
                }
              }
            : null,
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
