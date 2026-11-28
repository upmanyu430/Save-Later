import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Graphic illustrating an empty folder with a calm entrance transition
/// and stable, grounded resting state.
class EmptyFolderGraphic extends StatefulWidget {
  final double width;
  final double height;
  final bool animate;

  const EmptyFolderGraphic({
    super.key,
    this.width = 114.0,
    this.height = 96.0,
    this.animate = true,
  });

  @override
  State<EmptyFolderGraphic> createState() => _EmptyFolderGraphicState();
}

class _EmptyFolderGraphicState extends State<EmptyFolderGraphic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _floatAnimation = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeOutBack,
    );

    if (widget.animate) {
      _floatController.forward();
    } else {
      _floatController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: w,
        height: h,
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, _) {
            final progress = _floatAnimation.value;

            // Calm entrance transition settling to 0.0 at rest
            final floatY = lerpDouble(-8.0, 0.0, progress)!;
            final totalOffsetY = floatY;

            // Subtle tilt settling to 0.0
            final tiltAngle = lerpDouble(-0.015, 0.0, progress)!;

            // Ground shadow settles to grounded resting state
            final shadowScale = lerpDouble(0.85, 1.0, progress)!.clamp(0.0, 1.2);
            final shadowOpacity = lerpDouble(0.50, 0.85, progress)!.clamp(0.0, 1.0);

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Ground shadow (anchored at base)
                Positioned(
                  bottom: h * 0.01,
                  child: Transform.scale(
                    scaleX: shadowScale,
                    scaleY: shadowScale,
                    child: Opacity(
                      opacity: shadowOpacity,
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: CustomPaint(
                          size: Size(w, h),
                          painter: const _FolderShadowPainter(),
                        ),
                      ),
                    ),
                  ),
                ),
                // 2. Folder body + tabs
                Transform.translate(
                  offset: Offset(0, totalOffsetY),
                  child: Transform.rotate(
                    angle: tiltAngle,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: CustomPaint(
                        size: Size(w, h),
                        painter: const _FolderBodyPainter(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Painter for the soft ground shadow.
class _FolderShadowPainter extends CustomPainter {
  const _FolderShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPaint = Paint()
      ..color = const Color(0xFFC7CBD1)
      ..style = PaintingStyle.fill;
    final shadowRect = Rect.fromCenter(
      center: Offset(w * 0.49, h * 0.94),
      width: w * 0.72,
      height: h * 0.09,
    );
    canvas.drawOval(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the folder flaps and body.
class _FolderBodyPainter extends CustomPainter {
  const _FolderBodyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Back flap/tab (middle-right)
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

    // 2. Front tab (left)
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

    // 3. Front folder body
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
    final colors = context.appColors;
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tapOrShareToSave,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
