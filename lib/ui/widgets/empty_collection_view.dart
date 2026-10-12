import 'dart:io' show Platform;
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Graphic illustrating an empty folder with smooth floating animation,
/// breathing ground shadow, and interactive spring bounce on tap.
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
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  bool _isTestEnvironment() {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _floatAnimation = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutSine,
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    if (widget.animate && !_isTestEnvironment()) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _bounceController.forward(from: 0.0);
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
          animation: Listenable.merge([_floatAnimation, _bounceAnimation]),
          builder: (context, _) {
            final floatProgress = _floatAnimation.value;
            final bounceProgress = _bounceAnimation.value;

            // Vertical translation: subtle float + spring bounce hop
            final floatY = lerpDouble(0.0, -6.0, floatProgress)!;
            final bounceHopY = bounceProgress > 0.0 && bounceProgress < 1.0
                ? (1.0 - bounceProgress) * -10.0
                : 0.0;
            final totalOffsetY = floatY + bounceHopY;

            // Tilt rotation: slight playful sway
            final tiltAngle = lerpDouble(-0.015, 0.015, floatProgress)!;

            // Ground shadow breathing: shrinks and softens as folder rises
            final heightRatio = ((-totalOffsetY) / 16.0).clamp(0.0, 1.0);
            final shadowScale = lerpDouble(1.0, 0.78, heightRatio)!;
            final shadowOpacity = lerpDouble(0.85, 0.40, heightRatio)!;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Breathing ground shadow (anchored at base)
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
                // 2. Levitating folder body + tabs
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
