import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../../utils/url_launcher.dart';

class BookmarkDetailScreen extends ConsumerStatefulWidget {
  final Bookmark bookmark;

  const BookmarkDetailScreen({Key? key, required this.bookmark}) : super(key: key);

  @override
  ConsumerState<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  late Bookmark bookmark;

  @override
  void initState() {
    super.initState();
    bookmark = widget.bookmark;
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
                  hintText: 'e.g. Flutter, Recipes, ToRead',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => newTag = val,
                onSubmitted: (val) {
                  _addTag(val);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
              NeoButton(
                onPressed: () {
                  if (newTag.isNotEmpty) {
                    _addTag(newTag);
                    Navigator.pop(ctx);
                  }
                },
                child: const Center(
                  child: Text(
                    'Add',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
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
    setState(() {}); // refresh UI to show new tag
  }

  void _removeTag(String tag) async {
    await ref.read(bookmarkNotifierProvider.notifier).removeTag(bookmark, tag);
    setState(() {}); // refresh UI to hide tag
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.border),
          onPressed: () => context.pop(),
        ),
        title: const Text('Bookmark', style: TextStyle(color: AppTheme.border, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookmark.imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(bookmark.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              bookmark.title ?? bookmark.url,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              bookmark.sourceDomain ?? bookmark.url,
              style: const TextStyle(fontSize: 16, color: AppTheme.border, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (bookmark.description != null) ...[
              Text(
                bookmark.description!,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
            ],
            
            // Tags
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...bookmark.tags.map((tag) => InputChip(
                  label: Text('#$tag'),
                  backgroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border, width: 2),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeTag(tag),
                )),
                ActionChip(
                  label: const Text('+ Add Tag'),
                  backgroundColor: AppTheme.secondary,
                  side: const BorderSide(color: AppTheme.border, width: 2),
                  onPressed: _showAddTagModal,
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: NeoButton(
                    onPressed: () => openUrl(bookmark.url),
                    color: AppTheme.accent,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.open_in_browser),
                        SizedBox(width: 8),
                        Text('Open', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NeoButton(
                    onPressed: () {
                      ref.read(bookmarkNotifierProvider.notifier).markAsRead(bookmark);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as read!'))
                      );
                    },
                    color: AppTheme.primary,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('Mark Read', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NeoButton(
              onPressed: _showMoveModal,
              color: AppTheme.secondary,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drive_file_move),
                  SizedBox(width: 8),
                  Text('Move to Collection', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
