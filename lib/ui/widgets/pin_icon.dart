import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';

/// A custom neo-brutalist pin / unpin icon matching the Lucide pin and pin-off
/// vector specifications with pixel-perfect stroke and cap geometry.
class PinIcon extends StatelessWidget {
  final bool isPinned;
  final double size;
  final Color color;
  final double strokeWidth;

  const PinIcon({
    super.key,
    this.isPinned = true,
    this.size = AppDimensions.iconSizeMd,
    this.color = AppTheme.border,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PinIconPainter(
          isPinned: isPinned,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _PinIconPainter extends CustomPainter {
  final bool isPinned;
  final Color color;
  final double strokeWidth;

  const _PinIconPainter({
    required this.isPinned,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (isPinned) {
      // 1. Needle: M12 17v5
      path.moveTo(12, 17);
      path.lineTo(12, 22);

      // 2. Pin body:
      // M9 10.76
      path.moveTo(9, 10.76);
      // a2 2 0 0 1-1.11 1.79
      path.arcToPoint(
        const Offset(7.89, 12.55),
        radius: const Radius.circular(2),
        clockwise: true,
      );
      // l-1.78 .9
      path.lineTo(6.11, 13.45);
      // A2 2 0 0 0 5 15.24
      path.arcToPoint(
        const Offset(5, 15.24),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      // V16
      path.lineTo(5, 16);
      // a1 1 0 0 0 1 1
      path.arcToPoint(
        const Offset(6, 17),
        radius: const Radius.circular(1),
        clockwise: false,
      );
      // h12
      path.lineTo(18, 17);
      // a1 1 0 0 0 1-1
      path.arcToPoint(
        const Offset(19, 16),
        radius: const Radius.circular(1),
        clockwise: false,
      );
      // v-.76
      path.lineTo(19, 15.24);
      // a2 2 0 0 0-1.11-1.79
      path.arcToPoint(
        const Offset(17.89, 13.45),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      // l-1.78-.9
      path.lineTo(16.11, 12.55);
      // A2 2 0 0 1 15 10.76
      path.arcToPoint(
        const Offset(15, 10.76),
        radius: const Radius.circular(2),
        clockwise: true,
      );
      // V7
      path.lineTo(15, 7);
      // a1 1 0 0 1 1-1
      path.arcToPoint(
        const Offset(16, 6),
        radius: const Radius.circular(1),
        clockwise: true,
      );
      // a2 2 0 0 0 0-4
      path.arcToPoint(
        const Offset(16, 2),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      // H8
      path.lineTo(8, 2);
      // a2 2 0 0 0 0 4
      path.arcToPoint(
        const Offset(8, 6),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      // a1 1 0 0 1 1 1
      path.arcToPoint(
        const Offset(9, 7),
        radius: const Radius.circular(1),
        clockwise: true,
      );
      // z
      path.close();
    } else {
      // 1. Needle: M12 17v5
      path.moveTo(12, 17);
      path.lineTo(12, 22);

      // 2. Top-right section: M15 9.34V7a1 1 0 0 1 1-1 2 2 0 0 0 0-4H7.89
      path.moveTo(15, 9.34);
      path.lineTo(15, 7);
      path.arcToPoint(
        const Offset(16, 6),
        radius: const Radius.circular(1),
        clockwise: true,
      );
      path.arcToPoint(
        const Offset(16, 2),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      path.lineTo(7.89, 2);

      // 3. Diagonal slash line: m2 2 20 20
      path.moveTo(2, 2);
      path.lineTo(22, 22);

      // 4. Bottom-left section: M9 9v1.76a2 2 0 0 1-1.11 1.79l-1.78.9A2 2 0 0 0 5 15.24V16a1 1 0 0 0 1 1h11
      path.moveTo(9, 9);
      path.lineTo(9, 10.76);
      path.arcToPoint(
        const Offset(7.89, 12.55),
        radius: const Radius.circular(2),
        clockwise: true,
      );
      path.lineTo(6.11, 13.45);
      path.arcToPoint(
        const Offset(5, 15.24),
        radius: const Radius.circular(2),
        clockwise: false,
      );
      path.lineTo(5, 16);
      path.arcToPoint(
        const Offset(6, 17),
        radius: const Radius.circular(1),
        clockwise: false,
      );
      path.lineTo(17, 17);
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PinIconPainter oldDelegate) {
    return oldDelegate.isPinned != isPinned ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
