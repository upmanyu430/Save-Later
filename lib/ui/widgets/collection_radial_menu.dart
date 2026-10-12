import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/collection.dart';
import '../../providers/providers.dart';
import 'collection_editor_modal.dart';
import 'delete_confirmation_dialog.dart';

class CollectionRadialMenuAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? labelColor;

  CollectionRadialMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.labelColor,
  });
}

class CollectionRadialMenu {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required Widget child,
    required BookmarkCollection collection,
    required Rect cardRect,
    required WidgetRef ref,
  }) {
    if (_overlayEntry != null) return;
    final l10n = AppLocalizations.of(context)!;

    final actions = [
      CollectionRadialMenuAction(
        icon: Icons.edit,
        label: l10n.editUpper,
        color: const Color(0xFFFFD166),
        labelColor: const Color(0xFFFFD166),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (ctx) =>
                CollectionEditorModal(existingCollection: collection),
          );
        },
      ),
      CollectionRadialMenuAction(
        icon: Icons.share,
        label: l10n.shareUpper,
        color: const Color(0xFF7B61FF),
        labelColor: const Color(0xFF7B61FF),
        onTap: () async {
          final bookmarks = await ref
              .read(repositoryProvider)
              .getBookmarksByCollection(collection.id);
          if (bookmarks.isEmpty) {
            Share.share('Collection: ${collection.name}');
          } else {
            final urls = bookmarks.map((b) => b.url).join('\n');
            Share.share('${collection.name}:\n$urls');
          }
        },
      ),
      CollectionRadialMenuAction(
        icon: Icons.delete_outline,
        label: l10n.deleteUpper,
        color: const Color(0xFFEF476F),
        labelColor: const Color(0xFFEF476F),
        onTap: () async {
          final confirmed = await DeleteConfirmationDialog.show(
            context: context,
            title: l10n.deleteCollection,
            message: l10n.deleteCollectionMessage(collection.name),
          );
          if (!confirmed) return;
          await ref
              .read(collectionNotifierProvider.notifier)
              .deleteCollection(collection);
        },
      ),
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => _CollectionRadialMenuOverlayWidget(
        cardRect: cardRect,
        actions: actions,
        onClose: dismiss,
        child: child,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      }
    }
  }
}

final GlobalKey<_CollectionRadialMenuOverlayWidgetState> _overlayStateKey =
    GlobalKey();

class _CollectionRadialMenuOverlayWidget extends StatefulWidget {
  final Widget child;
  final Rect cardRect;
  final List<CollectionRadialMenuAction> actions;
  final VoidCallback onClose;

  _CollectionRadialMenuOverlayWidget({
    required this.child,
    required this.cardRect,
    required this.actions,
    required this.onClose,
  }) : super(key: _overlayStateKey);

  @override
  State<_CollectionRadialMenuOverlayWidget> createState() =>
      _CollectionRadialMenuOverlayWidgetState();
}

class _CollectionRadialMenuOverlayWidgetState
    extends State<_CollectionRadialMenuOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  int _selectedIndex = -1;

  final double buttonRadius = 32.0;
  final List<Offset> _buttonPositions = [];
  late Offset _origin;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_buttonPositions.isEmpty) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final isRightSide = widget.cardRect.center.dx > screenWidth / 2;

      if (isRightSide) {
        _origin = Offset(widget.cardRect.left + 24, widget.cardRect.top + 24);
        _buttonPositions.addAll([
          Offset(widget.cardRect.left - 18, widget.cardRect.top + 28), // Edit
          Offset(widget.cardRect.left + 30, widget.cardRect.top - 38), // Share
          Offset(widget.cardRect.left + 92, widget.cardRect.top - 34), // Delete
        ]);
      } else {
        _origin = Offset(widget.cardRect.right - 24, widget.cardRect.top + 24);
        _buttonPositions.addAll([
          Offset(widget.cardRect.right - 92, widget.cardRect.top - 34), // Edit
          Offset(widget.cardRect.right - 30, widget.cardRect.top - 38), // Share
          Offset(widget.cardRect.right + 18, widget.cardRect.top + 28), // Delete
        ]);
      }
    }
  }

  void updateFingerPosition(Offset pos) {
    int newSelectedIndex = -1;
    for (int i = 0; i < _buttonPositions.length; i++) {
      if ((_buttonPositions[i] - pos).distance < buttonRadius * 1.5) {
        newSelectedIndex = i;
        break;
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

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background dim
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: AnimatedBuilder(
              animation: _anim,
              builder: (c, _) => Container(
                color: Colors.black.withValues(alpha: 0.85 * _anim.value),
              ),
            ),
          ),

          // Action label in center of screen
          if (_selectedIndex != -1)
            Positioned.fill(
              child: Center(
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

          // Elevated & tilted card replica
          AnimatedBuilder(
            animation: _anim,
            builder: (c, child) {
              return Positioned(
                top: widget.cardRect.top,
                left: widget.cardRect.left,
                width: widget.cardRect.width,
                height: widget.cardRect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onClose();
                  },
                  child: Transform.rotate(
                    angle: -0.05 * _anim.value,
                    child: Transform.scale(
                      scale: 1.0 + (0.05 * _anim.value),
                      child: widget.child,
                    ),
                  ),
                ),
              );
            },
          ),

          // The 3 circular action bubbles
          ...List.generate(widget.actions.length, (index) {
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

                final scale = _anim.value * (isSelected ? 1.25 : 1.0);
                final buttonColor = isSelected ? action.color : Colors.white;
                final iconColor = buttonColor.computeLuminance() < 0.5
                    ? Colors.white
                    : Colors.black;

                return Positioned(
                  left: currentDx - buttonRadius,
                  top: currentDy - buttonRadius,
                  width: buttonRadius * 2,
                  height: buttonRadius * 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onClose();
                      action.onTap();
                    },
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          color: buttonColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          action.icon,
                          color: iconColor,
                          size: 30.0,
                          weight: 700,
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
    );
  }
}
