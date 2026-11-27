import 'package:flutter/material.dart';
import 'package:save_later/config/app_constants.dart';
import '../../theme/app_theme.dart';

class NeoBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final double borderWidth;
  final double borderRadius;
  final double shadowOffset;
  final EdgeInsetsGeometry padding;

  const NeoBox({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.borderWidth = 3.0,
    this.borderRadius = 16.0,
    this.shadowOffset = 2.0,
    this.padding = const EdgeInsets.all(AppDimensions.paddingLg),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedColor = color ?? colors.card;
    final resolvedBorder = borderColor ?? colors.border;
    final resolvedShadow = shadowColor ?? colors.shadow;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: resolvedBorder,
          width: borderWidth,
        ),
        boxShadow: shadowOffset <= 0
            ? null
            : [
                BoxShadow(
                  color: resolvedShadow,
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
