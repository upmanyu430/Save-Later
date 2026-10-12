import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';


class NeoButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;

  const NeoButton({
    super.key,
    this.onPressed,
    required this.child,
    this.color = AppTheme.primary,
    this.borderWidth = 3.0,
    this.borderRadius = 12.0,
    this.shadowOffset = 2.0,
    this.padding = const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl, vertical: 14),
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;
  bool get _isEnabled => widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isEnabled) return;
    setState(() {
      _isPressed = false;
    });
    widget.onPressed!();
  }

  void _handleTapCancel() {
    if (!_isEnabled) return;
    setState(() {
      _isPressed = false;
    });
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
      child: AnimatedContainer(
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset : 0,
          _isPressed ? widget.shadowOffset : 0,
          0,
        ),
        duration: _isPressed
            ? const Duration(milliseconds: 50)
            : const Duration(milliseconds: 400),
        curve: _isPressed ? Curves.easeOut : Curves.elasticOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: AppTheme.border,
            width: widget.borderWidth,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.border,
                    offset: Offset(widget.shadowOffset, widget.shadowOffset),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    ),
  );
}
}

