import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../../theme/app_theme.dart';

class ReviewModeScreen extends ConsumerStatefulWidget {
  const ReviewModeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReviewModeScreen> createState() => _ReviewModeScreenState();
}

class _ReviewModeScreenState extends ConsumerState<ReviewModeScreen> {
  final CardSwiperController controller = CardSwiperController();
  int currentIndex = 0;

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
    List<Bookmark> unreadBookmarks,
  ) {
    if (direction == CardSwiperDirection.right) {
      // Mark as read / Archive
      ref.read(bookmarkNotifierProvider.notifier).markAsRead(unreadBookmarks[previousIndex]);
    }
    
    setState(() {
      this.currentIndex = currentIndex ?? unreadBookmarks.length;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Review'),
      ),
      body: bookmarksAsync.when(
        data: (bookmarks) {
          final unread = bookmarks.where((b) => !b.isRead).toList();

          if (unread.isEmpty || currentIndex >= unread.length) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, size: 100, color: AppTheme.secondary),
                  SizedBox(height: 24),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentIndex + 1} / ${unread.length}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: LinearProgressIndicator(
                          value: (currentIndex + 1) / unread.length,
                          color: AppTheme.primary,
                          backgroundColor: Colors.white,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: CardSwiper(
                  controller: controller,
                  cardsCount: unread.length,
                  onSwipe: (prev, current, direction) => _onSwipe(prev, current, direction, unread),
                  numberOfCardsDisplayed: unread.length > 2 ? 3 : unread.length,
                  backCardOffset: const Offset(0, -40),
                  padding: const EdgeInsets.all(24.0),
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    final b = unread[index];
                    return GestureDetector(
                      onTap: () {
                        context.push('/bookmark/${b.id}', extra: b);
                      },
                      child: NeoBox(
                        padding: EdgeInsets.zero,
                        color: AppTheme.cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (b.imageUrl != null)
                              Expanded(
                                flex: 3,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                  child: Image.network(
                                    b.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported, size: 64)),
                                  ),
                                ),
                              ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.title ?? b.url,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    if (b.sourceDomain != null)
                                      Text(
                                        b.sourceDomain!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.border.withOpacity(0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: Text(
                  'Swipe right to archive, left to skip',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
