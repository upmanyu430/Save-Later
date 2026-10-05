import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/collection.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/bookmark_grid_item.dart';
import '../widgets/collection_editor_modal.dart';
import '../../theme/app_theme.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final int? collectionId;
  final BookmarkCollection? collection;

  const CollectionDetailScreen({
    Key? key,
    required this.collectionId,
    required this.collection,
  }) : super(key: key);

  @override
  ConsumerState<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends ConsumerState<CollectionDetailScreen> {
  bool _isSelectMode = false;
  final Set<int> _selectedIds = {};

  void _showAddLinkModal(BuildContext context) {
    String url = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
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
              const Text(
                'Add Link to Collection',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => url = val,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    ref.read(bookmarkNotifierProvider.notifier).quickSave(val.trim(), collection: widget.collection);
                    Navigator.pop(modalCtx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving link...')));
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
        padding: const EdgeInsets.only(bottom: 24, top: 12),
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
            const SizedBox(height: 24),
            
            // Add Link
            _buildMenuItem(
              icon: Icons.add,
              title: 'Add Link',
              onTap: () {
                Navigator.pop(ctx);
                _showAddLinkModal(context);
              },
            ),
            _buildDivider(),
            
            // Select Links
            _buildMenuItem(
              icon: Icons.check_box_outlined,
              title: 'Select Links',
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
              title: 'Create Sub-collection',
              trailing: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFFFD166), size: 28),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sub-collections are a premium feature!')),
                );
              },
            ),
            _buildDivider(),

            // Share Collection
            _buildMenuItem(
              icon: Icons.share_outlined,
              title: 'Share Collection',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing collection...')),
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppTheme.border),
            const SizedBox(width: 16),
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
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: NeoBox(
          color: color ?? Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderRadius: 8,
          borderWidth: 2.5,
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
  
  void _deleteSelected(List<Bookmark> allBookmarks) {
    if (_selectedIds.isEmpty) return;
    final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
    for (var b in selectedBookmarks) {
      ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(b);
    }
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _moveSelected(List<Bookmark> allBookmarks) async {
     if (_selectedIds.isEmpty) return;
     final collections = await ref.read(collectionsProvider.future);
     
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 3),
            left: BorderSide(color: AppTheme.border, width: 3),
            right: BorderSide(color: AppTheme.border, width: 3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Move to...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final c = collections[index];
                  if (c.id == widget.collectionId) return const SizedBox.shrink();
                  return ListTile(
                    leading: const Icon(Icons.folder, color: AppTheme.border),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      final selectedBookmarks = allBookmarks.where((b) => _selectedIds.contains(b.id)).toList();
                      for (var b in selectedBookmarks) {
                        ref.read(bookmarkNotifierProvider.notifier).moveToCollection(b, c);
                      }
                      Navigator.pop(ctx);
                      setState(() {
                        _isSelectMode = false;
                        _selectedIds.clear();
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = widget.collectionId != null ? ref.watch(collectionBookmarksProvider(widget.collectionId!)) : ref.watch(unsortedBookmarksProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: bookmarksAsync.when(
          data: (bookmarks) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: _isSelectMode
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                '${_selectedIds.length} select...',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(width: 8),
                              _buildSelectButton('All', onTap: () {
                                setState(() {
                                  _selectedIds.addAll(bookmarks.map((b) => b.id));
                                });
                              }),
                              _buildSelectButton('Share', onTap: () => _shareSelected(bookmarks)),
                              _buildSelectButton('Move', onTap: () => _moveSelected(bookmarks)),
                              _buildSelectButton('Delete', color: const Color(0xFFEF476F), textColor: Colors.white, onTap: () => _deleteSelected(bookmarks)),
                              _buildSelectButton('Cancel', onTap: () {
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
                              onTap: () => context.pop(),
                              child: NeoBox(
                                padding: const EdgeInsets.all(8),
                                borderRadius: 8,
                                borderWidth: 2.5,
                                child: const Icon(Icons.arrow_back, size: 28),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  (widget.collection?.name ?? 'Unsorted'),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '${bookmarks.length} ${bookmarks.length == 1 ? 'item' : 'items'}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.push('/review', extra: widget.collection),
                                  child: NeoBox(
                                    color: const Color(0xFFFFD166), // Yellow
                                    padding: const EdgeInsets.all(8),
                                    borderRadius: 8,
                                    borderWidth: 2.5,
                                    child: const Icon(Icons.style, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showMenuModal(context),
                                  child: NeoBox(
                                    padding: const EdgeInsets.all(8),
                                    borderRadius: 8,
                                    borderWidth: 2.5,
                                    child: const Icon(Icons.more_vert, size: 28),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                ),
                
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'SAVES (${bookmarks.length})',
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
                              const Icon(Icons.inbox, size: 80, color: AppTheme.border),
                              const SizedBox(height: 16),
                              const Text(
                                'No items yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
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
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
