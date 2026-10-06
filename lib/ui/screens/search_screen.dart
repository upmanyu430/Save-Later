import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/bookmark_grid_item.dart';
import '../../providers/providers.dart';
import '../../models/bookmark.dart';
import 'package:save_later/config/app_constants.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

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
        Icon(icon, size: AppDimensions.iconSizeMd, color: AppTheme.border),
        const SizedBox(height: AppDimensions.paddingSm),
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
      int collectionsCount, int bookmarksCount, int pinnedCount, int tagsCount) {
    final l10n = AppLocalizations.of(context)!;
    return NeoBox(
      color: const Color(0xFFFFD166), // Yellow
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yourLibrary,
            style: const TextStyle(
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
              _buildStatColumn(Icons.folder_outlined, '$collectionsCount', l10n.collections),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.book_outlined, '$bookmarksCount', l10n.saves),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.push_pin_outlined, '$pinnedCount', l10n.pinned),
              _buildVerticalDivider(),
              _buildStatColumn(Icons.local_offer_outlined, '$tagsCount', l10n.tags),
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
        context.push('/bookmark/${bookmark.id}', extra: bookmark);
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
                            bookmark.collection.value?.name ?? AppLocalizations.of(context)!.unsorted,
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
                              child: Text(
                                AppLocalizations.of(context)!.newBadge,
                                style: const TextStyle(
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
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
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
                              bookmark.sourceDomain ?? AppLocalizations.of(context)!.unknown,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            AppLocalizations.of(context)!.noResultsFound,
            style: const TextStyle(
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
                              return BookmarkGridItem(bookmark: b);
                            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(collectionsProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    final collectionsCount = collectionsAsync.valueOrNull?.length ?? 0;
    final allBookmarks = bookmarksAsync.valueOrNull ?? [];
    final bookmarksCount = allBookmarks.length;

    // Count pinned bookmarks
    final pinnedCount = allBookmarks.where((b) => b.isPinned).length;

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
                        decoration: InputDecoration(
                          hintText: l10n.findCollectionsOrSavesHint,
                          hintStyle: const TextStyle(
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          icon: const Icon(Icons.search,
                              color: AppTheme.border, size: AppDimensions.iconSizeLg),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMd),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      color: Colors.white,
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
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
                        _buildLibraryStats(collectionsCount, bookmarksCount,
                            pinnedCount, tagsCount),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Recently Saved Header
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                color: AppTheme.border, size: 22),
                            const SizedBox(width: AppDimensions.paddingSm),
                            Text(
                              l10n.recentlySaved,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.border,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),

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
                        const SizedBox(height: AppDimensions.paddingLg),
                        Center(
                          child: Text(
                            l10n.typeSomethingToSearch,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}



