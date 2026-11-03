import 'dart:math' as math;
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
import '../widgets/bookmark_image.dart';
import 'package:save_later/config/app_constants.dart';

/// Emil Kowalski's custom ease curve for crisp, physical button transitions.
const Curve emilEaseOut = Cubic(0.23, 1.0, 0.32, 1.0);

/// Apple-style spring scroll physics combining page snapping,
/// fluid boundary rubber-band overscroll damping, and momentum flick dismissal.
class ReviewDeckScrollPhysics extends ScrollPhysics {
  const ReviewDeckScrollPhysics({super.parent});

  /// Apple's { duration: 0.5, bounce: 0.18 } spring physics parameters.
  static const SpringDescription appleSpring = SpringDescription(
    mass: 1.0,
    stiffness: 120.0,
    damping: 14.0,
  );

  /// Flick velocity threshold to trigger card advance (~600-800 dp/s).
  static const double flickThreshold = 700.0;

  @override
  ReviewDeckScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ReviewDeckScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => appleSpring;

  @override
  Tolerance toleranceFor(ScrollMetrics metrics) {
    return Tolerance(
      velocity: flickThreshold,
      distance: 1.0 / metrics.devicePixelRatio,
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) {
      return offset;
    }

    final double overscrollPastStart =
        math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast =
        math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? _frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : _frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _frictionFactor(double overscrollFraction) {
    return 0.52 * math.pow(1 - overscrollFraction.clamp(0.0, 1.0), 2);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) {
        return absDelta * gamma;
      }
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta * gamma;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);
    if (position.outOfRange) {
      final double end = position.pixels < position.minScrollExtent
          ? position.minScrollExtent
          : position.maxScrollExtent;
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity,
        tolerance: tolerance,
      );
    }
    if (parent != null) {
      return parent!.createBallisticSimulation(position, velocity);
    }
    // Standalone fallback when instantiated without PageScrollPhysics parent:
    final double page = position is PageMetrics
        ? position.page!
        : position.pixels /
            (position.viewportDimension == 0 ? 1 : position.viewportDimension);
    double targetPage = page;
    if (velocity < -tolerance.velocity) {
      targetPage -= 0.5;
    } else if (velocity > tolerance.velocity) {
      targetPage += 0.5;
    }
    final double targetPixels =
        targetPage.roundToDouble() * position.viewportDimension;
    if (targetPixels != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        targetPixels,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}

class ReviewModeScreen extends ConsumerStatefulWidget {
  final BookmarkCollection? collection;
  const ReviewModeScreen({super.key, this.collection});

  @visibleForTesting
  static List<CardTransformData> calculateCardTransforms({
    required double page,
    required double cardWidth,
    required int totalCards,
    int? dragStartPage,
    int currentIndex = 0,
  }) {
    if (totalCards == 0) return const [];

    final k = page.floor();
    final frac = page - k;
    final isAtRest = frac.abs() < 0.0001;

    final isBackward = !isAtRest &&
        ((dragStartPage != null && dragStartPage == k + 1) ||
            (dragStartPage == null && currentIndex == k + 1));

    final List<CardTransformData> list = [];

    void addCard(int idx, double dx, double scale, double dim, double angle, int zIndex) {
      if (idx < 0 || idx >= totalCards) return;
      list.add(CardTransformData(
        index: idx,
        dx: dx,
        scale: scale,
        dim: dim.clamp(0.0, 1.0),
        angle: angle,
        zIndex: zIndex,
      ));
    }

    // Handle boundary overscroll before card 0 with elastic rubber-band damping
    if (page < 0.0) {
      final overscroll = -page;
      final dampedDx = cardWidth * 0.35 * (1.0 - math.exp(-overscroll * 1.5));
      final angle = (overscroll * 0.04).clamp(-0.06, 0.06);
      addCard(0, dampedDx, 1.0, 0.0, angle, 10);
      addCard(1, 28.0, 0.94, 0.38, 0.0, 8);
      addCard(2, 28.0, 0.94, 0.38, 0.0, 4);
      addCard(3, 28.0, 0.94, 0.38, 0.0, 2);
      list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      return list;
    }

    // Handle boundary overscroll past last card with elastic rubber-band damping
    if (page > totalCards - 1) {
      final lastIndex = totalCards - 1;
      final overscroll = page - lastIndex;
      final dampedDx = -cardWidth * 0.35 * (1.0 - math.exp(-overscroll * 1.5));
      final angle = -(overscroll * 0.04).clamp(-0.06, 0.06);
      addCard(lastIndex, dampedDx, 1.0, 0.0, angle, 10);
      addCard(lastIndex - 1, -28.0, 0.94, 0.38, 0.0, 7);
      addCard(lastIndex - 2, -28.0, 0.94, 0.38, 0.0, 3);
      addCard(lastIndex - 3, -28.0, 0.94, 0.38, 0.0, 2);
      list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      return list;
    }

    final t = frac;
    final arc = cardWidth * 0.55;

    if (isAtRest) {
      // Resting on card k:
      // Active card k is fully white, scaled 1.0, centered.
      // Next card k+1 and previous card k-1 peek out by 28dp, scaled 0.94, with a 38% dim overlay.
      // All cards are 100% opaque (NO see-through transparency).
      // Cards k+2 and k-2 sit directly behind k+1 and k-1 so they don't peek out or bleed through.
      addCard(k, 0.0, 1.0, 0.0, 0.0, 10);
      addCard(k + 1, 28.0, 0.94, 0.38, 0.0, 8);
      addCard(k + 2, 28.0, 0.94, 0.38, 0.0, 4);
      addCard(k - 1, -28.0, 0.94, 0.38, 0.0, 7);
      addCard(k - 2, -28.0, 0.94, 0.38, 0.0, 3);
    } else if (!isBackward) {
      // Forward swipe: moving from k towards k + 1
      // Card k is swiped outward with parting arc and tilts counter-clockwise,
      // continuously settling into left stack at -28.0 with scale 0.94, dim 0.38, zIndex 7.
      final dxK = -28.0 * t - arc * math.sin(math.pi * t);
      final scaleK = 1.0 - (t * 0.06);
      final dimK = t * 0.38;
      final angleK = -math.sin(math.pi * t) * 0.07;
      final zK = t < 0.5 ? 10 : 7;
      addCard(k, dxK, scaleK, dimK, angleK, zK);

      // Card k + 1 is moving from right stack (+28) into center (0)
      final dxNext = (1.0 - t) * 28.0;
      final scaleNext = 0.94 + (t * 0.06);
      final dimNext = (1.0 - t) * 0.38;
      final angleNext = math.sin(math.pi * t) * 0.05;
      final zNext = t < 0.5 ? 8 : 10;
      addCard(k + 1, dxNext, scaleNext, dimNext, angleNext, zNext);

      // Background cards: keep constant z-index so they never pop in front or flicker on slow reverse
      addCard(k + 2, 28.0, 0.94, 0.38, 0.0, 4);
      addCard(k + 3, 28.0, 0.94, 0.38, 0.0, 2);
      addCard(k - 1, -28.0, 0.94, 0.38, 0.0, 3);
      addCard(k - 2, -28.0, 0.94, 0.38, 0.0, 2);
    } else {
      // Backward swipe: moving from k + 1 towards k
      final progress = (k + 1) - page; // in [0.0, 1.0] as page goes from k+1 to k

      // Card k + 1 is the active card sliding outward to the right with parting arc and clockwise tilt,
      // continuously settling into right stack at +28.0 with scale 0.94, dim 0.38, zIndex 8.
      final dxActive = 28.0 * progress + arc * math.sin(math.pi * progress);
      final scaleActive = 1.0 - (progress * 0.06);
      final dimActive = progress * 0.38;
      final angleActive = math.sin(math.pi * progress) * 0.07;
      final zActive = progress < 0.5 ? 10 : 8;
      addCard(k + 1, dxActive, scaleActive, dimActive, angleActive, zActive);

      // Card k is the previous card expanding from -28 into center 0
      final dxPrev = -28.0 * (1.0 - progress);
      final scalePrev = 0.94 + (progress * 0.06);
      final dimPrev = (1.0 - progress) * 0.38;
      final anglePrev = -math.sin(math.pi * progress) * 0.05;
      final zPrev = progress < 0.5 ? 7 : 10;
      addCard(k, dxPrev, scalePrev, dimPrev, anglePrev, zPrev);

      // Background cards: keep constant z-index so they never pop in front or flicker on slow reverse
      addCard(k - 1, -28.0, 0.94, 0.38, 0.0, 3);
      addCard(k - 2, -28.0, 0.94, 0.38, 0.0, 2);
      addCard(k + 2, 28.0, 0.94, 0.38, 0.0, 4);
      addCard(k + 3, 28.0, 0.94, 0.38, 0.0, 2);
    }

    // Sort by zIndex ascending (lowest zIndex painted first, highest painted on top)
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

@visibleForTesting
class CardTransformData {
  final int index;
  final double dx;
  final double scale;
  final double dim;
  final double angle;
  final int zIndex;

  const CardTransformData({
    required this.index,
    required this.dx,
    required this.scale,
    required this.dim,
    required this.angle,
    required this.zIndex,
  });
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentIndexNotifier;
  int currentIndex = 0;
  List<Bookmark> unreadBookmarks = [];
  bool loaded = false;
  final Set<int> _reviewedBookmarkIds = {};
  final Set<int> _pendingReadBookmarkIds = {};
  int get completedCount => _reviewedBookmarkIds.length;
  int? _dragStartPage;
  late final BookmarkNotifier _bookmarkNotifier;

  final Map<int, Widget> _cachedCards = {};
  double? _cachedCardWidth;
  double? _cachedCardHeight;

  Widget _getCardWidget(Bookmark b, double cardWidth, double cardHeight) {
    if (_cachedCardWidth != cardWidth || _cachedCardHeight != cardHeight) {
      _cachedCards.clear();
      _cachedCardWidth = cardWidth;
      _cachedCardHeight = cardHeight;
    }
    return _cachedCards.putIfAbsent(b.id, () {
      return RepaintBoundary(
        child: _buildCard(b, cardWidth, cardHeight),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _currentIndexNotifier = ValueNotifier<int>(0);
    _bookmarkNotifier = ref.read(bookmarkNotifierProvider.notifier);
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
          // Collections and Unsorted are repeatable review folders: show all bookmarks.
          unreadBookmarks = list;
          loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _flushPendingReadActions();
    _currentIndexNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _applyAction(Bookmark bookmark) {
    _reviewedBookmarkIds.add(bookmark.id);
    _pendingReadBookmarkIds.add(bookmark.id);
  }

  void _flushPendingReadActions() {
    if (_pendingReadBookmarkIds.isEmpty) return;
    final idsToFlush = _pendingReadBookmarkIds.toSet();
    _pendingReadBookmarkIds.clear();

    final notifier = _bookmarkNotifier;
    final bookmarksToMark = unreadBookmarks
        .where((b) => idsToFlush.contains(b.id))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        try {
          for (final bookmark in bookmarksToMark) {
            await notifier.markAsRead(bookmark);
          }
        } catch (e, st) {
          debugPrint('Error flushing pending read actions: $e\n$st');
        }
      });
    });
  }

  void _onPageChanged(int nextIndex) {
    final previousIndex = currentIndex;
    if (nextIndex == previousIndex || previousIndex >= unreadBookmarks.length) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
    });

    // Backward navigation (swipe or button) to an earlier card is purely navigation;
    // do not mark as read or increment counts when looking back at a card.
    if (nextIndex < previousIndex) {
      currentIndex = nextIndex;
      _currentIndexNotifier.value = nextIndex;
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
      _flushPendingReadActions();
      setState(() {
        currentIndex = unreadBookmarks.length;
        _currentIndexNotifier.value = unreadBookmarks.length;
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

      currentIndex = nextIndex;
      _currentIndexNotifier.value = nextIndex;
    }
  }

  void _goToNext() {
    if (currentIndex >= unreadBookmarks.length) return;
    _dragStartPage = currentIndex;
    if (currentIndex == unreadBookmarks.length - 1) {
      _applyAction(unreadBookmarks[currentIndex]);
      _flushPendingReadActions();
      setState(() {
        currentIndex = unreadBookmarks.length;
        _currentIndexNotifier.value = unreadBookmarks.length;
      });
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: emilEaseOut,
    );
  }

  void _goToPrevious() {
    if (currentIndex <= 0 || !_pageController.hasClients) return;
    _dragStartPage = currentIndex;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 240),
      curve: emilEaseOut,
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
      _dragStartPage = _pageController.hasClients && _pageController.page != null
          ? _pageController.page!.round()
          : currentIndex;
      _flushPendingReadActions();
    }
    return false;
  }

  List<CardTransformData> _calculateCardTransforms(
    double page,
    double cardWidth,
    int totalCards,
  ) {
    return ReviewModeScreen.calculateCardTransforms(
      page: page,
      cardWidth: cardWidth,
      totalCards: totalCards,
      dragStartPage: _dragStartPage,
      currentIndex: currentIndex,
    );
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
          padding: EdgeInsets.fromLTRB(AppDimensions.paddingLg, 24.0, AppDimensions.paddingLg, 24.0 + bottomInset),
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
                          _currentIndexNotifier.value = previousIndex;
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
                      _flushPendingReadActions();
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
    final l10n = AppLocalizations.of(context);
    final reviewTitle =
        (widget.collection?.name ?? l10n?.unsorted ?? 'Unsorted').toUpperCase();

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg, vertical: 24.0),
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
                  ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (context, current, _) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            (current + 1).toString().padLeft(2, '0'),
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
                      );
                    },
                  ),
                ],
              ),
              SizedBox(
                width: 45,
                height: 45,
                child: NeoButton(
                  onPressed: () {
                    _flushPendingReadActions();
                    context.pop();
                  },
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
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg),
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, current, _) {
              return Row(
                children: List.generate(unreadBookmarks.length, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: emilEaseOut,
                      height: 8,
                      margin: EdgeInsets.only(
                          right: index == unreadBookmarks.length - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index <= current
                            ? const Color(0xFFFFD166)
                            : const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              );
            },
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
                                    final matrix = Matrix4.identity()
                                      ..translate(data.dx, 0.0)
                                      ..rotateZ(data.angle)
                                      ..scale(data.scale, data.scale);

                                    return Transform(
                                      key: ValueKey<int>(data.index),
                                      transform: matrix,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: cardWidth,
                                        height: cardHeight,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            _getCardWidget(
                                              unreadBookmarks[data.index],
                                              cardWidth,
                                              cardHeight,
                                            ),
                                            if (data.dim > 0.001)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: data.dim),
                                                      borderRadius: BorderRadius.circular(26),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
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
                              physics: const ReviewDeckScrollPhysics(),
                              itemBuilder: (context, index) {
                                return const SizedBox.expand();
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
          padding: EdgeInsets.fromLTRB(AppDimensions.paddingLg, 24.0, AppDimensions.paddingLg, 24.0 + bottomInset),
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
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (context, current, _) {
                      return NeoButton(
                        color: const Color(0xFFFFD166),
                        borderRadius: AppDimensions.radiusXl,
                        padding: EdgeInsets.zero,
                        shadowOffset: 0,
                        onPressed: () async {
                          if (current < unreadBookmarks.length) {
                            await openUrl(unreadBookmarks[current].url,
                                context: context);
                          }
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
                      );
                    },
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

  Widget _buildCard(
    Bookmark b,
    double cardWidth,
    double cardHeight,
  ) {
    final collection = b.collection.value ?? widget.collection;
    final collectionName =
        collection?.name ?? AppLocalizations.of(context)!.unsorted;
    final collectionColor = collection?.color ?? const Color(0xFFE5E5E5);
    final placeholderFontSize =
        MediaQuery.textScalerOf(context)
            .scale((cardWidth * 0.16).clamp(48.0, 80.0));

    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row (favicon and domain)
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 12.0),
            child: Row(
              children: [
                FaviconImage(
                  domain: b.sourceDomain,
                  url: b.url,
                  size: 26,
                  borderRadius: 6,
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
                    child: BookmarkImage(
                      imageUrl: b.imageUrl,
                      url: b.url,
                      fallback: Center(
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
                  ),
                  // Pill at bottom left
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                          ),
                          const SizedBox(width: 6),
                          Text(
                            collectionName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
