import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../../providers/providers.dart';
import '../../models/bookmark.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.black26,
    );
  }

  Widget _buildStatColumn(IconData icon, String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: AppTheme.border),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppTheme.border,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.border,
          ),
        ),
      ],
    );
  }

  Widget _buildLibraryStats(
      int collectionsCount, int bookmarksCount, int tagsCount) {
    return NeoBox(
      color: const Color(0xFFFFD166), // Yellow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR LIBRARY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.border,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatColumn(Icons.folder_outlined, '', 'Collections'),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.book_outlined, '', 'Saves'),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.push_pin_outlined, '0', 'Pinned'),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.local_offer_outlined, '', 'Tags'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard(Bookmark bookmark) {
    return GestureDetector(
      onTap: () {
        ref.read(bookmarkNotifierProvider.notifier).markAsRead(bookmark);
        context.push('/bookmark/', extra: bookmark);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: NeoBox(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top half image/color
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Initial letter
                      Center(
                        child: Text(
                          bookmark.title != null && bookmark.title!.isNotEmpty
                              ? bookmark.title![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.border,
                          ),
                        ),
                      ),
                      // Overlay Unsorted/Collection pill
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bookmark.collection.value?.name ?? 'Unsorted',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      // NEW pill
                      if (!bookmark.isRead)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Transform.rotate(
                            angle: -0.1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD166),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppTheme.border, width: 1.5),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
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
              // Horizontal divider
              Container(height: 3, color: AppTheme.border),
              // Bottom half details
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(13),
                      bottomRight: Radius.circular(13),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookmark.title ?? bookmark.url,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.border,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF8A65), // Placeholder color
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                bookmark.sourceDomain != null &&
                                        bookmark.sourceDomain!.isNotEmpty
                                    ? bookmark.sourceDomain![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              bookmark.sourceDomain ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<Bookmark> allBookmarks) {
    final results = allBookmarks.where((b) {
      final titleMatch = (b.title ?? '').toLowerCase().contains(_searchQuery);
      final urlMatch = b.url.toLowerCase().contains(_searchQuery);
      final tagMatch =
          b.tags.any((t) => t.toLowerCase().contains(_searchQuery));
      return titleMatch || urlMatch || tagMatch;
    }).toList();

    if (results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No results found.',
            style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final b = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () {
              ref.read(bookmarkNotifierProvider.notifier).markAsRead(b);
              context.push('/bookmark/', extra: b);
            },
            child: NeoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title ?? b.url,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.border,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b.url,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    final collectionsCount = collectionsAsync.valueOrNull?.length ?? 0;
    final allBookmarks = bookmarksAsync.valueOrNull ?? [];
    final bookmarksCount = allBookmarks.length;

    // Count unique tags
    final Set<String> uniqueTags = {};
    for (var b in allBookmarks) {
      uniqueTags.addAll(b.tags);
    }
    final tagsCount = uniqueTags.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      color: Colors.white,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Find collections or saves...',
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.search,
                              color: AppTheme.border, size: 28),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      color: Colors.white,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.border,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Thick black border line
            Container(
              height: 3,
              width: double.infinity,
              color: AppTheme.border,
            ),

            // Body
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults(allBookmarks)
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      children: [
                        _buildLibraryStats(
                            collectionsCount, bookmarksCount, tagsCount),
                        const SizedBox(height: 32),

                        // Recently Saved Header
                        Row(
                          children: const [
                            Icon(Icons.schedule,
                                color: AppTheme.border, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'RECENTLY SAVED',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.border,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Horizontal Cards
                        if (allBookmarks.isNotEmpty)
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: allBookmarks.length > 10
                                  ? 10
                                  : allBookmarks.length,
                              clipBehavior: Clip.none,
                              itemBuilder: (context, index) {
                                return _buildRecentCard(allBookmarks[index]);
                              },
                            ),
                          ),

                        const SizedBox(height: 64),

                        // Empty search state indicator
                        const Icon(
                          Icons.search,
                          size: 64,
                          color: AppTheme.border,
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Type something to search...',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
