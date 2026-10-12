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

  Widget _buildFolderBox() {
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
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    final renderBox =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final rect = position & size;

      CollectionRadialMenu.show(
        context: context,
        child: _buildFolderBox(),
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
    CollectionRadialMenu.handleLongPressEnd();
  }

  void _handleLongPressCancel() {
    CollectionRadialMenu.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: _cardKey,
      child: FolderBox(
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
    );
  }
}
