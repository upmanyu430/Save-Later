import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NeoBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;

  const NeoBox({
    super.key,
    required this.child,
    this.color = AppTheme.cardColor,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
    this.shadowOffset = 6.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.border,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.border,
            offset: Offset(shadowOffset, shadowOffset),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
