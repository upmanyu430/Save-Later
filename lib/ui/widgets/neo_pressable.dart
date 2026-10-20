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
  bool get _isPressable => widget.onTap != null || widget.onLongPressStart != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableFeedback) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.forward().whenComplete(() {
      if (!mounted) return;
      _controller.reverse().whenComplete(() {
        if (mounted) {
          widget.onTap?.call();
        }
      });
    });
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _controller.stop();
    _controller.value = 0.0; // snap back to idle, no animation
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

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap != null ? _handleTapDown : null,
      onTapUp: widget.onTap != null ? _handleTapUp : null,
      onTapCancel: widget.onTap != null ? _handleTapCancel : null,
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
    );
  }
}
