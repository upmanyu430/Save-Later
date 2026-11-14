import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';
import 'collection_editor_modal.dart';
import 'moved_success_dialog.dart';
import 'neo_button.dart';
import 'stored_icon.dart';

class MoveToCollectionModal extends ConsumerStatefulWidget {
  final Bookmark? bookmark;
  final List<Bookmark>? bookmarks;
  final BookmarkCollection? initialCollection;
  final bool initialUnsorted;
  final Future<void> Function(BookmarkCollection? collection)? onMove;

  const MoveToCollectionModal({
    super.key,
    this.bookmark,
    this.bookmarks,
    this.initialCollection,
    this.initialUnsorted = false,
    this.onMove,
  });

  static Future<bool?> show({
    required BuildContext context,
    Bookmark? bookmark,
    List<Bookmark>? bookmarks,
    BookmarkCollection? initialCollection,
    bool initialUnsorted = false,
    Future<void> Function(BookmarkCollection? collection)? onMove,
  }) async {
    final moved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MoveToCollectionModal(
        bookmark: bookmark,
        bookmarks: bookmarks,
        initialCollection: initialCollection,
        initialUnsorted: initialUnsorted,
        onMove: onMove,
      ),
    );

    if (moved == true && context.mounted) {
      await MovedSuccessDialog.show(context: context);
    }

    return moved;
  }

  @override
  ConsumerState<MoveToCollectionModal> createState() => _MoveToCollectionModalState();
}

class _MoveToCollectionModalState extends ConsumerState<MoveToCollectionModal> {
  BookmarkCollection? _selectedCollection;
  bool _isUnsortedSelected = false;

  @override
  void initState() {
    super.initState();
    _selectedCollection = widget.initialCollection;
    _isUnsortedSelected = widget.initialUnsorted && widget.initialCollection == null;
  }

  Future<void> _handleMove(BookmarkCollection? collection) async {
    if (widget.onMove != null) {
      await widget.onMove!(collection);
    } else if (widget.bookmark != null) {
      await ref.read(bookmarkNotifierProvider.notifier).moveToCollection(widget.bookmark!, collection);
    } else if (widget.bookmarks != null && widget.bookmarks!.isNotEmpty) {
      await ref.read(bookmarkNotifierProvider.notifier).moveBookmarksToCollection(widget.bookmarks!, collection);
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _openCreateCollection() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CollectionEditorModal(),
    );
  }

  Widget _buildUnsortedTile(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _isUnsortedSelected;

    return GestureDetector(
      key: const ValueKey('collection_unsorted'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isUnsortedSelected = true;
          _selectedCollection = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFF4D0)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.border
                : Colors.black.withValues(alpha: 0.08),
            width: 2.0,
          ),
        ),
        child: Row(
          children: [
            // Unsorted Icon Box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.border,
                  width: 1.8,
                ),
              ),
              child: const Icon(
                Icons.folder_off_outlined,
                color: AppTheme.border,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.unsorted ?? 'Unsorted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.border,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.border,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final view = View.of(context);
    final windowPadding = MediaQueryData.fromView(view).padding;
    final statusBarHeight = windowPadding.top > 0
        ? windowPadding.top
        : MediaQuery.paddingOf(context).top;
    final topClearance = statusBarHeight + 16.0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Exact height matching the Add New Collection modal (CollectionEditorModal):
    final targetModalHeight =
        CollectionEditorModal.getCollapsedModalHeight(context);
    final availableHeight = screenHeight - topClearance - bottomInset;
    final sheetHeight = math.min(availableHeight, targetModalHeight);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 5.0,
          right: 5.0,
          top: topClearance,
          bottom: bottomInset,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: sheetHeight,
            ),
            child: SizedBox(
              key: const ValueKey('move_to_collection_modal_sheet'),
              height: sheetHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(55),
                    border: Border.all(color: AppTheme.border, width: 2.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Grab Handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // Header Row: Title & Action Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Move to Collection',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.border,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingSm),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: NeoButton(
                                onPressed: _openCreateCollection,
                                padding: EdgeInsets.zero,
                                color: Colors.white,
                                borderRadius: AppDimensions.radiusMd,
                                borderWidth: AppDimensions.borderWidthMd,
                                child: const Icon(
                                  Icons.create_new_folder_outlined,
                                  size: AppDimensions.iconSizeMd,
                                  color: AppTheme.border,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Collections List
                      Expanded(
                        child: collectionsAsync.when(
                          data: (collections) {
                            if (collections.isEmpty) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildUnsortedTile(context),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'No collections yet',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          NeoButton(
                                            onPressed: _openCreateCollection,
                                            color: AppTheme.accent,
                                            borderWidth: 2,
                                            borderRadius: 12,
                                            shadowOffset: 2,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            child: const Text(
                                              'Create New Collection',
                                              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.border),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final selected = _selectedCollection;

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0),
                              physics: const ClampingScrollPhysics(),
                              itemCount: collections.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, index) {
                                if (index == 0) {
                                  return _buildUnsortedTile(context);
                                }

                                final col = collections[index - 1];
                                final isSelected = !_isUnsortedSelected && selected?.id == col.id;

                                final iconColor =
                                    BookmarkCollection.isWhiteIconColor(col.color)
                                        ? Colors.white
                                        : AppTheme.border;

                                return GestureDetector(
                                  key: ValueKey('collection_${col.id}'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedCollection = col;
                                      _isUnsortedSelected = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFFF4D0)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.border
                                            : Colors.black.withValues(alpha: 0.08),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Collection Icon Box
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: col.color,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppTheme.border,
                                              width: 1.8,
                                            ),
                                          ),
                                          child: Icon(
                                            storedIcon(
                                              col.iconCodePoint,
                                              col.iconFontFamily,
                                            ),
                                            color: iconColor,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                col.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.border,
                                                ),
                                              ),
                                              if (col.parentId != null) ...[
                                                Builder(
                                                  builder: (context) {
                                                    final parent = collections
                                                        .where((c) => c.id == col.parentId)
                                                        .firstOrNull;
                                                    if (parent == null) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    return Text(
                                                      'in ${parent.name}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.black.withValues(alpha: 0.5),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.border,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Move Action Button
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18.0,
                          0.0,
                          18.0,
                          30.0 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.08),
                              margin: const EdgeInsets.only(top: 6, bottom: 12),
                            ),
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                final isEnabled = _isUnsortedSelected || _selectedCollection != null;
                                final String buttonLabel;
                                if (_isUnsortedSelected) {
                                  buttonLabel = 'Move to "${l10n?.unsorted ?? 'Unsorted'}"';
                                } else if (_selectedCollection != null) {
                                  buttonLabel = 'Move to "${_selectedCollection!.name}"';
                                } else {
                                  buttonLabel = 'Move to Collection';
                                }

                                return SizedBox(
                                  height: 48.0,
                                  width: double.infinity,
                                  child: NeoButton(
                                    onPressed: isEnabled
                                        ? () => _handleMove(_isUnsortedSelected ? null : _selectedCollection)
                                        : null,
                                    color: const Color(0xFFFFD166),
                                    padding: EdgeInsets.zero,
                                    borderRadius: AppDimensions.radiusMd,
                                    shadowOffset: 2.0,
                                    child: Center(
                                      child: Text(
                                        buttonLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.border,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
