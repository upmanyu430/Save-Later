import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';
import 'collection_editor_modal.dart';
import 'moved_success_dialog.dart';
import 'neo_box.dart';
import 'neo_button.dart';

class MoveToCollectionModal extends ConsumerStatefulWidget {
  final Bookmark? bookmark;
  final List<Bookmark>? bookmarks;
  final BookmarkCollection? initialCollection;
  final Future<void> Function(BookmarkCollection collection)? onMove;

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
    Future<void> Function(BookmarkCollection collection)? onMove,
  }) async {
    final moved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  @override
  ConsumerState<MoveToCollectionModal> createState() => _MoveToCollectionModalState();
}

class _MoveToCollectionModalState extends ConsumerState<MoveToCollectionModal> {
  BookmarkCollection? _selectedCollection;

  @override
  void initState() {
    super.initState();
    _selectedCollection = widget.initialCollection;
  }

  Future<void> _handleMove(BookmarkCollection collection) async {
    HapticFeedback.mediumImpact();

    if (widget.onMove != null) {
      await widget.onMove!(collection);
    } else if (widget.bookmark != null) {
      final b = widget.bookmark!;
      final previousCollectionId = b.collection.value?.id;
      b.collection.value = collection;
      await ref.read(repositoryProvider).updateBookmark(b);
      b.collection.save();
      ref.invalidate(bookmarksProvider);
      ref.invalidate(collectionBookmarksProvider(collection.id));
      if (previousCollectionId != null && previousCollectionId != collection.id) {
        ref.invalidate(collectionBookmarksProvider(previousCollectionId));
      }
    } else if (widget.bookmarks != null && widget.bookmarks!.isNotEmpty) {
      for (final b in widget.bookmarks!) {
        final previousCollectionId = b.collection.value?.id;
        b.collection.value = collection;
        await ref.read(repositoryProvider).updateBookmark(b);
        b.collection.save();
        if (previousCollectionId != null && previousCollectionId != collection.id) {
          ref.invalidate(collectionBookmarksProvider(previousCollectionId));
        }
      }
      ref.invalidate(bookmarksProvider);
      ref.invalidate(collectionBookmarksProvider(collection.id));
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _openCreateCollection() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CollectionEditorModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.border, width: 2.5),
          left: BorderSide(color: AppTheme.border, width: 2.5),
          right: BorderSide(color: AppTheme.border, width: 2.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Grab Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header Row: Title & Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Move to Collection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.border,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openCreateCollection,
                    child: NeoBox(
                      padding: const EdgeInsets.all(AppDimensions.paddingSm),
                      borderRadius: AppDimensions.radiusSm,
                      borderWidth: AppDimensions.borderWidthMd,
                      child: const Icon(
                        Icons.create_new_folder_outlined,
                        size: AppDimensions.iconSizeLg,
                        color: AppTheme.border,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collections List
              collectionsAsync.when(
                data: (collections) {
                  if (collections.isEmpty) {
                    return Padding(
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
                          GestureDetector(
                            onTap: _openCreateCollection,
                            child: NeoBox(
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
                          ),
                        ],
                      ),
                    );
                  }

                  final selected = _selectedCollection;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.40,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: collections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final col = collections[index];
                        final isSelected = selected?.id == col.id;

                        final iconColor =
                            ThemeData.estimateBrightnessForColor(col.color) == Brightness.dark
                                ? Colors.white
                                : AppTheme.border;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCollection = col;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFF9E6)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFFFFD166), width: 1.5)
                                  : Border.all(color: Colors.transparent, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                // Collection Icon Box
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: col.color,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.border,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Icon(
                                    IconData(col.iconCodePoint, fontFamily: col.iconFontFamily),
                                    color: iconColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    col.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.border,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              // Thin Divider
              Container(
                height: 1,
                color: Colors.black.withValues(alpha: 0.08),
                margin: const EdgeInsets.symmetric(vertical: 14),
              ),

              // Bottom Move Action Button
              if (_selectedCollection != null)
                NeoButton(
                  onPressed: () => _handleMove(_selectedCollection!),
                  color: const Color(0xFFFFD166),
                  borderWidth: 2.5,
                  borderRadius: 12.0,
                  shadowOffset: 2.5,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Move to "${_selectedCollection!.name}"',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.border,
                    ),
                  ),
                )
              else
                Opacity(
                  opacity: 0.5,
                  child: NeoBox(
                    color: const Color(0xFFFFD166),
                    borderWidth: 2.5,
                    borderRadius: 12.0,
                    shadowOffset: 2.5,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Center(
                      child: Text(
                        'Move to Collection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.border,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
