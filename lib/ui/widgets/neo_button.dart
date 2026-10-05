import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeoButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;

  const NeoButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.color = AppTheme.primary,
    this.borderWidth = 3.0,
    this.borderRadius = 12.0,
    this.shadowOffset = 5.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  }) : super(key: key);

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Transform.translate(
        offset: Offset(
          _isPressed ? widget.shadowOffset : 0,
          _isPressed ? widget.shadowOffset : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
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
          child: widget.child,
        ),
      ),
    );
  }
}
