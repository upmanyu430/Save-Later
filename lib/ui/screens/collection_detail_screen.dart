import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/collection.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../widgets/neo_button.dart';
import '../widgets/bookmark_grid_item.dart';
import '../widgets/collection_grid_item.dart';
import '../widgets/collection_editor_modal.dart';
import '../widgets/review_cards_icon.dart';
import '../widgets/move_to_collection_modal.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_collection_view.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';


class CollectionDetailScreen extends ConsumerStatefulWidget {
  final int? collectionId;
  final BookmarkCollection? collection;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    required this.collection,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  bool _isSelectMode = false;
  final Set<int> _selectedIds = {};

  void _showAddLinkModal(BuildContext context, [BookmarkCollection? currentCollection]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(modalCtx),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16.0,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.border, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.border,
                          offset: Offset(2.8, 2.8),
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.addLinkToCollection,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.linkUrlHint,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              ref.read(bookmarkNotifierProvider.notifier).quickSave(val.trim(), collection: currentCollection ?? widget.collection);
                              Navigator.pop(modalCtx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.savingLink)));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateSubCollectionModal(BuildContext context) {
    if (widget.collectionId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CollectionEditorModal(
        parentId: widget.collectionId,
      ),
    );
  }

  void _showMenuModal(BuildContext context, [BookmarkCollection? currentCollection]) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(ctx),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 5.0,
              right: 5.0,
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 14,
                      bottom: 20 + MediaQuery.paddingOf(ctx).bottom,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(55),
                      border: Border.all(color: AppTheme.border, width: 2.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 48,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        
                        // Add Link
                        _buildMenuItem(
                          icon: Icons.add,
                          title: AppLocalizations.of(context)!.addLink,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAddLinkModal(context, currentCollection);
                          },
                        ),
                        _buildDivider(),
                        
                        // Select Links
                        _buildMenuItem(
                          icon: Icons.check_box_outlined,
                          title: AppLocalizations.of(context)!.selectLinks,
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _isSelectMode = true;
                              _selectedIds.clear();
                            });
                          },
                        ),
                        _buildDivider(),

                        // Create Sub-collection
                        _buildMenuItem(
                          icon: Icons.create_new_folder_outlined,
                          title: AppLocalizations.of(context)!.createSubCollection,
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCreateSubCollectionModal(context);
                          },
                        ),
                        _buildDivider(),

                        // Share Collection
                        _buildMenuItem(
                          icon: Icons.share_outlined,
                          title: AppLocalizations.of(context)!.shareCollection,
                          onTap: () {
                            Navigator.pop(ctx);
                            _shareCollection(currentCollection);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSizeLg, color: AppTheme.border),
            const SizedBox(width: AppDimensions.paddingLg),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.border,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        height: 2,
        color: AppTheme.border,
      ),
    );
  }
  
  Widget _buildSelectButton(String label, {Color? color, Color? textColor, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: NeoButton(
        onPressed: onTap,
        color: color ?? Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        borderRadius: AppDimensions.radiusSm,
        borderWidth: AppDimensions.borderWidthMd,
        shadowOffset: 2.0,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor ?? AppTheme.border)),
      ),
    );
  }

  Future<void> _shareCollection(BookmarkCollection? currentCollection) async {
    final repo = ref.read(repositoryProvider);
    final List<Bookmark> bookmarks;
    final String collectionName;
    if (widget.collectionId != null) {
      collectionName = currentCollection?.name ?? 'Collection';
      bookmarks = await repo.getBookmarksByCollection(widget.collectionId!);
    } else {
      collectionName = AppLocalizations.of(context)!.unsorted;
      bookmarks = await repo.getUnsortedBookmarks();
    }

    if (!mounted) return;

    if (bookmarks.isEmpty) {
      await Share.share('Collection: $collectionName');
    } else {
      final urls = bookmarks.map((b) => b.url).join('\n');
      await Share.share('$collectionName:\n$urls');
    }
  }

  void _shareSelected(List<Bookmark> allBookmarks) {
    if (_selectedIds.isEmpty) return;
    final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
    final urls = selectedBookmarks.map((b) => b.url).join('\n');
    Share.share(urls);
  }
  
  void _deleteSelected(List<Bookmark> allBookmarks) async {
    if (_selectedIds.isEmpty) return;
    final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
    if (selectedBookmarks.isEmpty) return;

    final isSingle = selectedBookmarks.length == 1;
    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      title: isSingle ? 'Delete link' : 'Delete links',
      message: isSingle
          ? 'Permanently delete this link?'
          : 'Permanently delete these ${selectedBookmarks.length} links?',
    );
    if (!confirmed) return;

    final toDelete = List<Bookmark>.from(selectedBookmarks);
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
    await ref.read(bookmarkNotifierProvider.notifier).deleteBookmarks(toDelete, collectionId: widget.collectionId);
  }

  void _moveSelected(List<Bookmark> allBookmarks) async {
    if (_selectedIds.isEmpty) return;
    final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
    if (selectedBookmarks.isEmpty) return;

    MoveToCollectionModal.show(
      context: context,
      bookmarks: selectedBookmarks,
      onMove: (c) async {
        await ref.read(bookmarkNotifierProvider.notifier).moveBookmarksToCollection(selectedBookmarks, c);
        if (mounted) {
          setState(() {
            _isSelectMode = false;
            _selectedIds.clear();
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookmarksAsync = widget.collectionId != null
        ? ref.watch(collectionBookmarksProvider(widget.collectionId!))
        : ref.watch(unsortedBookmarksProvider);
    final subCollectionsAsync = widget.collectionId != null
        ? ref.watch(subCollectionsProvider(widget.collectionId!))
        : const AsyncValue.data(<BookmarkCollection>[]);
    final effectiveCollection = widget.collection ??
        (widget.collectionId != null
            ? ref.watch(singleCollectionProvider(widget.collectionId!)).valueOrNull
            : null);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: bookmarksAsync.when(
          data: (bookmarks) {
            final subCollections = subCollectionsAsync.valueOrNull ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingXl,
                    AppDimensions.paddingLg,
                    AppDimensions.paddingXl,
                    AppDimensions.paddingSm,
                  ),
                  child: _isSelectMode
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                l10n.selectedCount(_selectedIds.length),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: AppDimensions.paddingSm),
                              _buildSelectButton(l10n.selectAll, onTap: () {
                                setState(() {
                                  _selectedIds.addAll(bookmarks.map((b) => b.id));
                                });
                              }),
                              _buildSelectButton(l10n.share, onTap: () => _shareSelected(bookmarks)),
                              _buildSelectButton(l10n.move, onTap: () => _moveSelected(bookmarks)),
                              _buildSelectButton(l10n.delete, color: const Color(0xFFEF476F), textColor: Colors.white, onTap: () => _deleteSelected(bookmarks)),
                              _buildSelectButton(l10n.cancel, onTap: () {
                                setState(() {
                                  _isSelectMode = false;
                                  _selectedIds.clear();
                                });
                              }),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: NeoButton(
                                onPressed: () => context.pop(),
                                padding: EdgeInsets.zero,
                                color: AppTheme.cardColor,
                                borderRadius: AppDimensions.radiusSm,
                                borderWidth: AppDimensions.borderWidthMd,
                                child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeLg),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  widget.collectionId != null
                                      ? (effectiveCollection?.name ?? '...')
                                      : l10n.unsorted,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  widget.collectionId != null
                                      ? '${l10n.itemsCount(bookmarks.length)} · ${l10n.subcollectionsCount(subCollections.length)}'
                                      : l10n.itemsCount(bookmarks.length),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: NeoButton(
                                    onPressed: () => context.push('/review', extra: effectiveCollection),
                                    color: const Color(0xFFFFD166), // Yellow
                                    padding: EdgeInsets.zero,
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: AppDimensions.borderWidthMd,
                                    child: const ReviewCardsIcon(size: AppDimensions.iconSizeLg),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingSm),
                                SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: NeoButton(
                                    onPressed: () => _showMenuModal(context, effectiveCollection),
                                    padding: EdgeInsets.zero,
                                    color: AppTheme.cardColor,
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: AppDimensions.borderWidthMd,
                                    child: const Icon(Icons.more_vert, size: AppDimensions.iconSizeLg),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                ),
                


                // Content Grid
                Expanded(
                  child: LayoutBuilder(
                          builder: (context, constraints) {
                            const horizontalPadding = AppDimensions.paddingXl * 2;
                            const maxCrossAxisExtent = 200.0;
                            const crossAxisSpacing = AppDimensions.gridSpacingMd;
                            const desiredBookmarkCardHeight =
                                AppDimensions.gridBookmarkCardHeight;
                            const desiredFolderCardHeight =
                                AppDimensions.gridFolderCardHeight;
                            final contentWidth = constraints.maxWidth - horizontalPadding;
                            final columnCount = (contentWidth /
                                    (maxCrossAxisExtent + crossAxisSpacing))
                                .ceil()
                                .clamp(1, 10)
                                .toInt();
                            final itemWidth = (contentWidth -
                                    (columnCount - 1) * crossAxisSpacing) /
                                columnCount;
                            final bookmarkAspectRatio = itemWidth / desiredBookmarkCardHeight;
                            final folderAspectRatio = itemWidth / desiredFolderCardHeight;

                            Widget buildGridItem(Bookmark b) {
                              return BookmarkGridItem(
                                bookmark: b,
                                isSelectMode: _isSelectMode,
                                isSelected: _selectedIds.contains(b.id),
                                onSelectTapped: () {
                                  setState(() {
                                    if (_selectedIds.contains(b.id)) {
                                      _selectedIds.remove(b.id);
                                    } else {
                                      _selectedIds.add(b.id);
                                    }
                                  });
                                },
                              );
                            }

                            final pinnedBookmarks = bookmarks.where((b) => b.isPinned).toList();
                            final unpinnedBookmarks = bookmarks.where((b) => !b.isPinned).toList();

                            return CustomScrollView(
                              slivers: [
                                if (subCollections.isNotEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.paddingXl,
                                        vertical: AppDimensions.paddingSm,
                                      ),
                                      child: Text(
                                        '${l10n.subCollections.toUpperCase()} (${subCollections.length})',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppDimensions.paddingXl,
                                      AppDimensions.paddingSm,
                                      AppDimensions.paddingXl,
                                      0,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columnCount,
                                        crossAxisSpacing: crossAxisSpacing,
                                        mainAxisSpacing: AppDimensions.gridSpacingLg,
                                        childAspectRatio: folderAspectRatio,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final subCol = subCollections[index];
                                          return Consumer(
                                            builder: (context, ref, _) {
                                              final countAsync = ref.watch(
                                                  collectionBookmarksProvider(subCol.id));
                                              final count =
                                                  countAsync.valueOrNull?.length ?? 0;
                                              final newCount = countAsync.valueOrNull?.where((b) => !b.isRead).length ?? 0;
                                              final hasNew = newCount > 0;
                                              return CollectionGridItem(
                                                collection: subCol,
                                                itemCount: count,
                                                hasNewItems: hasNew,
                                                newCount: newCount,
                                                onTap: () => context.push(
                                                    '/collection/${subCol.id}',
                                                    extra: subCol),
                                              );
                                            },
                                          );
                                        },
                                        childCount: subCollections.length,
                                      ),
                                    ),
                                  ),
                                ],
                                if (pinnedBookmarks.isNotEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        AppDimensions.paddingXl,
                                        subCollections.isNotEmpty
                                            ? AppDimensions.paddingMd
                                            : AppDimensions.paddingSm,
                                        AppDimensions.paddingXl,
                                        AppDimensions.paddingSm,
                                      ),
                                      child: Text(
                                        'PINNED (${pinnedBookmarks.length})',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppDimensions.paddingXl,
                                      AppDimensions.paddingSm,
                                      AppDimensions.paddingXl,
                                      0,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columnCount,
                                        crossAxisSpacing: crossAxisSpacing,
                                        mainAxisSpacing: AppDimensions.gridSpacingMd,
                                        childAspectRatio: bookmarkAspectRatio,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => buildGridItem(pinnedBookmarks[index]),
                                        childCount: pinnedBookmarks.length,
                                      ),
                                    ),
                                  ),
                                ],
                                if (bookmarks.isEmpty) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        AppDimensions.paddingXl,
                                        (pinnedBookmarks.isNotEmpty || subCollections.isNotEmpty)
                                            ? AppDimensions.paddingMd
                                            : AppDimensions.paddingSm,
                                        AppDimensions.paddingXl,
                                        AppDimensions.paddingSm,
                                      ),
                                      child: Text(
                                        l10n.savesCount(0),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: bottomInset + 32),
                                      child: const Center(
                                        child: EmptyCollectionView(),
                                      ),
                                    ),
                                  ),
                                ] else if (unpinnedBookmarks.isNotEmpty ||
                                    (pinnedBookmarks.isEmpty && bookmarks.isNotEmpty)) ...[
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        AppDimensions.paddingXl,
                                        (pinnedBookmarks.isNotEmpty || subCollections.isNotEmpty)
                                            ? AppDimensions.paddingMd
                                            : AppDimensions.paddingSm,
                                        AppDimensions.paddingXl,
                                        AppDimensions.paddingSm,
                                      ),
                                      child: Text(
                                        l10n.savesCount(
                                          pinnedBookmarks.isNotEmpty
                                              ? unpinnedBookmarks.length
                                              : bookmarks.length,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.fromLTRB(
                                      AppDimensions.paddingXl,
                                      AppDimensions.paddingSm,
                                      AppDimensions.paddingXl,
                                      AppDimensions.paddingLg + bottomInset,
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columnCount,
                                        crossAxisSpacing: crossAxisSpacing,
                                        mainAxisSpacing: AppDimensions.gridSpacingMd,
                                        childAspectRatio: bookmarkAspectRatio,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          final list = pinnedBookmarks.isNotEmpty
                                              ? unpinnedBookmarks
                                              : bookmarks;
                                          return buildGridItem(list[index]);
                                        },
                                        childCount: pinnedBookmarks.isNotEmpty
                                            ? unpinnedBookmarks.length
                                            : bookmarks.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text(l10n.errorWithMessage(e.toString()))),
        ),
      ),
    ),
  ),
);
}
}
