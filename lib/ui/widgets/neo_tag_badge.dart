import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class NeoTagBadge extends StatefulWidget {
  final String name;
  final int count;
  final Color? color;
  final Color? textColor;
  final double tilt;
  final VoidCallback? onTap;
  final double height;
  final double shadowOffset;
  final double borderWidth;
  final bool isSelected;

  const NeoTagBadge({
    super.key,
    required this.name,
    required this.count,
    this.color,
    this.textColor,
    this.tilt = 0.0,
    this.onTap,
    this.height = 44.0,
    this.shadowOffset = 3.0,
    this.borderWidth = 2.5,
    this.isSelected = false,
  });

  /// Map of canonical tag names from the design mockup to their exact colors.
  static const Map<String, Color> namedColors = {
    'recipes': Color(0xFFFF7E33), // Warm orange
    'travel': Color(0xFF4B92E2), // Royal blue
    'design': Color(0xFF6366F1), // Indigo / purple-blue
    'japan': Color(0xFFFA5A68), // Coral / salmon red
    'reading list': Color(0xFFEBDFAF), // Warm beige / tan
    'readinglist': Color(0xFFEBDFAF),
    'interior': Color(0xFFA37AF2), // Purple / lilac
    'workout': Color(0xFF57A046), // Leaf green
    'coffee': Color(0xFF9E6B47), // Caramel brown
    'gift ideas': Color(0xFFC772D8), // Orchid pink
    'giftideas': Color(0xFFC772D8),
    'weeknight': Color(0xFFF5C61E), // Dandelion yellow
    'typography': Color(0xFF1E232A), // Slate black
    'beach': Color(0xFF14B8A6), // Turquoise / teal
    'podcast': Color(0xFFB2D33D), // Lime green
    'music': Color(0xFF708CA8), // Steel blue
    'diy': Color(0xFFE8437D), // Berry magenta
  };

  /// Vibrantly saturated neo-brutalist color palette for general tags.
  static const List<Color> palette = [
    Color(0xFFFF7E33), // Orange
    Color(0xFF4B92E2), // Royal Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFFFA5A68), // Salmon
    Color(0xFFEBDFAF), // Tan
    Color(0xFFA37AF2), // Purple
    Color(0xFF57A046), // Green
    Color(0xFF9E6B47), // Brown
    Color(0xFFC772D8), // Orchid
    Color(0xFFF5C61E), // Yellow
    Color(0xFF1E232A), // Slate Black
    Color(0xFF14B8A6), // Teal
    Color(0xFFB2D33D), // Lime
    Color(0xFF708CA8), // Steel Blue
    Color(0xFFE8437D), // Magenta
  ];

  /// Resolves a background color for [name], using named colors if known,
  /// or a deterministic hash into the palette.
  static Color getColor(String name, [int? index]) {
    final lower = name.trim().toLowerCase();
    if (namedColors.containsKey(lower)) {
      return namedColors[lower]!;
    }
    if (index != null && index >= 0 && index < palette.length) {
      return palette[index % palette.length];
    }
    int hash = 0;
    for (int i = 0; i < lower.length; i++) {
      hash = (hash * 31 + lower.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  /// Calculates high-contrast text color based on background luminance.
  static Color getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() < 0.35
        ? Colors.white
        : AppTheme.border;
  }

  /// Natural playful alternating tilt angles in radians.
  static const List<double> defaultTilts = [
    -0.035, // ~ -2.0 deg
    0.060,  // ~ +3.5 deg
    -0.070, // ~ -4.0 deg
    0.065,  // ~ +3.7 deg
    -0.040, // ~ -2.3 deg
    0.055,  // ~ +3.1 deg
    -0.050, // ~ -2.9 deg
    0.050,  // ~ +2.9 deg
    -0.050, // ~ -2.9 deg
    0.060,  // ~ +3.4 deg
    -0.045, // ~ -2.6 deg
    0.050,  // ~ +2.9 deg
    -0.045, // ~ -2.6 deg
    0.040,  // ~ +2.3 deg
    -0.040, // ~ -2.3 deg
  ];

  static double getTilt(int index) {
    return defaultTilts[index % defaultTilts.length];
  }

  /// Default sample tags from design mockup when library has no tags yet.
  static const List<MapEntry<String, int>> sampleTags = [
    MapEntry('recipes', 11),
    MapEntry('travel', 9),
    MapEntry('design', 8),
    MapEntry('japan', 7),
    MapEntry('reading list', 6),
    MapEntry('interior', 6),
    MapEntry('workout', 5),
    MapEntry('coffee', 4),
    MapEntry('gift ideas', 4),
    MapEntry('weeknight', 4),
    MapEntry('typography', 4),
    MapEntry('beach', 3),
    MapEntry('podcast', 3),
    MapEntry('music', 2),
    MapEntry('diy', 2),
  ];

  @override
  State<NeoTagBadge> createState() => _NeoTagBadgeState();
}

class _NeoTagBadgeState extends State<NeoTagBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _animation = CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    _pressController.forward().whenComplete(() {
      if (!mounted) return;
      _pressController.reverse().whenComplete(() {
        if (mounted) {
          widget.onTap?.call();
        }
      });
    });
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? NeoTagBadge.getColor(widget.name);
    final fgColor = widget.textColor ?? NeoTagBadge.getTextColor(bgColor);
    const noseWidth = 22.0;

    return Transform.rotate(
      angle: widget.tilt,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final t = _animation.value;
            final baseBorderWidth = widget.isSelected ? 3.5 : widget.borderWidth;
            final baseShadow = widget.isSelected ? 4.5 : widget.shadowOffset;
            final currentShadowOffset = (1.0 - t).clamp(0.0, 1.0) * baseShadow;
            final pressTranslate = t * baseShadow;

            return Transform.translate(
              offset: Offset(pressTranslate, pressTranslate),
              child: CustomPaint(
                painter: NeoTagPainter(
                  color: bgColor,
                  borderColor: AppTheme.border,
                  shadowColor: AppTheme.border,
                  borderWidth: baseBorderWidth,
                  shadowOffset: currentShadowOffset,
                  noseWidth: noseWidth,
                  cornerRadius: 11.0,
                  tipRadius: 3.5,
                ),
                child: Container(
                  height: widget.height,
                  padding: const EdgeInsets.fromLTRB(
                    noseWidth + 6.0,
                    4.0,
                    8.0,
                    4.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.isSelected) ...[
                        Icon(
                          Icons.check,
                          size: 16,
                          color: fgColor,
                        ),
                        const SizedBox(width: 4.0),
                      ],
                      Text(
                        '#${widget.name}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: fgColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.border,
                            width: 2.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${widget.count}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.border,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NeoTagPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double shadowOffset;
  final double noseWidth;
  final double cornerRadius;
  final double tipRadius;

  NeoTagPainter({
    required this.color,
    this.borderColor = AppTheme.border,
    this.shadowColor = AppTheme.border,
    this.borderWidth = 2.5,
    this.shadowOffset = 3.0,
    this.noseWidth = 22.0,
    this.cornerRadius = 11.0,
    this.tipRadius = 3.5,
  });

  Path _createTagPath(Size size, [Offset offset = Offset.zero]) {
    final path = Path();
    final ox = offset.dx;
    final oy = offset.dy;
    final w = size.width + ox;
    final h = size.height + oy;
    final midY = oy + (size.height / 2.0);
    final actualNose = (noseWidth).clamp(12.0, size.height * 0.55);
    final actualRadius = (cornerRadius).clamp(4.0, size.height / 2.0);

    // Start at top-left chamfer junction
    path.moveTo(ox + actualNose, oy);

    // Top edge
    path.lineTo(w - actualRadius, oy);

    // Top-right rounded corner
    path.arcToPoint(
      Offset(w, oy + actualRadius),
      radius: Radius.circular(actualRadius),
    );

    // Right edge
    path.lineTo(w, h - actualRadius);

    // Bottom-right rounded corner
    path.arcToPoint(
      Offset(w - actualRadius, h),
      radius: Radius.circular(actualRadius),
    );

    // Bottom edge
    path.lineTo(ox + actualNose, h);

    // Bottom-left angled edge to tip
    path.lineTo(ox + tipRadius * 0.8, midY + tipRadius * 1.2);

    // Left tip arc
    path.arcToPoint(
      Offset(ox + tipRadius * 0.8, midY - tipRadius * 1.2),
      radius: Radius.circular(tipRadius),
    );

    // Top-left angled edge back to start
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw solid black drop shadow
    if (shadowOffset > 0) {
      final shadowPath = _createTagPath(
        size,
        Offset(shadowOffset, shadowOffset),
      );
      final shadowPaint = Paint()
        ..color = shadowColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // 2. Draw tag body fill
    final tagPath = _createTagPath(size);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(tagPath, fillPaint);

    // 3. Draw tag border stroke
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tagPath, borderPaint);

    // 4. Draw eyelet (grommet hole)
    final midY = size.height / 2.0;
    final actualNose = (noseWidth).clamp(12.0, size.height * 0.55);
    final eyeletCenterX = actualNose * 0.55;
    const eyeletRadius = 4.5;

    // Eyelet white fill
    final eyeletFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(eyeletCenterX, midY),
      eyeletRadius,
      eyeletFillPaint,
    );

    // Eyelet black stroke
    final eyeletStrokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(eyeletCenterX, midY),
      eyeletRadius,
      eyeletStrokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant NeoTagPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.shadowOffset != shadowOffset ||
        oldDelegate.borderWidth != borderWidth;
  }
}
