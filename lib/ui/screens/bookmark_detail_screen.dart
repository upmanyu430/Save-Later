import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../../utils/url_launcher.dart';

class BookmarkDetailScreen extends ConsumerWidget {
  final Bookmark bookmark;

  const BookmarkDetailScreen({Key? key, required this.bookmark}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ...bookmark.tags.map((tag) => Chip(
                  label: Text('#$tag'),
                  backgroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.border, width: 2),
                )),
                ActionChip(
                  label: const Text('+ Add Tag'),
                  backgroundColor: AppTheme.secondary,
                  side: const BorderSide(color: AppTheme.border, width: 2),
                  onPressed: () {
                    // TODO: Implement add tag modal
                  },
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
          ],
        ),
      ),
    );
  }
}
