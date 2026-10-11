import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/collection.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/bookmark_grid_item.dart';
import '../widgets/review_cards_icon.dart';
import '../widgets/move_to_collection_modal.dart';
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

  void _showAddLinkModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalCtx).viewInsets.bottom +
              MediaQuery.paddingOf(modalCtx).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.border, width: 3)),
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
                    ref.read(bookmarkNotifierProvider.notifier).quickSave(val.trim(), collection: widget.collection);
                    Navigator.pop(modalCtx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.savingLink)));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 12,
          bottom: 24 + MediaQuery.paddingOf(ctx).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 3),
            left: BorderSide(color: AppTheme.border, width: 3),
            right: BorderSide(color: AppTheme.border, width: 3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXl),
            
            // Add Link
            _buildMenuItem(
              icon: Icons.add,
              title: AppLocalizations.of(context)!.addLink,
              onTap: () {
                Navigator.pop(ctx);
                _showAddLinkModal(context);
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
              trailing: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFFFD166), size: AppDimensions.iconSizeLg),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.subCollectionsPremiumFeature)),
                );
              },
            ),
            _buildDivider(),

            // Share Collection
            _buildMenuItem(
              icon: Icons.share_outlined,
              title: AppLocalizations.of(context)!.shareCollection,
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.sharingCollection)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        height: 2,
        color: AppTheme.border,
      ),
    );
  }
  
  Widget _buildSelectButton(String label, {Color? color, Color? textColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap == null ? null : () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: NeoBox(
          color: color ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: AppDimensions.radiusSm,
          borderWidth: AppDimensions.borderWidthMd,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor ?? AppTheme.border)),
        ),
      ),
    );
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
    final toDelete = List<Bookmark>.from(selectedBookmarks);
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
    for (var b in toDelete) {
      await ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(b, collectionId: widget.collectionId);
    }
  }

  void _moveSelected(List<Bookmark> allBookmarks) async {
    if (_selectedIds.isEmpty) return;
    final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
    if (selectedBookmarks.isEmpty) return;

    MoveToCollectionModal.show(
      context: context,
      bookmarks: selectedBookmarks,
      onMove: (c) async {
        for (final b in selectedBookmarks) {
          await ref.read(bookmarkNotifierProvider.notifier).moveToCollection(b, c);
        }
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
    final bookmarksAsync = widget.collectionId != null ? ref.watch(collectionBookmarksProvider(widget.collectionId!)) : ref.watch(unsortedBookmarksProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: bookmarksAsync.when(
          data: (bookmarks) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLg),
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
                            GestureDetector(
                              onTap: () { HapticFeedback.lightImpact(); context.pop(); },
                              child: NeoBox(
                                padding: const EdgeInsets.all(AppDimensions.paddingSm),
                                borderRadius: AppDimensions.radiusSm,
                                borderWidth: AppDimensions.borderWidthMd,
                                child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeLg),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  (widget.collection?.name ?? l10n.unsorted),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  l10n.itemsCount(bookmarks.length),
                                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); context.push('/review', extra: widget.collection); },
                                  child: NeoBox(
                                    color: const Color(0xFFFFD166), // Yellow
                                    padding: const EdgeInsets.all(AppDimensions.paddingSm),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: AppDimensions.borderWidthMd,
                                    child: const ReviewCardsIcon(size: AppDimensions.iconSizeLg),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.paddingSm),
                                GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); _showMenuModal(context); },
                                  child: NeoBox(
                                    padding: const EdgeInsets.all(AppDimensions.paddingSm),
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
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl, vertical: AppDimensions.paddingSm),
                  child: Text(
                    l10n.savesCount(bookmarks.length),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),

                // Content Grid
                Expanded(
                  child: bookmarks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inbox, size: AppDimensions.iconSizeXxl, color: AppTheme.border),
                              const SizedBox(height: AppDimensions.paddingLg),
                              Text(
                                l10n.noItemsYet,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            const horizontalPadding = AppDimensions.paddingXl * 2;
                            const maxCrossAxisExtent = 200.0;
                            const crossAxisSpacing = AppDimensions.gridSpacingMd;
                            const desiredCardHeight = 180.0;
                            final contentWidth = constraints.maxWidth - horizontalPadding;
                            final columnCount = (contentWidth /
                                    (maxCrossAxisExtent + crossAxisSpacing))
                                .ceil()
                                .clamp(1, 10)
                                .toInt();
                            final itemWidth = (contentWidth -
                                    (columnCount - 1) * crossAxisSpacing) /
                                columnCount;

                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                AppDimensions.paddingXl,
                                AppDimensions.paddingLg,
                                AppDimensions.paddingXl,
                                AppDimensions.paddingLg + bottomInset,
                              ),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxCrossAxisExtent,
                                crossAxisSpacing: crossAxisSpacing,
                                mainAxisSpacing: AppDimensions.gridSpacingMd,
                                childAspectRatio: itemWidth / desiredCardHeight,
                              ),
                              itemCount: bookmarks.length,
                              itemBuilder: (context, index) {
                              final b = bookmarks[index];
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
                              },
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
    );
  }
}
