import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Graphic illustrating an empty folder with tabs and drop shadow.
class EmptyFolderGraphic extends StatelessWidget {
  final double width;
  final double height;

  const EmptyFolderGraphic({
    super.key,
    this.width = 114.0,
    this.height = 96.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        size: Size(width, height),
        painter: const _EmptyFolderPainter(),
      ),
    );
  }
}

class _EmptyFolderPainter extends CustomPainter {
  const _EmptyFolderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft ground shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFFC7CBD1).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final shadowRect = Rect.fromCenter(
      center: Offset(w * 0.49, h * 0.94),
      width: w * 0.72,
      height: h * 0.09,
    );
    canvas.drawOval(shadowRect, shadowPaint);

    // Common stroke paint
    final strokePaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 2. Back flap/tab (middle-right)
    final backTabRect = Rect.fromLTRB(w * 0.23, h * 0.08, w * 0.68, h * 0.36);
    final backTabRRect = RRect.fromRectAndCorners(
      backTabRect,
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    final backTabFillPaint = Paint()
      ..color = const Color(0xFFBDBDBD)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(backTabRRect, backTabFillPaint);
    canvas.drawRRect(backTabRRect, strokePaint);

    // 3. Front tab (left)
    final frontTabRect = Rect.fromLTRB(w * 0.03, h * 0.14, w * 0.46, h * 0.36);
    final frontTabRRect = RRect.fromRectAndCorners(
      frontTabRect,
      topLeft: const Radius.circular(8),
      topRight: const Radius.circular(8),
    );
    final frontTabFillPaint = Paint()
      ..color = const Color(0xFFE4E4E4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(frontTabRRect, frontTabFillPaint);
    canvas.drawRRect(frontTabRRect, strokePaint);

    // 4. Front folder body
    final bodyRect = Rect.fromLTWH(0, h * 0.23, w, h * 0.68);
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      const Radius.circular(16),
    );
    final bodyFillPaint = Paint()
      ..color = const Color(0xFFE4E4E4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRRect, bodyFillPaint);
    canvas.drawRRect(bodyRRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Empty state view shown when a collection folder has no items.
class EmptyCollectionView extends StatelessWidget {
  const EmptyCollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const EmptyFolderGraphic(
          width: 114,
          height: 96,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.noItemsYet,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.border,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tapOrShareToSave,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
