import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../../utils/url_launcher.dart';
import 'delete_confirmation_dialog.dart';
import 'pin_icon.dart';

typedef IconBuilder = Widget Function(Color color, double size);

class BookmarkRadialMenuAction {
  final IconBuilder iconBuilder;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? labelColor;

  BookmarkRadialMenuAction({
    required this.iconBuilder,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.labelColor,
  });
}

// Type alias for backward compatibility with existing tests
typedef RadialMenuAction = BookmarkRadialMenuAction;

class BookmarkRadialMenu {
  static OverlayEntry? _overlayEntry;
  static VoidCallback? _onDismissedCallback;

  static void show({
    required BuildContext context,
    required Widget child,
    required Bookmark bookmark,
    required Rect cardRect,
    required WidgetRef ref,
    VoidCallback? onDismissed,
  }) {
    if (_overlayEntry != null) return;
    _onDismissedCallback = onDismissed;
    final l10n = AppLocalizations.of(context)!;

    final actions = [
      BookmarkRadialMenuAction(
        icon: Icons.open_in_new,
        iconBuilder: (color, size) => CustomPaint(
          size: Size(size, size),
          painter: _ExternalLinkIconPainter(color: color),
        ),
        label: l10n.openUpper,
        color: const Color(0xFF26D5A8),
        labelColor: const Color(0xFF26D5A8),
        onTap: () async {
          await openUrl(bookmark.url, context: context);
        },
      ),
      BookmarkRadialMenuAction(
        icon: Icons.push_pin_outlined,
        iconBuilder: (color, size) => PinIcon(
          isPinned: true,
          size: size,
          color: color,
          strokeWidth: 2.2,
        ),
        label: bookmark.isPinned ? 'UNPIN' : l10n.pinUpper,
        color: const Color(0xFFFFD166),
        labelColor: const Color(0xFFFFD166),
        onTap: () async {
          await ref.read(bookmarkNotifierProvider.notifier).togglePin(bookmark);
        },
      ),
      BookmarkRadialMenuAction(
        icon: Icons.share_outlined,
        iconBuilder: (color, size) => CustomPaint(
          size: Size(size, size),
          painter: _ShareIconPainter(color: color),
        ),
        label: l10n.shareUpper,
        color: const Color(0xFF7B61FF),
        labelColor: const Color(0xFF7B61FF),
        onTap: () {
          Share.share(bookmark.url);
        },
      ),
      BookmarkRadialMenuAction(
        icon: Icons.delete_outline,
        iconBuilder: (color, size) => CustomPaint(
          size: Size(size, size),
          painter: _TrashIconPainter(color: color),
        ),
        label: l10n.deleteUpper,
        color: const Color(0xFFEF476F),
        labelColor: const Color(0xFFEF476F),
        onTap: () async {
          final confirmed =
              await DeleteConfirmationDialog.show(context: context);
          if (!confirmed) return;
          await ref
              .read(bookmarkNotifierProvider.notifier)
              .deleteBookmark(bookmark);
        },
      ),
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => _RadialMenuOverlayWidget(
        cardRect: cardRect,
        actions: actions,
        onClose: dismiss,
        child: child,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss({bool animated = false}) {
    if (animated && _overlayStateKey.currentState != null) {
      _overlayStateKey.currentState!.dismissAnimated();
      return;
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
    final cb = _onDismissedCallback;
    _onDismissedCallback = null;
    cb?.call();
  }

  static void updatePosition(Offset globalPosition) {
    if (_overlayStateKey.currentState != null) {
      _overlayStateKey.currentState!.updateFingerPosition(globalPosition);
    }
  }

  static void handleLongPressEnd() {
    if (_overlayStateKey.currentState != null) {
      final executed = _overlayStateKey.currentState!.executeSelectedIfAny();
      if (executed) {
        dismiss();
      } else {
        dismiss(animated: true);
      }
    } else {
      dismiss();
    }
  }

  static void handleLongPressCancel() {
    dismiss(animated: true);
  }

  static void executeSelectedAndClose() {
    handleLongPressEnd();
  }
}

final GlobalKey<_RadialMenuOverlayWidgetState> _overlayStateKey = GlobalKey();

class _RadialMenuOverlayWidget extends StatefulWidget {
  final Widget child;
  final Rect cardRect;
  final List<BookmarkRadialMenuAction> actions;
  final VoidCallback onClose;

  _RadialMenuOverlayWidget({
    required this.child,
    required this.cardRect,
    required this.actions,
    required this.onClose,
  }) : super(key: _overlayStateKey);

  @override
  State<_RadialMenuOverlayWidget> createState() =>
      _RadialMenuOverlayWidgetState();
}

class _RadialMenuOverlayWidgetState extends State<_RadialMenuOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;
  late Animation<double> _scrimAnim;

  int _selectedIndex = -1;
  bool _isDismissing = false;

  final double buttonRadius = 31.0;
  final List<Offset> _buttonPositions = [];
  late Offset _origin;
  late bool _isRightSide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _scrimAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_buttonPositions.isEmpty) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      _isRightSide = widget.cardRect.center.dx > screenWidth / 2;

      if (_isRightSide) {
        _origin = Offset(widget.cardRect.left + 24, widget.cardRect.top + 24);
        _buttonPositions.addAll([
          // 0: Open - sits along lower-left edge
          Offset(widget.cardRect.left - 24.0, widget.cardRect.top + 120.0),
          // 1: Pin - sits along upper-left edge (75.3dp from Open)
          Offset(widget.cardRect.left - 10.0, widget.cardRect.top + 46.0),
          // 2: Share - sits along upper-left top edge (75.3dp from Pin, gap fixed)
          Offset(widget.cardRect.left + 48.0, widget.cardRect.top - 2.0),
          // 3: Delete - sits along top edge (75.3dp from Share)
          Offset(widget.cardRect.left + 123.0, widget.cardRect.top + 5.0),
        ]);
      } else {
        _origin = Offset(widget.cardRect.right - 24, widget.cardRect.top + 24);
        _buttonPositions.addAll([
          // 0: Open - sits along top edge (75.3dp from Pin)
          Offset(widget.cardRect.right - 123.0, widget.cardRect.top + 5.0),
          // 1: Pin - sits along upper-right top edge (75.3dp from Share, gap fixed)
          Offset(widget.cardRect.right - 48.0, widget.cardRect.top - 2.0),
          // 2: Share - sits along upper-right edge (75.3dp from Delete)
          Offset(widget.cardRect.right + 10.0, widget.cardRect.top + 46.0),
          // 3: Delete - sits along lower-right edge
          Offset(widget.cardRect.right + 24.0, widget.cardRect.top + 120.0),
        ]);
      }
    }
  }

  void updateFingerPosition(Offset pos) {
    int newSelectedIndex = -1;
    double minDistance = double.infinity;
    for (int i = 0; i < _buttonPositions.length; i++) {
      final distance = (_buttonPositions[i] - pos).distance;
      if (distance < buttonRadius * 1.4 && distance < minDistance) {
        minDistance = distance;
        newSelectedIndex = i;
      }
    }

    if (newSelectedIndex != _selectedIndex) {
      if (newSelectedIndex != -1) {
        HapticFeedback.selectionClick();
      }
      setState(() {
        _selectedIndex = newSelectedIndex;
      });
    }
  }

  bool executeSelectedIfAny() {
    if (_selectedIndex != -1) {
      HapticFeedback.lightImpact();
      widget.actions[_selectedIndex].onTap();
      return true;
    }
    return false;
  }

  Future<void> dismissAnimated() async {
    if (_isDismissing) return;
    _isDismissing = true;
    try {
      await _animController.reverse();
    } catch (_) {}
    widget.onClose();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabelFontSize = MediaQuery.textScalerOf(context).scale(
      (MediaQuery.sizeOf(context).width * 0.16).clamp(48.0, 80.0),
    );
    final selectedLabelColor = _selectedIndex == -1
        ? Colors.white
        : widget.actions[_selectedIndex].labelColor ?? Colors.white;

    // Tilt angle matches bookmark long press reference (+2.6 deg for right, -2.6 deg for left)
    final tiltAngle = _isRightSide ? 0.045 : -0.045;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenCenterY = screenHeight / 2;

    // Detect if this bookmark card sits in the middle band of the screen (overlapping center area)
    final isMiddleBookmark = (widget.cardRect.top < screenCenterY + 40 &&
            widget.cardRect.bottom > screenCenterY - 40) ||
        (widget.cardRect.center.dy >= screenHeight * 0.38 &&
            widget.cardRect.center.dy <= screenHeight * 0.62);

    final topBoundary = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final highestBubbleY = _buttonPositions.isNotEmpty
        ? _buttonPositions.map((p) => p.dy).reduce(math.min)
        : widget.cardRect.top;
    final bubblesTop = highestBubbleY - (buttonRadius * 1.3);

    // For middle bookmarks only, position label on the upper side above the card and radial bubbles.
    // For other bookmarks, position label at the center of the screen.
    final targetCenterY = isMiddleBookmark
        ? ((topBoundary + bubblesTop) / 2)
            .clamp(topBoundary + 40.0, screenCenterY - 60.0)
        : screenCenterY;
    final labelAlignmentY =
        ((targetCenterY - screenCenterY) / screenCenterY).clamp(-1.0, 1.0);

    // Render order: unselected buttons first, selected button last so it stays on top
    final renderOrder = List.generate(widget.actions.length, (i) => i);
    if (_selectedIndex != -1) {
      renderOrder.remove(_selectedIndex);
      renderOrder.add(_selectedIndex);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          dismissAnimated();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Background dim
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                dismissAnimated();
              },
              child: AnimatedBuilder(
                animation: _scrimAnim,
                builder: (c, _) => Container(
                  color: Colors.black.withValues(
                    alpha: 0.85 * _scrimAnim.value.clamp(0.0, 1.0),
                  ),
                ),
              ),
            ),

            // Action label (upper side for middle bookmarks, center for others)
            if (_selectedIndex != -1)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.0, labelAlignmentY),
                  child: AnimatedOpacity(
                    opacity: 1.0,
                    duration: AppDurations.animationFast,
                    child: Text(
                      widget.actions[_selectedIndex].label,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: selectedLabelColor,
                        fontSize: selectedLabelFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),

            // Elevated card replica with smooth entrance animation and tilt
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                return Positioned(
                  top: widget.cardRect.top,
                  left: widget.cardRect.left,
                  width: widget.cardRect.width,
                  height: widget.cardRect.height,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      dismissAnimated();
                    },
                    child: Transform.rotate(
                      angle: tiltAngle * _anim.value,
                      child: Transform.scale(
                        scale: 1.0 + (0.045 * _anim.value),
                        child: widget.child,
                      ),
                    ),
                  ),
                );
              },
            ),

            // The 4 circular action bubbles (Open, Pin, Share, Delete)
            ...renderOrder.map((index) {
              final action = widget.actions[index];
              final pos = _buttonPositions[index];
              final isSelected = index == _selectedIndex;

              return AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final currentDx =
                      _origin.dx + (pos.dx - _origin.dx) * _anim.value;
                  final currentDy =
                      _origin.dy + (pos.dy - _origin.dy) * _anim.value;

                  final buttonColor = isSelected ? action.color : Colors.white;
                  final iconColor = isSelected ? Colors.white : Colors.black;

                  return Positioned(
                    left: currentDx - buttonRadius,
                    top: currentDy - buttonRadius,
                    width: buttonRadius * 2,
                    height: buttonRadius * 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        BookmarkRadialMenu.dismiss();
                        action.onTap();
                      },
                      child: Transform.scale(
                        scale: _anim.value,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutBack,
                          scale: isSelected ? 1.15 : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: buttonColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.black, width: 3.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(1.5, 1.5),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Transparent standard Icon for widget test finder compatibility
                                  Opacity(
                                    opacity: 0.0,
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: Icon(action.icon),
                                    ),
                                  ),
                                  action.iconBuilder(iconColor, 26.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Lucide `external-link` icon custom painter
class _ExternalLinkIconPainter extends CustomPainter {
  final Color color;

  const _ExternalLinkIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Box outline: top line, left line, bottom line, partial right line
    final box = Path()
      ..moveTo(11.0, 4.0)
      ..lineTo(6.5, 4.0)
      ..quadraticBezierTo(4.0, 4.0, 4.0, 6.5)
      ..lineTo(4.0, 17.5)
      ..quadraticBezierTo(4.0, 20.0, 6.5, 20.0)
      ..lineTo(17.5, 20.0)
      ..quadraticBezierTo(20.0, 20.0, 20.0, 17.5)
      ..lineTo(20.0, 13.0);
    canvas.drawPath(box, paint);

    // Diagonal arrow line
    canvas.drawLine(const Offset(10.0, 14.0), const Offset(20.0, 4.0), paint);

    // Arrowhead at top-right
    final head = Path()
      ..moveTo(15.0, 4.0)
      ..lineTo(20.0, 4.0)
      ..lineTo(20.0, 9.0);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant _ExternalLinkIconPainter oldDelegate) =>
      oldDelegate.color != color;
}


/// Lucide `share-2` icon custom painter
class _ShareIconPainter extends CustomPainter {
  final Color color;

  const _ShareIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    // Two connecting lines from node perimeter to node perimeter
    canvas.drawLine(
        const Offset(8.6, 10.5), const Offset(15.4, 6.5), linePaint);
    canvas.drawLine(
        const Offset(8.6, 13.5), const Offset(15.4, 17.5), linePaint);

    // 3 hollow outline circles
    canvas.drawCircle(const Offset(18.0, 5.0), 3.0, circlePaint);
    canvas.drawCircle(const Offset(6.0, 12.0), 3.0, circlePaint);
    canvas.drawCircle(const Offset(18.0, 19.0), 3.0, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _ShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Lucide `trash-2` icon custom painter
class _TrashIconPainter extends CustomPainter {
  final Color color;

  const _TrashIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Horizontal top lid line
    canvas.drawLine(const Offset(3.0, 6.0), const Offset(21.0, 6.0), paint);

    // Top handle above lid
    final handle = Path()
      ..moveTo(8.5, 6.0)
      ..lineTo(8.5, 3.5)
      ..quadraticBezierTo(8.5, 2.0, 10.0, 2.0)
      ..lineTo(14.0, 2.0)
      ..quadraticBezierTo(15.5, 2.0, 15.5, 3.5)
      ..lineTo(15.5, 6.0);
    canvas.drawPath(handle, paint);

    // Rounded bucket body
    final bucket = Path()
      ..moveTo(5.5, 6.0)
      ..lineTo(6.5, 19.5)
      ..quadraticBezierTo(6.8, 22.0, 9.0, 22.0)
      ..lineTo(15.0, 22.0)
      ..quadraticBezierTo(17.2, 22.0, 17.5, 19.5)
      ..lineTo(18.5, 6.0);
    canvas.drawPath(bucket, paint);

    // Two vertical lines inside bucket
    canvas.drawLine(const Offset(10.0, 10.5), const Offset(10.0, 17.5), paint);
    canvas.drawLine(const Offset(14.0, 10.5), const Offset(14.0, 17.5), paint);
  }

  @override
  bool shouldRepaint(covariant _TrashIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
