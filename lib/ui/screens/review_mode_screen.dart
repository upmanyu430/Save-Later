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
import '../../theme/app_theme.dart';
import '../../utils/url_launcher.dart';
import 'package:save_later/config/app_constants.dart';

class ReviewModeScreen extends ConsumerStatefulWidget {
  final BookmarkCollection? collection;
  const ReviewModeScreen({super.key, this.collection});

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen> {
  late final PageController _pageController;
  int currentIndex = 0;
  List<Bookmark> unreadBookmarks = [];
  bool loaded = false;
  int completedCount = 0;
  bool? _pendingReadAction;
  bool _pendingPreviousNavigation = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _applyAction(Bookmark bookmark, {required bool markRead}) {
    final notifier = ref.read(bookmarkNotifierProvider.notifier);
    // Reviewing a card must never delete the saved bookmark. Both swipe
    // directions complete the review by marking it as read; deletion remains
    // available from the bookmark's own actions.
    notifier.markAsRead(bookmark);
  }

  void _onPageChanged(int nextIndex) {
    final previousIndex = currentIndex;
    if (nextIndex == previousIndex || previousIndex >= unreadBookmarks.length)
      return;

    // The bottom-left arrow is navigation, not a swipe action. Do not mark
    // or delete the current bookmark when it returns to the previous card.
    if (_pendingPreviousNavigation && nextIndex < previousIndex) {
      _pendingPreviousNavigation = false;
      _pendingReadAction = null;
      setState(() {
        currentIndex = nextIndex;
      });
      return;
    }
    _pendingPreviousNavigation = false;

    // PageView has one trailing page so the final bookmark can be swiped
    // away naturally. Reaching that page completes the last bookmark and
    // lets the parent rebuild into the caught-up state.
    if (nextIndex == unreadBookmarks.length ||
        previousIndex == unreadBookmarks.length - 1) {
      final markRead = _pendingReadAction ?? nextIndex < previousIndex;
      _pendingReadAction = null;
      _applyAction(unreadBookmarks[previousIndex], markRead: markRead);
      setState(() {
        currentIndex = unreadBookmarks.length;
        completedCount++;
      });
      return;
    }

    // A swipe completes the current card. The bookmark is retained and marked
    // as read regardless of swipe direction.
    final markRead = _pendingReadAction ?? nextIndex < previousIndex;
    _pendingReadAction = null;
    _applyAction(unreadBookmarks[previousIndex], markRead: markRead);

    setState(() {
      currentIndex = nextIndex;
      completedCount++;
    });
  }

  void _goToNext({required bool markRead}) {
    if (currentIndex >= unreadBookmarks.length) return;
    _pendingReadAction = markRead;
    if (currentIndex == unreadBookmarks.length - 1) {
      _applyAction(unreadBookmarks[currentIndex], markRead: markRead);
      setState(() {
        currentIndex = unreadBookmarks.length;
        completedCount++;
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
    _pendingReadAction = null;
    _pendingPreviousNavigation = true;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
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
        child:
            isDone ? _buildCaughtUp(bottomInset) : _buildReviewUI(bottomInset),
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
                child: NeoButton(
                  color: Colors.white,
                  borderRadius: 16,
                  shadowOffset: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (completedCount > 0 && unreadBookmarks.isNotEmpty) {
                      final previousIndex = (currentIndex - 1)
                          .clamp(
                            0,
                            unreadBookmarks.length - 1,
                          )
                          .toInt();
                      setState(() {
                        currentIndex = previousIndex;
                        completedCount--;
                      });
                      _pendingReadAction = null;
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
                      const Icon(Icons.arrow_back, color: Colors.black),
                      const SizedBox(width: AppDimensions.paddingSm),
                      Flexible(
                          child: Text(AppLocalizations.of(context)!.previous,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingLg),
              Expanded(
                child: NeoButton(
                  color: const Color(0xFFFFD166),
                  borderRadius: 16,
                  shadowOffset: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go('/');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_outlined, color: Colors.black),
                      const SizedBox(width: AppDimensions.paddingSm),
                      Flexible(
                          child: Text(AppLocalizations.of(context)!.done,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis)),
                    ],
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
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingMd),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
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
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                      right: index == unreadBookmarks.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= currentIndex
                        ? const Color(0xFFFFD166)
                        : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
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
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 56.0, vertical: 32.0),
                child: PageView.builder(
                  controller: _pageController,
                  // The extra trailing page makes the last left swipe
                  // produce an onPageChanged event instead of stopping on
                  // the final card.
                  itemCount: unreadBookmarks.length + 1,
                  onPageChanged: _onPageChanged,
                  allowImplicitScrolling: true,
                  physics: const ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == unreadBookmarks.length) {
                      return const SizedBox.shrink();
                    }
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        final page = _pageController.hasClients &&
                                _pageController.page != null
                            ? _pageController.page!
                            : _pageController.initialPage.toDouble();
                        final difference =
                            (index - page).clamp(-1.0, 1.0).toDouble();
                        final progress = difference.abs();

                        return Transform.translate(
                          offset: Offset(difference * 18, 0),
                          child: Transform.scale(
                            scale: 1 - (progress * 0.04),
                            child: child,
                          ),
                        );
                      },
                      child: RepaintBoundary(
                        child: _buildCard(unreadBookmarks[index]),
                      ),
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
                  height: 64,
                  child: NeoButton(
                    color: const Color(0xFFFFD166),
                    borderRadius: AppDimensions.radiusXl,
                    padding: EdgeInsets.zero,
                    onPressed: () => openUrl(unreadBookmarks[currentIndex].url),
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
                onPressed: () => _goToNext(markRead: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Bookmark b) {
    final collection = b.collection.value ?? widget.collection;
    final collectionName =
        collection?.name ?? AppLocalizations.of(context)!.unsorted;
    final collectionColor = collection?.color ?? Colors.grey.shade400;
    final placeholderSize =
        (MediaQuery.sizeOf(context).width * 0.16).clamp(48.0, 80.0);
    final placeholderFontSize =
        MediaQuery.textScalerOf(context).scale(placeholderSize);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: AppTheme.border, width: 3),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.border,
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row (favicon and domain)
          Padding(
            padding: const EdgeInsets.all(20.0),
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
                  child: const Center(
                    child: Icon(Icons.web_asset_outlined,
                        color: Color(0xFF83D64D), size: 20),
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
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: b.imageUrl != null
                        ? Image.network(
                            b.imageUrl!.startsWith('//')
                                ? 'https:${b.imageUrl!}'
                                : b.imageUrl!,
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
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(color: AppTheme.border, width: 2),
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
                                      color: AppTheme.border,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppDimensions.paddingSm),
                          Text(
                            collectionName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  b.title ?? b.url,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  b.description ?? b.url,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
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

class _ReviewIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ReviewIconButton({required this.icon, required this.onPressed});

  @override
  State<_ReviewIconButton> createState() => _ReviewIconButtonState();
}

class _ReviewIconButtonState extends State<_ReviewIconButton> {
  bool _pressed = false;

  void _press() {
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
  }

  void _release() {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapCancel: _release,
      onTapUp: (_) {
        _release();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: 60,
        height: 60,
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFF333333) : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: Colors.white12, width: 2),
          boxShadow: _pressed
              ? const []
              : const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Icon(widget.icon, color: Colors.white, size: 30),
      ),
    );
  }
}
