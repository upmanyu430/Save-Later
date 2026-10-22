import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
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
    return Container(
      width: _recentCardWidth(context),
      height: AppDimensions.gridBookmarkCardHeight,
      margin: const EdgeInsets.only(right: AppDimensions.gridSpacingMd),
      child: BookmarkGridItem(
        bookmark: bookmark,
        showCollectionPill: true,
      ),
    );
  }

  double _recentCardWidth(BuildContext context) {
    final availableWidth = (MediaQuery.sizeOf(context)
            .width
            .clamp(0.0, AppDimensions.maxContentWidth)) -
        (AppDimensions.paddingXl * 2);
    final columnCount = (availableWidth /
            (AppDimensions.gridMaxCrossAxisExtent + AppDimensions.gridSpacingMd))
        .ceil()
        .clamp(1, 10)
        .toInt();
    return (availableWidth -
            (columnCount - 1) * AppDimensions.gridSpacingMd) /
        columnCount;
  }

  Widget _buildSearchResults(List<Bookmark> allBookmarks, double bottomInset) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 48.0;
        const maxCrossAxisExtent = 200.0;
        const crossAxisSpacing = AppDimensions.gridSpacingMd;
        const desiredCardHeight = AppDimensions.gridBookmarkCardHeight;
        final contentWidth = constraints.maxWidth - horizontalPadding;
        final columnCount = (contentWidth /
                (maxCrossAxisExtent + crossAxisSpacing))
            .ceil()
            .clamp(1, 10)
            .toInt();

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: AppDimensions.gridSpacingMd,
            mainAxisExtent: desiredCardHeight,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final b = results[index];
            return BookmarkGridItem(
              bookmark: b,
              showCollectionPill: true,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    final collectionsCount = collectionsAsync.valueOrNull?.length ?? 0;
    final allBookmarks = bookmarksAsync.valueOrNull ?? [];
    final bookmarksCount = allBookmarks.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
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
                  NeoButton(
                    onPressed: () => context.pop(),
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
                  ? _buildSearchResults(allBookmarks, bottomInset)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
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
                            height: AppDimensions.gridBookmarkCardHeight,
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
    ),
  ),
);
}
}




