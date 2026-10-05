import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../widgets/neo_button.dart';
import '../../theme/app_theme.dart';
import '../../utils/url_launcher.dart';

class ReviewModeScreen extends ConsumerStatefulWidget {
  final BookmarkCollection? collection;
  const ReviewModeScreen({super.key, this.collection});

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen> {
  final CardSwiperController controller = CardSwiperController();
  int currentIndex = 0;
  List<Bookmark> unreadBookmarks = [];
  bool loaded = false;
  int completedCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      List<Bookmark> list;
      if (widget.collection == null) {
        list = await ref.read(unsortedBookmarksProvider.future);
      } else {
        list = await ref.read(collectionBookmarksProvider(widget.collection!.id).future);
      }
      if (mounted) {
        setState(() {
          unreadBookmarks = list.where((b) => !b.isRead).toList();
          loaded = true;
        });
      }
    });
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // any swipe direction
    if (direction == CardSwiperDirection.right) {
      ref.read(bookmarkNotifierProvider.notifier).markAsRead(unreadBookmarks[previousIndex]);
    }
    
    setState(() {
      this.currentIndex = currentIndex ?? unreadBookmarks.length;
      completedCount++;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF111111),
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final isDone = unreadBookmarks.isEmpty || currentIndex >= unreadBookmarks.length;

    return Scaffold(
      backgroundColor: const Color(0xFF111111), // Almost black
      body: SafeArea(
        child: isDone ? _buildCaughtUp() : _buildReviewUI(),
      ),
    );
  }

  Widget _buildCaughtUp() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Checkmark circle
        Stack(
          alignment: Alignment.center,
          children: [
            // Sparkles background
            Positioned(top: 0, left: 20, child: Icon(Icons.auto_awesome, color: Colors.greenAccent.withValues(alpha: 0.8), size: 24)),
            Positioned(bottom: 10, right: 20, child: Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
            Positioned(top: 20, right: 0, child: Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
            Positioned(bottom: 0, left: 10, child: Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 28)),
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF3CD27D), // Green
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 64),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          AppLocalizations.of(context)!.caughtUpTitle,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context)!.caughtUpSubtitle,
          style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppLocalizations.of(context)!.viewedCount(completedCount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            children: [
              Expanded(
                child: NeoButton(
                  color: Colors.white,
                  onPressed: () {
                    if (completedCount > 0 && unreadBookmarks.isNotEmpty) {
                       setState(() {
                         currentIndex = currentIndex - 1;
                         completedCount--;
                       });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.previous, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NeoButton(
                  color: const Color(0xFFFFD166),
                  onPressed: () => context.go('/'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.home_outlined, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.done, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
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

  Widget _buildReviewUI() {
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
                    (widget.collection?.name ?? AppLocalizations.of(context)!.unsorted).toUpperCase(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        (currentIndex + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' / ${unreadBookmarks.length.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(16),
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
                  margin: EdgeInsets.only(right: index == unreadBookmarks.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: index <= currentIndex ? const Color(0xFFFFD166) : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        
        // Swiper
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: unreadBookmarks.length,
            onSwipe: (prev, current, direction) => _onSwipe(prev, current, direction),
            numberOfCardsDisplayed: unreadBookmarks.length > 2 ? 3 : unreadBookmarks.length,
            backCardOffset: const Offset(12, 0), // Offset to the right
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              final b = unreadBookmarks[index];
              return _buildCard(b);
            },
          ),
        ),
        
        // Bottom Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                   controller.swipe(CardSwiperDirection.left);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF222222),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () {
                     openUrl(unreadBookmarks[currentIndex].url);
                  },
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD166),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context)!.openLink, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_outward, color: Colors.black, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                   controller.swipe(CardSwiperDirection.right);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF222222),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Bookmark b) {
    final collection = b.collection.value ?? widget.collection;
    final collectionName = collection?.name ?? AppLocalizations.of(context)!.unsorted;
    final collectionColor = collection?.color ?? Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border, width: 3),
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
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.public, color: AppTheme.border, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    b.sourceDomain ?? AppLocalizations.of(context)!.unknown,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: b.imageUrl != null
                        ? Image.network(
                            b.imageUrl!.startsWith('//') ? 'https:${b.imageUrl!}' : b.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64)),
                          )
                        : Center(
                            child: Text(
                              b.title != null && b.title!.isNotEmpty ? b.title![0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white24),
                            ),
                          ),
                  ),
                  // Pill at bottom left
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                              border: Border.all(color: AppTheme.border, width: 2),
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
                          const SizedBox(width: 8),
                          Text(
                            collectionName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2, color: Colors.black),
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


