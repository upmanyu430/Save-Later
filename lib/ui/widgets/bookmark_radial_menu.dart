import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark.dart';
import 'dart:math';
import '../../utils/url_launcher.dart';
import '../../providers/providers.dart';
import 'package:save_later/config/app_constants.dart';


class RadialMenuAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  RadialMenuAction({required this.icon, required this.label, required this.onTap});
}

class BookmarkRadialMenu {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required Widget child,
    required Bookmark bookmark,
    required Rect cardRect,
    required WidgetRef ref,
  }) {
    if (_overlayEntry != null) return;
    final l10n = AppLocalizations.of(context)!;
    
    final actions = [
      RadialMenuAction(
        icon: Icons.open_in_new, 
        label: l10n.openUpper, 
        onTap: () {
          openUrl(bookmark.url);
        }
      ),
      RadialMenuAction(
        icon: Icons.push_pin_outlined, 
        label: l10n.pinUpper, 
        onTap: () async {
          bookmark.isPinned = !bookmark.isPinned;
          await ref.read(repositoryProvider).updateBookmark(bookmark);
          ref.invalidate(bookmarksProvider);
          if (bookmark.collection.value != null) {
            ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
          }
          ref.invalidate(unsortedBookmarksProvider);
        }
      ),
      RadialMenuAction(
        icon: Icons.share_outlined, 
        label: l10n.shareUpper, 
        onTap: () {
          Share.share(bookmark.url);
        }
      ),
      RadialMenuAction(
        icon: Icons.delete_outline, 
        label: l10n.deleteUpper, 
        onTap: () async {
          await ref.read(repositoryProvider).deleteBookmark(bookmark.id);
          ref.invalidate(bookmarksProvider);
          if (bookmark.collection.value != null) {
            ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
          }
          ref.invalidate(unsortedBookmarksProvider);
        }
      ),
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => _RadialMenuOverlayWidget(
        cardRect: cardRect,
        actions: actions,
        onClose: _removeOverlay,
        child: child,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  static void updatePosition(Offset globalPosition) {
    if (_overlayStateKey.currentState != null) {
      _overlayStateKey.currentState!.updateFingerPosition(globalPosition);
    }
  }
  
  static void executeSelectedAndClose() {
    if (_overlayStateKey.currentState != null) {
      _overlayStateKey.currentState!.executeSelected();
    }
    _removeOverlay();
  }
}

final GlobalKey<_RadialMenuOverlayWidgetState> _overlayStateKey = GlobalKey();

class _RadialMenuOverlayWidget extends StatefulWidget {
  final Widget child;
  final Rect cardRect;
  final List<RadialMenuAction> actions;
  final VoidCallback onClose;

  _RadialMenuOverlayWidget({
    required this.child,
    required this.cardRect,
    required this.actions,
    required this.onClose,
  }) : super(key: _overlayStateKey);

  @override
  State<_RadialMenuOverlayWidget> createState() => _RadialMenuOverlayWidgetState();
}

class _RadialMenuOverlayWidgetState extends State<_RadialMenuOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;
  
  int _selectedIndex = -1;

  final double buttonRadius = 34.0; // Slightly larger for easier touch
  final double arcRadius = 65.0;
  
  final List<Offset> _buttonPositions = [];
  late Offset _origin;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: AppDurations.animationNormal);
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_buttonPositions.isEmpty) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isRightSide = widget.cardRect.center.dx > screenWidth / 2;
      
      _origin = isRightSide 
          ? Offset(widget.cardRect.left + 20, widget.cardRect.top + 20)
          : Offset(widget.cardRect.right - 20, widget.cardRect.top + 20);
          
      final angles = isRightSide 
          ? [
              -pi * 0.2,
              -pi * 0.55,
              -pi * 0.9,
              -pi * 1.25
            ]
          : [
              -pi * 0.8,
              -pi * 0.45,
              -pi * 0.1,
              pi * 0.25
            ];
            
      for (int i = 0; i < widget.actions.length; i++) {
        _buttonPositions.add(Offset(
          _origin.dx + arcRadius * cos(angles[i]),
          _origin.dy + arcRadius * sin(angles[i]),
        ));
      }
    }
  }

  void updateFingerPosition(Offset pos) {
    int newSelectedIndex = -1;
    for (int i = 0; i < _buttonPositions.length; i++) {
      if ((_buttonPositions[i] - pos).distance < buttonRadius * 1.5) { // generous hit area
        newSelectedIndex = i;
        break;
      }
    }
    
    if (newSelectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newSelectedIndex;
      });
    }
  }

  void executeSelected() {
    if (_selectedIndex != -1) {
      widget.actions[_selectedIndex].onTap();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background dim
          GestureDetector(
            onTap: widget.onClose,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (c, _) => Container(
                color: Colors.black.withValues(alpha: 0.85 * _anim.value),
              ),
            ),
          ),
          
          // The selected label
          if (_selectedIndex != -1)
            Positioned.fill(
              child: Center(
                child: AnimatedOpacity(
                  opacity: 1.0,
                  duration: AppDurations.animationFast,
                  child: Text(
                    widget.actions[_selectedIndex].label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
            
          // The card replica
          AnimatedBuilder(
            animation: _anim,
            builder: (c, child) {
              return Positioned(
                top: widget.cardRect.top,
                left: widget.cardRect.left,
                width: widget.cardRect.width,
                height: widget.cardRect.height,
                child: Transform.rotate(
                  angle: -0.05 * _anim.value,
                  child: Transform.scale(
                    scale: 1.0 + (0.05 * _anim.value),
                    child: widget.child,
                  ),
                ),
              );
            }
          ),
          
          // The radial buttons
          ...List.generate(widget.actions.length, (index) {
            final action = widget.actions[index];
            final pos = _buttonPositions[index];
            final isSelected = index == _selectedIndex;
            
            return AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final currentDx = _origin.dx + (pos.dx - _origin.dx) * _anim.value;
                final currentDy = _origin.dy + (pos.dy - _origin.dy) * _anim.value;
                
                final scale = _anim.value * (isSelected ? 1.3 : 1.0);
                
                return Positioned(
                  left: currentDx - buttonRadius,
                  top: currentDy - buttonRadius,
                  width: buttonRadius * 2,
                  height: buttonRadius * 2,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD166) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        action.icon, 
                        color: Colors.black, 
                        size: 32.0,
                        weight: 700,
                      ),
                    ),
                  ),
                );
              }
            );
          }),
        ],
      ),
    );
  }
}
