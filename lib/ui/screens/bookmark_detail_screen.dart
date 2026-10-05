import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../../utils/url_launcher.dart';

class BookmarkDetailScreen extends ConsumerStatefulWidget {
  final Bookmark bookmark;

  const BookmarkDetailScreen({Key? key, required this.bookmark}) : super(key: key);

  @override
  ConsumerState<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  late Bookmark bookmark;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _notesController = TextEditingController(text: bookmark.description ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showAddTagModal() {
    String newTag = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                'Add Tag',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'tag_name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => newTag = val,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _addTag(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag(String tag) async {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    await ref.read(bookmarkNotifierProvider.notifier).addTag(bookmark, cleanTag);
    setState(() {});
  }

  void _removeTag(String tag) async {
    await ref.read(bookmarkNotifierProvider.notifier).removeTag(bookmark, tag);
    setState(() {});
  }

  void _showMoveModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, child) {
          final collectionsAsync = ref.watch(collectionsProvider);
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.border, width: 3)),
            ),
            padding: const EdgeInsets.all(24),
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) return const Text('No collections created yet.');
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (ctx, index) {
                    final col = collections[index];
                    return ListTile(
                      leading: Icon(IconData(col.iconCodePoint, fontFamily: col.iconFontFamily), color: col.color),
                      title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () async {
                        bookmark.collection.value = col;
                        await ref.read(repositoryProvider).updateBookmark(bookmark);
                        bookmark.collection.save();
                        ref.invalidate(bookmarksProvider);
                        ref.invalidate(collectionBookmarksProvider(col.id));
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Moved to ${col.name}')));
                      },
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            )
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Matches image overflow areas
      body: Stack(
        children: [
          // 1. Background Image
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: bookmark.imageUrl != null
                ? Image.network(
                    bookmark.imageUrl!.startsWith('//') ? 'https:' + bookmark.imageUrl! : bookmark.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(
                      color: Colors.grey.shade900,
                      child: const Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey)),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.link, size: 64, color: Colors.grey)),
                  ),
          ),

          // 2. Main Content Card
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border(
                        top: BorderSide(color: AppTheme.border, width: 3),
                        left: BorderSide(color: AppTheme.border, width: 3),
                        right: BorderSide(color: AppTheme.border, width: 3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source Domain
                        Row(
                          children: [
                            const Icon(Icons.public, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              bookmark.sourceDomain ?? 'Unknown Source',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Edit Button
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                bookmark.title ?? bookmark.url,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            NeoBox(
                              padding: const EdgeInsets.all(8),
                              borderRadius: 12,
                              borderWidth: 2.5,
                              child: const Icon(Icons.edit_outlined, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Collection & Date
                        Row(
                          children: [
                            if (bookmark.collection.value != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: NeoBox(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  borderRadius: 8,
                                  borderWidth: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        IconData(bookmark.collection.value!.iconCodePoint, fontFamily: bookmark.collection.value!.iconFontFamily),
                                        size: 16,
                                        color: bookmark.collection.value!.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        bookmark.collection.value!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Text(
                              DateFormat('dd MMM yyyy, h:mm a').format(bookmark.createdAt),
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Open Link Button
                        GestureDetector(
                          onTap: () => openUrl(bookmark.url),
                          child: NeoBox(
                            color: const Color(0xFFFFD166), // Yellow
                            padding: const EdgeInsets.all(16),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Open link',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        bookmark.sourceDomain ?? bookmark.url,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.border,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_outward, color: Colors.white, size: 24),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Actions Row
                        NeoBox(
                          padding: const EdgeInsets.all(0),
                          borderRadius: 16,
                          child: Row(
                            children: [
                              _buildActionItem(Icons.share_outlined, 'Share', () {}),
                              _buildDivider(),
                              _buildActionItem(Icons.folder_outlined, 'Move', _showMoveModal),
                              _buildDivider(),
                              _buildActionItem(Icons.refresh, 'Refresh', _showRefreshDialog),
                              _buildDivider(),
                              _buildActionItem(Icons.delete_outline, 'Delete', () async {
                                await ref.read(repositoryProvider).deleteBookmark(bookmark.id);
                                ref.invalidate(bookmarksProvider);
                                if (bookmark.collection.value != null) ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
                                context.pop();
                              }, isDestructive: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Description
                        const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Text(
                          bookmark.description ?? 'No description provided.',
                          style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 32),

                        // Tags
                        const Text('TAGS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ...bookmark.tags.map((tag) => GestureDetector(
                              onTap: () => _removeTag(tag), // Or edit
                              child: NeoBox(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: 8,
                                borderWidth: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔖', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )),
                            GestureDetector(
                              onTap: _showAddTagModal,
                              child: NeoBox(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: 8,
                                borderWidth: 2,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('👑', style: TextStyle(fontSize: 12)),
                                    SizedBox(width: 6),
                                    Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Notes
                        const Text('NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        NeoBox(
                          color: const Color(0xFFFFF7E0), // Pale yellow
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: TextField(
                            controller: _notesController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Tap to add notes...',
                              hintStyle: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Top Floating App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: NeoBox(
                        padding: const EdgeInsets.all(8),
                        color: AppTheme.background,
                        borderRadius: 12,
                        borderWidth: 2.5,
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                    ),
                    NeoBox(
                      padding: const EdgeInsets.all(8),
                      color: AppTheme.background,
                      borderRadius: 12,
                      borderWidth: 2.5,
                      child: const Icon(Icons.auto_fix_off_outlined, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefreshDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.border,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Refresh link metadata?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Refresh updates the link preview (title, image, description). Your notes, pin state, and collection will remain unchanged.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border, width: 2.5),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshing...')),
                          );
                          await ref.read(bookmarkNotifierProvider.notifier).refreshMetadata(bookmark);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Refreshed!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3366),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.border,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFC0392B) : AppTheme.border;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.transparent,
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 2,
      color: AppTheme.border,
    );
  }
}



