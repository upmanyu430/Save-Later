import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/collection_editor_modal.dart';
import '../../theme/app_theme.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final int collectionId;
  final BookmarkCollection collection;

  const CollectionDetailScreen({
    Key? key,
    required this.collectionId,
    required this.collection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(collectionBookmarksProvider(collectionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        backgroundColor: collection.color,
      ),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 80, color: AppTheme.border),
                    const SizedBox(height: 16),
                    const Text(
                      'No items yet. Tap + or share to save one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final b = bookmarks[index];
              return GestureDetector(
                onTap: () {
                  context.push('/bookmark/${b.id}', extra: b);
                },
                child: NeoBox(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (b.imageUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          child: Image.network(
                            b.imageUrl!,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(height: 140, child: Center(child: Icon(Icons.image_not_supported))),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.title ?? b.url,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (b.sourceDomain != null)
                              Text(
                                b.sourceDomain!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.border.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open menu (Bottom Sheet)
          showModalBottomSheet(
            context: context,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_link),
                  title: const Text('Add Link'),
                  onTap: () {
                    Navigator.pop(ctx);
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
                  },
                ),
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
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.menu, color: AppTheme.border),
      ),
    );
  }
}

