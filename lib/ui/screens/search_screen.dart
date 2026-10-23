import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_tag_badge.dart';
import '../widgets/bookmark_grid_item.dart';
import '../../providers/providers.dart';
import '../../models/bookmark.dart';
import 'package:save_later/config/app_constants.dart';

enum LibraryTab {
  overview,
  collections,
  saves,
  pinned,
  tags,
}

class SearchScreen extends ConsumerStatefulWidget {
  final LibraryTab initialTab;

  const SearchScreen({
    super.key,
    this.initialTab = LibraryTab.overview,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late LibraryTab _selectedTab;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
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

  Widget _buildStatTab({
    required IconData icon,
    required String count,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSizeMd, color: AppTheme.border),
        const SizedBox(height: 6),
        Text(
          count,
          style: const TextStyle(
            fontSize: 26,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.border : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: content,
      ),
    );
  }

  Widget _buildLibraryStats(
    int collectionsCount,
    int bookmarksCount,
    int pinnedCount,
    int tagsCount,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return NeoBox(
      color: const Color(0xFFFFD166), // Yellow
      borderRadius: 18.0,
      borderWidth: 2.5,
      shadowOffset: 3.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedTab = LibraryTab.overview;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.border,
                      width: 2.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.border,
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.overview,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatTab(
                icon: Icons.folder_outlined,
                count: '$collectionsCount',
                label: l10n.collections,
                isSelected: _selectedTab == LibraryTab.collections,
                onTap: () => setState(() => _selectedTab = LibraryTab.collections),
              ),
              _buildStatTab(
                icon: Icons.link,
                count: '$bookmarksCount',
                label: l10n.saves,
                isSelected: _selectedTab == LibraryTab.saves,
                onTap: () => setState(() => _selectedTab = LibraryTab.saves),
              ),
              _buildStatTab(
                icon: Icons.push_pin_outlined,
                count: '$pinnedCount',
                label: l10n.pinned,
                isSelected: _selectedTab == LibraryTab.pinned,
                onTap: () => setState(() => _selectedTab = LibraryTab.pinned),
              ),
              _buildStatTab(
                icon: Icons.local_offer_outlined,
                count: '$tagsCount',
                label: l10n.tags,
                isSelected: _selectedTab == LibraryTab.tags,
                onTap: () => setState(() => _selectedTab = LibraryTab.tags),
              ),
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

  Widget _buildTagsView(List<Bookmark> allBookmarks) {
    final l10n = AppLocalizations.of(context)!;

    // Collect tags from real bookmarks
    final Map<String, int> tagCounts = {};
    for (final b in allBookmarks) {
      for (final t in b.tags) {
        final clean = t.trim();
        if (clean.isNotEmpty) {
          tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
        }
      }
    }

    final userTags = tagCounts.entries
        .map((e) => MapEntry(e.key, e.value))
        .toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    final displayedTags =
        userTags.isNotEmpty ? userTags : NeoTagBadge.sampleTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: AppTheme.border,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.tagsLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.border,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12.0,
            runSpacing: 16.0,
            children: List.generate(displayedTags.length, (index) {
              final entry = displayedTags[index];
              final tilt = NeoTagBadge.getTilt(index);
              return NeoTagBadge(
                name: entry.key,
                count: entry.value,
                color: NeoTagBadge.getColor(entry.key, index),
                tilt: tilt,
                onTap: () {
                  _searchController.text = entry.key;
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewView(
    List<Bookmark> allBookmarks,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recently Saved Header
        Row(
          children: [
            const Icon(Icons.schedule, color: AppTheme.border, size: 22),
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
              itemCount: allBookmarks.length > 10 ? 10 : allBookmarks.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                return _buildRecentCard(allBookmarks[index]);
              },
            ),
          ),

        const SizedBox(height: 64),

        // Empty search state indicator
        const Center(
          child: Icon(
            Icons.search,
            size: 64,
            color: AppTheme.border,
          ),
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
    );
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
              fontWeight: FontWeight.w500,
            ),
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
                // Header (Search Bar & Cancel Button)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: NeoBox(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          color: Colors.white,
                          borderRadius: 14.0,
                          borderWidth: 2.5,
                          shadowOffset: 2.0,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: l10n.findCollectionsOrSavesHint,
                              hintStyle: const TextStyle(
                                color: Colors.black38,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              icon: const Icon(
                                Icons.search,
                                color: AppTheme.border,
                                size: AppDimensions.iconSizeLg,
                              ),
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
                          horizontal: 16,
                          vertical: 14,
                        ),
                        color: Colors.white,
                        borderWidth: 2.5,
                        borderRadius: 14.0,
                        shadowOffset: 2.0,
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

                // Body
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults(allBookmarks, bottomInset)
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            24 + bottomInset,
                          ),
                          children: [
                            _buildLibraryStats(
                              collectionsCount,
                              bookmarksCount,
                              pinnedCount,
                              tagsCount,
                            ),
                            const SizedBox(height: AppDimensions.paddingXxl),
                            if (_selectedTab == LibraryTab.tags)
                              _buildTagsView(allBookmarks)
                            else
                              _buildOverviewView(allBookmarks, l10n),
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
