import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';

/// A custom neo-brutalist icon depicting 3 cascading flashcards/review cards
/// angled down and to the right.
class ReviewCardsIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color? backgroundColor;
  final double? strokeWidth;
  final double? cardSize;
  final double? cornerRadius;
  final double? offset;

  const ReviewCardsIcon({
    super.key,
    this.size = AppDimensions.iconSizeLg,
    this.color = AppTheme.border,
    this.backgroundColor,
    this.strokeWidth,
    this.cardSize,
    this.cornerRadius,
    this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / 28.0;
    final effCardSize = cardSize ?? (10.5 * scale);
    final effCornerRadius = cornerRadius ?? (3.0 * scale);
    final effOffset = offset ?? (5.8 * scale);
    final effStrokeWidth = strokeWidth ?? (2.0 * scale);
    final effBgColor = backgroundColor ?? AppTheme.accent;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ReviewCardsPainter(
          color: color,
          backgroundColor: effBgColor,
          strokeWidth: effStrokeWidth,
          cardSize: effCardSize,
          cornerRadius: effCornerRadius,
          offset: effOffset,
        ),
      ),
    );
  }
}

class _ReviewCardsPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double cardSize;
  final double cornerRadius;
  final double offset;

  _ReviewCardsPainter({
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.cardSize,
    required this.cornerRadius,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final totalSpan = cardSize + 2 * offset;
    final startX = cx - totalSpan / 2;
    final startY = cy - totalSpan / 2;

    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX, startY, cardSize, cardSize),
      Radius.circular(cornerRadius),
    );

    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + offset, startY + offset, cardSize, cardSize),
      Radius.circular(cornerRadius),
    );

    final r3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(startX + 2 * offset, startY + 2 * offset, cardSize, cardSize),
      Radius.circular(cornerRadius),
    );

    // Card 1 (back)
    canvas.drawRRect(r1, fillPaint);
    canvas.drawRRect(r1, strokePaint);

    // Card 2 (middle) - fill cleanly covers Card 1's bottom-right
    canvas.drawRRect(r2, fillPaint);
    canvas.drawRRect(r2, strokePaint);

    // Card 3 (front) - fill cleanly covers Card 2's bottom-right
    canvas.drawRRect(r3, fillPaint);
    canvas.drawRRect(r3, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ReviewCardsPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cardSize != cardSize ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.offset != offset;
  }
}
