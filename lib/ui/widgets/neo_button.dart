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
    this.padding = const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl, vertical: 14),
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool get _isEnabled => widget.onPressed != null;

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
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
    _controller.forward().whenComplete(() {
      if (!mounted) return;
      _controller.reverse().whenComplete(() {
        if (mounted) {
          widget.onPressed?.call();
        }
      });
    });
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _isEnabled ? _handleTapDown : null,
        onTapUp: _isEnabled ? _handleTapUp : null,
        onTapCancel: _isEnabled ? _handleTapCancel : null,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            final offset = t * widget.shadowOffset;
            final shadowOffset = (1.0 - t).clamp(0.0, 1.0) * widget.shadowOffset;
            final scale = 1.0 - (t * 0.04);

            return Transform.translate(
              offset: Offset(offset, offset),
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
                    boxShadow: [
                      BoxShadow(
                        color: widget.shadowColor ?? AppTheme.border,
                        offset: Offset(shadowOffset, shadowOffset),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
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
    );
  }
}

