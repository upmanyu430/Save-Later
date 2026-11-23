import 'package:flutter/material.dart';

/// An animated checkmark icon that smoothly scales and fades in with a snappy
/// overshoot when selected, and scales out cleanly when unselected.
class AnimatedCheckmark extends StatelessWidget {
  final bool isSelected;
  final Color color;
  final double size;

  const AnimatedCheckmark({
    super.key,
    required this.isSelected,
    this.color = const Color(0xFFFDD164),
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 150),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            ),
            child: child,
          ),
        );
      },
      child: isSelected
          ? Icon(
              Icons.check_circle_outline,
              key: const ValueKey('animated_check_icon'),
              color: color,
              size: size,
            )
          : const SizedBox.shrink(key: ValueKey('animated_check_none')),
    );
  }
}
