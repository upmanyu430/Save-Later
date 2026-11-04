import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_tag_badge.dart';
import '../widgets/bookmark_grid_item.dart';
import '../widgets/collection_grid_item.dart';
import '../widgets/pin_icon.dart';
import '../../providers/providers.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  late LibraryTab _selectedTab;
  String _searchQuery = '';
  String? _selectedTagFilter;

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildStatTab({
    IconData? icon,
    Widget? iconWidget,
    required String count,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget ??
            Icon(icon!, size: 20, color: AppTheme.border),
        const SizedBox(height: 2),
        Text(
          count,
          style: GoogleFonts.gabarito(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.border,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.gabarito(
            fontSize: 10.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
      borderRadius: 16.0,
      borderWidth: 2.5,
      shadowOffset: 3.0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.yourLibrary,
                style: GoogleFonts.gabarito(
                  fontSize: 13,
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
                    horizontal: 10,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.border,
                      width: 2.0,
                    ),
                    boxShadow: _selectedTab == LibraryTab.overview
                        ? const [
                            BoxShadow(
                              color: AppTheme.border,
                              offset: Offset(1.5, 1.5),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    l10n.overview,
                    style: GoogleFonts.gabarito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatTab(
                icon: Icons.folder_outlined,
                count: '$collectionsCount',
                label: l10n.collections,
                isSelected: _selectedTab == LibraryTab.collections,
                onTap: () => setState(() => _selectedTab =
                    _selectedTab == LibraryTab.collections
                        ? LibraryTab.overview
                        : LibraryTab.collections),
              ),
              _buildStatTab(
                icon: Icons.link,
                count: '$bookmarksCount',
                label: l10n.saves,
                isSelected: _selectedTab == LibraryTab.saves,
                onTap: () => setState(() => _selectedTab =
                    _selectedTab == LibraryTab.saves
                        ? LibraryTab.overview
                        : LibraryTab.saves),
              ),
              _buildStatTab(
                iconWidget: const PinIcon(
                  size: 20,
                  isPinned: true,
                  color: AppTheme.border,
                ),
                count: '$pinnedCount',
                label: l10n.pinned,
                isSelected: _selectedTab == LibraryTab.pinned,
                onTap: () => setState(() => _selectedTab =
                    _selectedTab == LibraryTab.pinned
                        ? LibraryTab.overview
                        : LibraryTab.pinned),
              ),
              _buildStatTab(
                icon: Icons.local_offer_outlined,
                count: '$tagsCount',
                label: l10n.tags,
                isSelected: _selectedTab == LibraryTab.tags,
                onTap: () => setState(() => _selectedTab =
                    _selectedTab == LibraryTab.tags
                        ? LibraryTab.overview
                        : LibraryTab.tags),
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
        key: ValueKey('recent_bookmark_${bookmark.id}'),
        bookmark: bookmark,
        showCollectionPill: true,
      ),
    );
  }

  double _recentCardWidth(BuildContext context) {
    final availableWidth = (MediaQuery.sizeOf(context)
            .width
            .clamp(0.0, AppDimensions.maxContentWidth)) -
        (AppDimensions.paddingLg * 2);
    final columnCount = (availableWidth /
            (AppDimensions.gridMaxCrossAxisExtent + AppDimensions.gridSpacingMd))
        .ceil()
        .clamp(1, 10)
        .toInt();
    return (availableWidth -
            (columnCount - 1) * AppDimensions.gridSpacingMd) /
        columnCount;
  }

  Widget _buildCollectionsView(
    List<BookmarkCollection> collections,
    List<Bookmark> allBookmarks,
    AppLocalizations l10n,
  ) {
    if (collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.folder_open_outlined,
                  size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              Text(
                l10n.myCollections,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const maxCrossAxisExtent = AppDimensions.gridMaxCrossAxisExtent;
        const crossAxisSpacing = AppDimensions.gridSpacingMd;
        const desiredCardHeight = AppDimensions.gridFolderCardHeight;
        final gridWidth = constraints.maxWidth;
        final columnCount = (gridWidth /
                (maxCrossAxisExtent + crossAxisSpacing))
            .ceil()
            .clamp(1, 10)
            .toInt();
        final itemWidth = (gridWidth -
                (columnCount - 1) * crossAxisSpacing) /
            columnCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined,
                    size: 18, color: AppTheme.border),
                const SizedBox(width: 8),
                Text(
                  l10n.collections.toUpperCase(),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: AppDimensions.gridSpacingLg,
                childAspectRatio: itemWidth / desiredCardHeight,
              ),
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final col = collections[index];
                final colBookmarks = allBookmarks.where((b) {
                  return b.collection.value?.id == col.id;
                }).toList();
                final hasNew = colBookmarks.any((b) => !b.isRead);
                final newCount = colBookmarks.where((b) => !b.isRead).length;

                return CollectionGridItem(
                  collection: col,
                  itemCount: colBookmarks.length,
                  hasNewItems: hasNew,
                  newCount: newCount,
                  onTap: () =>
                      context.push('/collection/${col.id}', extra: col),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavesView(
    List<Bookmark> allBookmarks,
    AppLocalizations l10n,
  ) {
    if (allBookmarks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.bookmark_border, size: 48, color: Colors.black26),
              SizedBox(height: 12),
              Text(
                'No saves yet',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.link, size: 18, color: AppTheme.border),
            const SizedBox(width: 8),
            Text(
              l10n.saves.toUpperCase(),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.gridSpacingMd,
            mainAxisSpacing: AppDimensions.gridSpacingMd,
            mainAxisExtent: AppDimensions.gridBookmarkCardHeight,
          ),
          itemCount: allBookmarks.length,
          itemBuilder: (context, index) {
            final b = allBookmarks[index];
            return BookmarkGridItem(
              key: ValueKey('all_bookmark_${b.id}'),
              bookmark: b,
              showCollectionPill: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPinnedView(
    List<Bookmark> allBookmarks,
    AppLocalizations l10n,
  ) {
    final pinned = allBookmarks.where((b) => b.isPinned).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const PinIcon(
              size: 18,
              isPinned: true,
              color: AppTheme.border,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.pinned.toUpperCase(),
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
        if (pinned.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Column(
                children: [
                  PinIcon(
                    size: 48,
                    isPinned: true,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No pinned saves',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black45,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Pin your favorite saves to quickly find them here',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.gridSpacingMd,
              mainAxisSpacing: AppDimensions.gridSpacingMd,
              mainAxisExtent: AppDimensions.gridBookmarkCardHeight,
            ),
            itemCount: pinned.length,
            itemBuilder: (context, index) {
              final b = pinned[index];
              return BookmarkGridItem(
                key: ValueKey('pinned_bookmark_${b.id}'),
                bookmark: b,
                showCollectionPill: true,
              );
            },
          ),
      ],
    );
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

    // Filter bookmarks for currently selected tag
    final matchingBookmarks = _selectedTagFilter == null
        ? <Bookmark>[]
        : allBookmarks.where((b) {
            final target = _selectedTagFilter!.startsWith('#')
                ? _selectedTagFilter!.substring(1).trim().toLowerCase()
                : _selectedTagFilter!.trim().toLowerCase();
            return b.tags.any((t) {
              final clean = t.startsWith('#')
                  ? t.substring(1).trim().toLowerCase()
                  : t.trim().toLowerCase();
              return clean == target;
            });
          }).toList();

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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border, width: 1.5),
              ),
              child: Text(
                '${displayedTags.length}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.border,
                ),
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
              final isTagSelected = _selectedTagFilter != null &&
                  (_selectedTagFilter!.toLowerCase().trim() ==
                      entry.key.toLowerCase().trim());

              return NeoTagBadge(
                name: entry.key,
                count: entry.value,
                color: NeoTagBadge.getColor(entry.key, index),
                tilt: tilt,
                isSelected: isTagSelected,
                onTap: () {
                  setState(() {
                    if (isTagSelected) {
                      _selectedTagFilter = null;
                    } else {
                      _selectedTagFilter = entry.key;
                    }
                  });
                },
              );
            }),
          ),
        ),
        if (_selectedTagFilter != null) ...[
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_outline,
                    size: 18,
                    color: AppTheme.border,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TAGGED #${_selectedTagFilter!.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.border,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border, width: 1.5),
                    ),
                    child: Text(
                      '${matchingBookmarks.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.border,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedTagFilter = null);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.border,
                        offset: Offset(1.5, 1.5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: AppTheme.border),
                      SizedBox(width: 4),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.border,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (matchingBookmarks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.bookmark_border,
                        size: 40, color: Colors.black26),
                    const SizedBox(height: 8),
                    Text(
                      'No bookmarks found with tag #$_selectedTagFilter',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.gridSpacingMd,
                mainAxisSpacing: AppDimensions.gridSpacingMd,
                mainAxisExtent: AppDimensions.gridBookmarkCardHeight,
              ),
              itemCount: matchingBookmarks.length,
              itemBuilder: (context, index) {
                final b = matchingBookmarks[index];
                return BookmarkGridItem(
                  key: ValueKey('tag_bookmark_${b.id}'),
                  bookmark: b,
                  showCollectionPill: true,
                );
              },
            ),
        ] else ...[
          const SizedBox(height: 24),
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 16, color: Colors.black38),
                  SizedBox(width: 6),
                  Text(
                    'Tap any tag above to view its bookmarks',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    final isTagSearch = _searchQuery.startsWith('#');
    final tagQuery = isTagSearch
        ? _searchQuery.substring(1).trim().toLowerCase()
        : '';

    final results = allBookmarks.where((b) {
      if (isTagSearch) {
        if (tagQuery.isEmpty) return b.tags.isNotEmpty;
        return b.tags.any((t) {
          final clean = t.startsWith('#')
              ? t.substring(1).trim().toLowerCase()
              : t.trim().toLowerCase();
          return clean == tagQuery;
        });
      }

      final titleMatch = (b.title ?? '').toLowerCase().contains(_searchQuery);
      final urlMatch = b.url.toLowerCase().contains(_searchQuery);
      final tagMatch = b.tags.any((t) {
        final clean = t.startsWith('#')
            ? t.substring(1).trim().toLowerCase()
            : t.trim().toLowerCase();
        return clean.contains(_searchQuery);
      });
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
        const horizontalPadding = AppDimensions.paddingLg * 2;
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
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
              key: ValueKey('search_bookmark_${b.id}'),
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

    final collections = collectionsAsync.valueOrNull ?? [];
    final collectionsCount = collections.length;
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
                // Pinned Header: Search Bar & Cancel Button + Library Stats (when not searching)
                Container(
                  color: AppTheme.background,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50.4,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _searchFocusNode.requestFocus(),
                                  child: NeoBox(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 8,
                                    ),
                                    color: Colors.white,
                                    borderRadius: 14.0,
                                    borderWidth: 2.5,
                                    shadowOffset: 2.0,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.search,
                                          color: AppTheme.border,
                                          size: 21,
                                        ),
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            textAlignVertical: TextAlignVertical.center,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              hintText: l10n.findCollectionsOrSavesHint,
                                              hintStyle: GoogleFonts.gabarito(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black38,
                                              ),
                                            ),
                                            style: GoogleFonts.gabarito(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.border,
                                            ),
                                          ),
                                        ),
                                        if (_searchController.text.isNotEmpty)
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                                              child: Icon(Icons.close,
                                                  color: AppTheme.border, size: 20),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingMd),
                            SizedBox(
                              height: 50.4,
                              child: NeoButton(
                                onPressed: () => context.pop(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                color: Colors.white,
                                borderWidth: 2.5,
                                borderRadius: 14.0,
                                shadowOffset: 2.0,
                                child: Text(
                                  l10n.cancel,
                                  style: GoogleFonts.gabarito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.border,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_searchQuery.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: _buildLibraryStats(
                            collectionsCount,
                            bookmarksCount,
                            pinnedCount,
                            tagsCount,
                          ),
                        ),
                    ],
                  ),
                ),

                // Scrollable Body
                Expanded(
                  child: _searchQuery.isNotEmpty
                      ? _buildSearchResults(allBookmarks, bottomInset)
                      : ListView(
                          clipBehavior: Clip.hardEdge,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24 + bottomInset,
                          ),
                          children: [
                            if (_selectedTab == LibraryTab.tags)
                              _buildTagsView(allBookmarks)
                            else if (_selectedTab == LibraryTab.collections)
                              _buildCollectionsView(
                                collections,
                                allBookmarks,
                                l10n,
                              )
                            else if (_selectedTab == LibraryTab.saves)
                              _buildSavesView(allBookmarks, l10n)
                            else if (_selectedTab == LibraryTab.pinned)
                              _buildPinnedView(allBookmarks, l10n)
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
