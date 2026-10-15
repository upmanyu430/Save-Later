import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import 'collection_radial_menu.dart';
import 'folder_box.dart';

class CollectionGridItem extends ConsumerStatefulWidget {
  final BookmarkCollection collection;
  final int itemCount;
  final bool hasNewItems;
  final VoidCallback onTap;

  const CollectionGridItem({
    super.key,
    required this.collection,
    required this.itemCount,
    required this.hasNewItems,
    required this.onTap,
  });

  @override
  ConsumerState<CollectionGridItem> createState() => _CollectionGridItemState();
}

class _CollectionGridItemState extends ConsumerState<CollectionGridItem> {
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _cardBodyKey = GlobalKey();
  bool _isMenuOpen = false;

  Widget _buildFolderBox({bool showTab = true, bool isInteractive = true}) {
    final l10n = AppLocalizations.of(context)!;
    return FolderBox(
      forceBold: true,
      title: widget.collection.name,
      itemCountText: l10n.itemsCount(widget.itemCount),
      folderColor: widget.collection.color,
      icon: IconData(
        widget.collection.iconCodePoint,
        fontFamily: widget.collection.iconFontFamily,
      ),
      onTap: widget.onTap,
      hasNewItems: widget.hasNewItems,
      showTab: showTab,
      isInteractive: isInteractive,
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    final bodyBox =
        _cardBodyKey.currentContext?.findRenderObject() as RenderBox?;
    final cardBox =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;

    Rect? rect;
    if (bodyBox != null) {
      final size = bodyBox.size;
      final position = bodyBox.localToGlobal(Offset.zero);
      rect = position & size;
    } else if (cardBox != null) {
      final size = cardBox.size;
      final position = cardBox.localToGlobal(Offset.zero);
      rect = Rect.fromLTWH(
        position.dx,
        position.dy + 15.0,
        size.width,
        (size.height - 15.0).clamp(1.0, double.infinity),
      );
    }

    if (rect != null) {
      setState(() => _isMenuOpen = true);

      CollectionRadialMenu.show(
        context: context,
        child: _buildFolderBox(showTab: false, isInteractive: false),
        collection: widget.collection,
        cardRect: rect,
        ref: ref,
      );

      CollectionRadialMenu.updatePosition(details.globalPosition);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    CollectionRadialMenu.updatePosition(details.globalPosition);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    setState(() => _isMenuOpen = false);
    CollectionRadialMenu.handleLongPressEnd();
  }

  void _handleLongPressCancel() {
    setState(() => _isMenuOpen = false);
    CollectionRadialMenu.handleLongPressCancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Opacity(
      opacity: _isMenuOpen ? 0.0 : 1.0,
      child: Container(
        key: _cardKey,
        child: FolderBox(
          bodyKey: _cardBodyKey,
          forceBold: true,
          title: widget.collection.name,
          itemCountText: l10n.itemsCount(widget.itemCount),
          folderColor: widget.collection.color,
          icon: IconData(
            widget.collection.iconCodePoint,
            fontFamily: widget.collection.iconFontFamily,
          ),
          onTap: widget.onTap,
          hasNewItems: widget.hasNewItems,
          onLongPressStart: _handleLongPressStart,
          onLongPressMoveUpdate: _handleLongPressMoveUpdate,
          onLongPressEnd: _handleLongPressEnd,
          onLongPressCancel: _handleLongPressCancel,
        ),
      ),
    );
  }
}
