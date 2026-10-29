import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../widgets/neo_button.dart';
import '../widgets/neo_box.dart';
import '../widgets/favicon_image.dart';
import '../../theme/app_theme.dart';
import '../../utils/url_launcher.dart';
import '../../utils/url_helper.dart';
import 'package:save_later/config/app_constants.dart';

class ReviewModeScreen extends ConsumerStatefulWidget {
  final BookmarkCollection? collection;
  const ReviewModeScreen({super.key, this.collection});

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _CardTransformData {
  final int index;
  final double dx;
  final double scale;
  final double opacity;
  final double angle;
  final int zIndex;

  const _CardTransformData({
    required this.index,
    required this.dx,
    required this.scale,
    required this.opacity,
    required this.angle,
    required this.zIndex,
  });
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen> {
  late final PageController _pageController;
  int currentIndex = 0;
  List<Bookmark> unreadBookmarks = [];
  bool loaded = false;
  final Set<int> _reviewedBookmarkIds = {};
  int get completedCount => _reviewedBookmarkIds.length;
  int? _dragStartPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    Future.microtask(() async {
      List<Bookmark> list;
      if (widget.collection == null) {
        list = await ref.read(unsortedBookmarksProvider.future);
      } else {
        list = await ref
            .read(collectionBookmarksProvider(widget.collection!.id).future);
      }
      if (mounted) {
        setState(() {
          // Collections are repeatable review folders: show every bookmark
          // each time. Unsorted remains the inbox and only shows unread saves.
          unreadBookmarks = widget.collection == null
              ? list.where((b) => !b.isRead).toList()
              : list;
          loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyAction(Bookmark bookmark) {
    _reviewedBookmarkIds.add(bookmark.id);
    final notifier = ref.read(bookmarkNotifierProvider.notifier);
    // Reviewing a card must never delete the saved bookmark. Both swipe
    // directions complete the review by marking it as read; deletion remains
    // available from the bookmark's own actions.
    notifier.markAsRead(bookmark);
  }

  void _onPageChanged(int nextIndex) {
    final previousIndex = currentIndex;
    if (nextIndex == previousIndex || previousIndex >= unreadBookmarks.length) {
      return;
    }

    HapticFeedback.lightImpact();

    // Backward navigation (swipe or button) to an earlier card is purely navigation;
    // do not mark as read or increment counts when looking back at a card.
    if (nextIndex < previousIndex) {
      setState(() {
        currentIndex = nextIndex;
      });
      return;
    }

    // PageView has one trailing page so the final bookmark can be swiped
    // away naturally. Reaching that page completes the last bookmark and
    // lets the parent rebuild into the caught-up state.
    // Only a forward swipe can complete the review. A backward swipe from
    // the last card is navigation and must not jump to the caught-up screen.
    if (nextIndex > previousIndex &&
        (nextIndex == unreadBookmarks.length ||
            previousIndex == unreadBookmarks.length - 1)) {
      for (var index = previousIndex;
          index < unreadBookmarks.length;
          index++) {
        _applyAction(unreadBookmarks[index]);
      }
      setState(() {
        currentIndex = unreadBookmarks.length;
      });
      return;
    }

    // A forward swipe completes the cards passed.
    if (nextIndex > previousIndex) {
      final lastUnreviewedIndex =
          nextIndex.clamp(0, unreadBookmarks.length).toInt();
      for (var index = previousIndex; index < lastUnreviewedIndex; index++) {
        _applyAction(unreadBookmarks[index]);
      }

      setState(() {
        currentIndex = nextIndex;
      });
    }
  }

  void _goToNext() {
    if (currentIndex >= unreadBookmarks.length) return;
    _dragStartPage = currentIndex;
    if (currentIndex == unreadBookmarks.length - 1) {
      _applyAction(unreadBookmarks[currentIndex]);
      setState(() {
        currentIndex = unreadBookmarks.length;
      });
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPrevious() {
    if (currentIndex <= 0 || !_pageController.hasClients) return;
    _dragStartPage = currentIndex;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      final start = _pageController.hasClients && _pageController.page != null
          ? _pageController.page!.round()
          : currentIndex;
      if (_dragStartPage != start) {
        _dragStartPage = start;
      }
    } else if (notification is ScrollEndNotification) {
      if (_dragStartPage != null) {
        _dragStartPage = null;
      }
    }
    return false;
  }

  List<_CardTransformData> _calculateCardTransforms(
    double page,
    double cardWidth,
    int totalCards,
  ) {
    if (totalCards == 0) return const [];

    final k = page.floor();
    final frac = page - k;
    final isAtRest = frac.abs() < 0.0001;

    final isBackward = !isAtRest &&
        ((_dragStartPage != null && _dragStartPage == k + 1) ||
            (_dragStartPage == null && currentIndex == k + 1));

    final List<_CardTransformData> list = [];

    void addCard(int idx, double dx, double scale, double opacity, double angle, int zIndex) {
      if (idx < 0 || idx >= totalCards) return;
      if (opacity <= 0.0) return;
      list.add(_CardTransformData(
        index: idx,
        dx: dx,
        scale: scale,
        opacity: opacity.clamp(0.0, 1.0),
        angle: angle,
        zIndex: zIndex,
      ));
    }

    if (isAtRest) {
      // Resting on card k
      addCard(k, 0.0, 1.0, 1.0, 0.0, 4);
      addCard(k + 1, 44.0, 0.94, 0.60, 0.0, 2);
      addCard(k + 2, 80.0, 0.88, 0.35, 0.0, 1);
      addCard(k - 1, -44.0, 0.94, 0.60, 0.0, 2);
      addCard(k - 2, -80.0, 0.88, 0.35, 0.0, 1);
    } else if (!isBackward) {
      // Forward swipe: moving from k towards k + 1
      // Card k is being swiped off to the left with counter-clockwise tilt
      final diffK = k - page; // in [-1.0, 0.0]
      final dxK = diffK * (cardWidth * 1.05);
      final angleK = diffK * 0.08;
      final opacityK = 1.0 - ((-diffK) * 0.40);
      addCard(k, dxK, 1.0, opacityK, angleK, 4);

      // Card k + 1 is moving from right stack (+44) into center (0)
      final diffNext = (k + 1) - page; // in [0.0, 1.0]
      final dxNext = diffNext * 44.0;
      final scaleNext = 1.0 - (diffNext * 0.06);
      final opacityNext = 1.0 - (diffNext * 0.40);
      // Entering card tilts clockwise (positive angle) proportional to remaining distance
      final angleNext = diffNext * 0.05;
      addCard(k + 1, dxNext, scaleNext, opacityNext, angleNext, 3);

      // Card k + 2 is moving from +80 to +44
      final diffNext2 = (k + 2) - page; // in [1.0, 2.0]
      final pNext2 = diffNext2 - 1.0;
      final dxNext2 = 44.0 + (pNext2 * 36.0);
      final scaleNext2 = 0.94 - (pNext2 * 0.06);
      final opacityNext2 = 0.60 - (pNext2 * 0.25);
      addCard(k + 2, dxNext2, scaleNext2, opacityNext2, 0.0, 1);

      // Card k - 1 is moving from -44 to -80
      final diffPrev = (k - 1) - page; // in [-2.0, -1.0]
      final pPrev = -diffPrev - 1.0;
      final dxPrev = -44.0 - (pPrev * 36.0);
      final scalePrev = 0.94 - (pPrev * 0.06);
      final opacityPrev = 0.60 - (pPrev * 0.25);
      addCard(k - 1, dxPrev, scalePrev, opacityPrev, 0.0, 2);
    } else {
      // Backward swipe: moving from k + 1 towards k
      final progress = (k + 1) - page; // in [0.0, 1.0] as page goes from k+1 to k

      // Card k + 1 is the active card sliding right with clockwise tilt
      final dxActive = progress * (cardWidth * 1.05);
      final angleActive = progress * 0.08;
      final opacityActive = 1.0 - (progress * 0.40);
      addCard(k + 1, dxActive, 1.0, opacityActive, angleActive, 4);

      // Card k is the previous card expanding from -44 into center 0
      final dxPrev = -44.0 * (1.0 - progress);
      final scalePrev = 0.94 + (progress * 0.06);
      final opacityPrev = 0.60 + (progress * 0.40);
      // Entering card tilts counter-clockwise (negative angle) proportional to remaining distance
      final anglePrev = -(1.0 - progress) * 0.05;
      addCard(k, dxPrev, scalePrev, opacityPrev, anglePrev, 3);

      // Card k - 1 moves from -80 to -44
      final dxPrev2 = -80.0 + (progress * 36.0);
      final scalePrev2 = 0.88 + (progress * 0.06);
      final opacityPrev2 = 0.35 + (progress * 0.25);
      addCard(k - 1, dxPrev2, scalePrev2, opacityPrev2, 0.0, 1);

      // Card k + 2 moves from +44 to +80
      final dxNext2 = 44.0 + (progress * 36.0);
      final scaleNext2 = 0.94 - (progress * 0.06);
      final opacityNext2 = 0.60 - (progress * 0.25);
      addCard(k + 2, dxNext2, scaleNext2, opacityNext2, 0.0, 2);
    }

    // Sort by zIndex ascending (lowest zIndex painted first, highest painted on top)
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final isDone =
        unreadBookmarks.isEmpty || currentIndex >= unreadBookmarks.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF111111), // Almost black
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: isDone
                ? _buildCaughtUp(bottomInset)
                : _buildReviewUI(bottomInset),
          ),
        ),
      ),
    );
  }

  Widget _buildCaughtUp(double bottomInset) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Checkmark circle
        Stack(
          alignment: Alignment.center,
          children: [
            // Sparkles background
            Positioned(
                top: 0,
                left: 20,
                child: Icon(Icons.auto_awesome,
                    color: Colors.greenAccent.withValues(alpha: 0.8),
                    size: AppDimensions.iconSizeMd)),
            Positioned(
                bottom: 10,
                right: 20,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
            Positioned(
                top: 20,
                right: 0,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
            Positioned(
                bottom: 0,
                left: 10,
                child: Icon(Icons.auto_awesome,
                    color: Colors.greenAccent, size: AppDimensions.iconSizeLg)),
            Container(
              width: 124,
              height: 124,
              decoration: const BoxDecoration(
                color: Color(0xFF3CD27D), // Green
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 64),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingXxl),
        Text(
          AppLocalizations.of(context)!.caughtUpTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.caughtUpSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingXxl),
        NeoBox(
          color: Colors.white,
          borderRadius: 16,
          shadowOffset: 3,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            AppLocalizations.of(context)!.viewedCount(completedCount),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomInset),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: NeoButton(
                    color: Colors.white,
                    borderRadius: AppDimensions.radiusXl,
                    padding: EdgeInsets.zero,
                    shadowOffset: 0,
                    onPressed: () {
                      // currentIndex points at the trailing page while the
                      // caught-up view is shown. Use it as the source of truth
                      // instead of completedCount, which can lag behind when
                      // the last card was completed by a pager callback.
                      if (currentIndex > 0 && unreadBookmarks.isNotEmpty) {
                        final previousIndex = (currentIndex - 1)
                            .clamp(0, unreadBookmarks.length - 1)
                            .toInt();
                        setState(() {
                          currentIndex = previousIndex;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _pageController.hasClients) {
                            _pageController.jumpToPage(previousIndex);
                          }
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                        const SizedBox(width: AppDimensions.paddingSm),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.previous,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: NeoButton(
                    color: const Color(0xFFFFD166),
                    borderRadius: AppDimensions.radiusXl,
                    padding: EdgeInsets.zero,
                    shadowOffset: 0,
                    onPressed: () {
                      // Review is pushed from the current folder. Pop back to
                      // that folder instead of replacing the route with home.
                      context.pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home_outlined, color: Colors.black, size: 24),
                        const SizedBox(width: AppDimensions.paddingSm),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.done,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildReviewUI(double bottomInset) {
    final reviewTitle = widget.collection == null
        ? 'NEW SAVES'
        : widget.collection!.name.toUpperCase();

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reviewTitle,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (currentIndex + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' / ${unreadBookmarks.length.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 45,
                height: 45,
                child: NeoButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  color: const Color(0xFF222222),
                  borderColor: Colors.white24,
                  shadowColor: Colors.black,
                  borderWidth: 1.5,
                  borderRadius: AppDimensions.radiusXl,
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        // Progress Bars
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: List.generate(unreadBookmarks.length, (index) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  margin: EdgeInsets.only(
                      right: index == unreadBookmarks.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= currentIndex
                        ? const Color(0xFFFFD166)
                        : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ),

        // Swiper
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.sizeOf(context).width;
                    final cardWidth = (screenWidth * 0.736).clamp(280.0, 420.0);
                    final cardHeight = (cardWidth * 1.70).clamp(0.0, constraints.maxHeight * 0.88);

                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Stacked deck visual rendering in proper Z-order
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _pageController,
                                builder: (context, _) {
                                  final page = _pageController.hasClients &&
                                          _pageController.page != null
                                      ? _pageController.page!
                                      : currentIndex.toDouble();
                                  final transforms = _calculateCardTransforms(
                                    page,
                                    cardWidth,
                                    unreadBookmarks.length,
                                  );

                                  return Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: transforms.map((data) {
                                      return Transform.translate(
                                        offset: Offset(data.dx, 0),
                                        child: Transform.rotate(
                                          angle: data.angle,
                                          child: Transform.scale(
                                            scale: data.scale,
                                            child: Opacity(
                                              opacity: data.opacity,
                                              child: _buildCard(
                                                unreadBookmarks[data.index],
                                                cardWidth,
                                                cardHeight,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Gesture driver PageView
                        Positioned.fill(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: _onScrollNotification,
                            child: PageView.builder(
                              controller: _pageController,
                              clipBehavior: Clip.none,
                              itemCount: unreadBookmarks.length + 1,
                              onPageChanged: _onPageChanged,
                              allowImplicitScrolling: true,
                              physics: const PageScrollPhysics(),
                              itemBuilder: (context, index) {
                                return Container(
                                  color: Colors.transparent,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Bottom Action Bar
        Padding(
          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ReviewIconButton(
                icon: Icons.arrow_back,
                onPressed: _goToPrevious,
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: NeoButton(
                    color: const Color(0xFFFFD166),
                    borderRadius: AppDimensions.radiusXl,
                    padding: EdgeInsets.zero,
                    shadowOffset: 0,
                    onPressed: () async {
                      await openUrl(unreadBookmarks[currentIndex].url, context: context);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.openLink,
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(width: AppDimensions.paddingSm),
                        const Icon(Icons.arrow_outward,
                            color: Colors.black, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMd),
              _ReviewIconButton(
                icon: Icons.arrow_forward,
                onPressed: _goToNext,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Bookmark b, double cardWidth, double cardHeight) {
    final collection = b.collection.value ?? widget.collection;
    final collectionName =
        collection?.name ?? AppLocalizations.of(context)!.unsorted;
    final collectionColor = collection?.color ?? Colors.grey.shade400;
    final placeholderSize = (cardWidth * 0.16).clamp(48.0, 80.0);
    final placeholderFontSize =
        MediaQuery.textScalerOf(context).scale(placeholderSize);

    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row (favicon and domain)
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 12.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: Center(
                    child: FaviconImage(
                      domain: b.sourceDomain,
                      url: b.url,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMd),
                Expanded(
                  child: Text(
                    b.sourceDomain ?? AppLocalizations.of(context)!.unknown,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // Large image area
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(color: AppTheme.border, width: 2.0),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: b.imageUrl != null
                        ? Image.network(
                            UrlHelper.resolveImageUrl(b.imageUrl, b.url) ??
                                (b.imageUrl!.startsWith('//')
                                     ? 'https:${b.imageUrl!}'
                                     : b.imageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: placeholderSize,
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              b.title != null && b.title!.isNotEmpty
                                  ? b.title![0].toUpperCase()
                                  : '?',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: placeholderFontSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                  // Pill at bottom left
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(color: AppTheme.border, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.border,
                            offset: Offset(2.0, 2.0),
                            blurRadius: 0,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: collectionColor,
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: AppTheme.border, width: 2),
                            ),
                            child: collection != null
                                ? Center(
                                    child: Icon(
                                      IconData(
                                        collection.iconCodePoint,
                                        fontFamily: collection.iconFontFamily,
                                      ),
                                      size: 10,
                                      color: BookmarkCollection.isWhiteIconColor(collectionColor)
                                          ? Colors.white
                                          : AppTheme.border,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppDimensions.paddingSm),
                          Text(
                            collectionName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Title and description
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  b.title ?? b.url,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  b.description ?? b.url,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ReviewIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: NeoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: const Color(0xFF222222),
        borderColor: Colors.white24,
        borderWidth: 2,
        borderRadius: AppDimensions.radiusXl,
        shadowOffset: 0,
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
