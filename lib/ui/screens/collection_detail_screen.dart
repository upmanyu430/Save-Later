import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
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
        backgroundColor: Color(int.parse('0xFF${collection.colorHex}')),
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
                onTap: () async {
                  final uri = Uri.parse(b.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
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
                    // Logic to add link to this collection
                    Navigator.pop(ctx);
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
