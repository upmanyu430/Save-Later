import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';
import 'app_modal_sheet.dart';
import 'collection_editor_modal.dart';
import 'moved_success_dialog.dart';
import 'neo_button.dart';
import 'stored_icon.dart';

class MoveToCollectionModal extends ConsumerStatefulWidget {
  final Bookmark? bookmark;
  final List<Bookmark>? bookmarks;
  final BookmarkCollection? initialCollection;
  final Future<void> Function(BookmarkCollection? collection)? onMove;

  const MoveToCollectionModal({
    super.key,
    this.bookmark,
    this.bookmarks,
    this.initialCollection,
    this.onMove,
  });

  static Future<bool?> show({
    required BuildContext context,
    Bookmark? bookmark,
    List<Bookmark>? bookmarks,
    BookmarkCollection? initialCollection,
    Future<void> Function(BookmarkCollection? collection)? onMove,
  }) async {
    final moved = await showAppModalSheet<bool>(
      context: context,
      builder: (ctx) => MoveToCollectionModal(
        bookmark: bookmark,
        bookmarks: bookmarks,
        initialCollection: initialCollection,
        onMove: onMove,
      ),
    );

    if (moved == true && context.mounted) {
      await MovedSuccessDialog.show(context: context);
    }

    return moved;
  }

  static String formatTargetLabel(String prefix, String name) {
    if (name.length <= 22) {
      return '$prefix "$name"';
    }
    final truncated = '${name.substring(0, 10)}...${name.substring(name.length - 8)}';
    return '$prefix "$truncated"';
  }

  @override
  ConsumerState<MoveToCollectionModal> createState() => _MoveToCollectionModalState();
}

class _MoveToCollectionModalState extends ConsumerState<MoveToCollectionModal> {
  late final ScrollController _scrollController;
  BookmarkCollection? _selectedCollection;

  BoxDecoration _optionDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? const Color(0xFFFFF4D0) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected ? const Color(0xFFFDD164) : Colors.transparent,
        width: 1.5,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _selectedCollection = widget.initialCollection;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    dismissAppModalSheet(context, true);
  }

  void _openCreateCollection() async {
    await showAppModalSheet<void>(
      context: context,
      unfocusBeforeOpen: false,
      builder: (ctx) => const CollectionEditorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(allCollectionsProvider);
    // Exact height matching the Add New Collection modal (CollectionEditorModal):
    final targetModalHeight =
        CollectionEditorModal.getCollapsedModalHeight(context);

    return AppModalKeyboardLift(
      maxHeight: targetModalHeight,
      freezeWhenCovered: true,
      child: SizedBox(
        key: const ValueKey('move_to_collection_modal_sheet'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(55),
            border: Border.all(color: AppTheme.border, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 6),
                              // Header Row: Title & Action Button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.modalFolderOptionHorizontalMargin,
                                ),
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
                                      width: AppDimensions.dialogHeaderButtonSize,
                                      height: AppDimensions.dialogHeaderButtonSize,
                                      child: NeoButton(
                                        onPressed: _openCreateCollection,
                                        padding: EdgeInsets.zero,
                                        color: Colors.white,
                                        borderRadius: AppDimensions.radiusMd,
                                        borderWidth: AppDimensions.borderWidthMd,
                                        child: const Icon(
                                          Icons.create_new_folder_outlined,
                                          size: AppDimensions.dialogHeaderIconSize,
                                          color: AppTheme.border,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Collections List
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: collectionsAsync.when(
                                data: (collections) {
                                  if (collections.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 24.0),
                                      child: Center(
                                        child: Text(
                                          'No collections yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final selected = _selectedCollection;

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: collections.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (ctx, index) {
                                      final col = collections[index];
                                      final isSelected = selected?.id == col.id;

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
                                          });
                                        },
                                        child: Tooltip(
                                          message: col.name,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: AppDimensions.modalFolderOptionHorizontalMargin),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: AppDimensions.modalFolderOptionVerticalPadding),
                                            decoration: _optionDecoration(isSelected),
                                            child: Row(
                                              children: [
                                                // Collection Icon Box
                                                Container(
                                                  width: AppDimensions.modalFolderOptionIconBoxSize,
                                                  height: AppDimensions.modalFolderOptionIconBoxSize,
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
                                                    size: AppDimensions.modalFolderOptionIconSize,
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
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 11,
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
                                              ],
                                            ),
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
                            ],
                          ),
                        ),
                      ),

                      // Bottom Move Action Button
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          18.0 + AppDimensions.modalFolderOptionHorizontalMargin,
                          0.0,
                          18.0 + AppDimensions.modalFolderOptionHorizontalMargin,
                          AppDimensions.modalActionButtonBottomPadding +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 18),
                            Builder(
                              builder: (context) {
                                final isEnabled = _selectedCollection != null;
                                final buttonLabel = _selectedCollection != null
                                    ? MoveToCollectionModal.formatTargetLabel('Move to', _selectedCollection!.name)
                                    : 'Move to Collection';

                                return SizedBox(
                                  height: 50.0,
                                  width: double.infinity,
                                  child: NeoButton(
                                    onPressed: isEnabled
                                        ? () => _handleMove(_selectedCollection)
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
    );
  }
}
