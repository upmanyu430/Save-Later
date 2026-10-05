import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/collection_editor_modal.dart';
import '../../theme/app_theme.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final int? collectionId;
  final BookmarkCollection? collection;

  const CollectionDetailScreen({
    Key? key,
    required this.collectionId,
    required this.collection,
  }) : super(key: key);

  void _showAddLinkModal(BuildContext context, WidgetRef ref) {
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
                    ref.read(bookmarkNotifierProvider.notifier).quickSave(val.trim(), collection: collection);
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
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('Select Links'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Collection'),
            onTap: () => Navigator.pop(ctx),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Collection'),
            onTap: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (modalCtx) => CollectionEditorModal(existingCollection: collection),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = collectionId != null ? ref.watch(collectionBookmarksProvider(collectionId!)) : ref.watch(unsortedBookmarksProvider);

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
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
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
                            (collection?.name ?? 'Unsorted'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${bookmarks.length} items · 0 subcollections',
                            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showAddLinkModal(context, ref),
                            child: NeoBox(
                              color: const Color(0xFFFFD166), // Yellow
                              padding: const EdgeInsets.all(8),
                              borderRadius: 8,
                              borderWidth: 2.5,
                              child: const Icon(Icons.add_link, size: 28),
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
                            return GestureDetector(
                              onTap: () {
                                  ref.read(bookmarkNotifierProvider.notifier).markAsRead(b);
                                  context.push('/bookmark/${b.id}', extra: b);
                                },
                              child: NeoBox(
                                padding: const EdgeInsets.all(0),
                                borderRadius: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppTheme.border, width: 2.5)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(9.5)),
                                          child: b.imageUrl != null
                                              ? Image.network(b.imageUrl!.startsWith('//') ? 'https:' + b.imageUrl! : b.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))
                                              : const Icon(Icons.link, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b.title ?? b.url,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                const Icon(Icons.public, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    b.sourceDomain ?? 'Unknown',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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



