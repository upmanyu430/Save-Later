import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/review_mode_screen.dart';
import 'package:save_later/theme/app_theme.dart';

class FakeIsarRepository implements IsarRepository {
  final List<Bookmark> bookmarks = [];

  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => [];

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<BookmarkCollection?> getCollection(Id id) async => null;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => [];

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<Bookmark?> getBookmark(Id id) async {
    try {
      return bookmarks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async =>
      bookmarks.where((b) => !b.isRead).toList();

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks.add(bookmark);
  }

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    final idx = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx != -1) {
      bookmarks[idx] = bookmark;
    }
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    for (final b in updated) {
      await updateBookmark(b);
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {
    bookmarks.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    bookmarks.removeWhere((b) => ids.contains(b.id));
  }
}

Widget buildTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: home,
  );
}

void main() {
  group('Review Mode Stack Deck & Gestures', () {
    testWidgets(
        'Test 1: Stack Layout & Card Styling at Index 0 (white bg, radius 26, 2.5px dark outer border, 2px hero border, 2px badge shadow)',
        (tester) async {
      final fakeRepo = FakeIsarRepository();
      final bookmark1 = Bookmark()
        ..id = 1
        ..url = 'https://example.com/1'
        ..title = 'Bookmark 1'
        ..isRead = false;
      final bookmark2 = Bookmark()
        ..id = 2
        ..url = 'https://example.com/2'
        ..title = 'Bookmark 2'
        ..isRead = false;
      final bookmark3 = Bookmark()
        ..id = 3
        ..url = 'https://example.com/3'
        ..title = 'Bookmark 3'
        ..isRead = false;

      fakeRepo.bookmarks.addAll([bookmark1, bookmark2, bookmark3]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider.overrideWith(
                (ref) => Future.value([bookmark1, bookmark2, bookmark3])),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Card 1 title is visible
      expect(find.text('Bookmark 1'), findsOneWidget);
      // Verify Card 2 is also built in the stack behind Card 1
      expect(find.text('Bookmark 2'), findsOneWidget);

      // Inspect main card container: white background, radius 26, NO outer border
      final mainCardFinder = find.ancestor(
        of: find.text('Bookmark 1'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).borderRadius ==
                  BorderRadius.circular(26),
        ),
      );
      expect(mainCardFinder, findsOneWidget);

      final mainCardContainer =
          tester.widget<Container>(mainCardFinder.first);
      final cardDecoration = mainCardContainer.decoration as BoxDecoration;
      expect(cardDecoration.color, equals(Colors.white));
      expect(cardDecoration.borderRadius, equals(BorderRadius.circular(26)));
      expect(cardDecoration.border, equals(Border.all(color: Colors.black, width: 2.5)));

      // Inspect hero image container: 2px inner image border
      final heroContainerFinder = find.descendant(
        of: mainCardFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border ==
                  Border.all(color: AppTheme.border, width: 2.0) &&
              (w.decoration as BoxDecoration).color == const Color(0xFF111111),
        ),
      );
      expect(heroContainerFinder, findsOneWidget);
      final heroContainer =
          tester.widget<Container>(heroContainerFinder.first);
      final heroDecoration = heroContainer.decoration as BoxDecoration;
      expect(heroDecoration.border,
          equals(Border.all(color: AppTheme.border, width: 2.0)));

      // Inspect collection badge: 2.0px drop shadow and 2.0px border
      final badgeContainerFinder = find.descendant(
        of: mainCardFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).boxShadow != null &&
              (w.decoration as BoxDecoration)
                  .boxShadow!
                  .any((s) => s.offset == const Offset(2.0, 2.0)),
        ),
      );
      expect(badgeContainerFinder, findsOneWidget);
      final badgeContainer =
          tester.widget<Container>(badgeContainerFinder.first);
      final badgeDecoration = badgeContainer.decoration as BoxDecoration;
      expect(badgeDecoration.border,
          equals(Border.all(color: AppTheme.border, width: 2.0)));
      expect(
          badgeDecoration.boxShadow!
              .any((s) => s.offset == const Offset(2.0, 2.0)),
          isTrue);
    });

    testWidgets(
        'Test 2: Stack Drag & Tilt Transform Verification (drag gesture, read tracking integrity)',
        (tester) async {
      final fakeRepo = FakeIsarRepository();
      final bookmark1 = Bookmark()
        ..id = 1
        ..url = 'https://example.com/1'
        ..title = 'Bookmark 1'
        ..isRead = false;
      final bookmark2 = Bookmark()
        ..id = 2
        ..url = 'https://example.com/2'
        ..title = 'Bookmark 2'
        ..isRead = false;
      final bookmark3 = Bookmark()
        ..id = 3
        ..url = 'https://example.com/3'
        ..title = 'Bookmark 3'
        ..isRead = false;

      fakeRepo.bookmarks.addAll([bookmark1, bookmark2, bookmark3]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider.overrideWith(
                (ref) => Future.value([bookmark1, bookmark2, bookmark3])),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bookmark 1'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);

      // Verify dragging PageView initiates card movement and changes page index
      // Start drag forward (drag left)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(PageView)));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();

      // Complete drag forward to smoothly advance from Bookmark 1 to Bookmark 2
      await gesture.moveBy(const Offset(-350, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Bookmark 2'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      // Bookmark 1 is marked as read, Bookmark 2 remains unread
      expect(bookmark1.isRead, isTrue);
      expect(bookmark2.isRead, isFalse);

      // Drag backward (drag right) to return to Bookmark 1
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Bookmark 1'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      // Bookmark 2 still remains unread after backward navigation
      expect(bookmark2.isRead, isFalse);
    });

    testWidgets(
        'Test 3: Multi-card Stack Layers at Middle Index (both left and right stacks present)',
        (tester) async {
      final fakeRepo = FakeIsarRepository();
      final bookmarks = List.generate(
        5,
        (i) => Bookmark()
          ..id = i + 1
          ..url = 'https://example.com/${i + 1}'
          ..title = 'Bookmark ${i + 1}'
          ..isRead = false,
      );

      fakeRepo.bookmarks.addAll(bookmarks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider
                .overrideWith((ref) => Future.value(bookmarks)),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder =
          find.widgetWithIcon(GestureDetector, Icons.arrow_forward);

      // Advance to bookmark 3 (index 2)
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Verify top counter shows 03 / 05
      expect(find.text('03'), findsOneWidget);
      expect(find.text(' / 05'), findsOneWidget);

      // Verify progress bar shows 3 active yellow segments out of 5 total segments
      final progressBars = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .where((w) {
        final dec = w.decoration as BoxDecoration?;
        return dec?.borderRadius == BorderRadius.circular(999);
      }).toList();
      expect(progressBars.length, equals(5));

      final activeSegments = progressBars.where((w) {
        final dec = w.decoration as BoxDecoration?;
        return dec?.color == const Color(0xFFFFD166);
      }).toList();
      expect(activeSegments.length, equals(3));

      // Verify all cards are built in the stacked deck:
      // Left stack (previous cards Bookmark 1 and 2), center (Bookmark 3), right stack (Bookmark 4 and 5)
      expect(find.text('Bookmark 1'), findsOneWidget);
      expect(find.text('Bookmark 2'), findsOneWidget);
      expect(find.text('Bookmark 3'), findsOneWidget);
      expect(find.text('Bookmark 4'), findsOneWidget);
      expect(find.text('Bookmark 5'), findsOneWidget);

      // Verify transform offsets: both negative dx (left stack) and positive dx (right stack) exist
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final dxTranslations = transforms
          .map((t) => t.transform.getTranslation().x)
          .where((dx) => dx != 0.0)
          .toList();

      final hasLeftStack = dxTranslations.any((dx) => dx < 0.0);
      final hasRightStack = dxTranslations.any((dx) => dx > 0.0);
      expect(hasLeftStack, isTrue);
      expect(hasRightStack, isTrue);
    });

    testWidgets(
        'Test 4: Button Navigation & Caught-up Flow (advance, return, and complete)',
        (tester) async {
      final fakeRepo = FakeIsarRepository();
      final bookmark1 = Bookmark()
        ..id = 1
        ..url = 'https://example.com/1'
        ..title = 'Bookmark 1'
        ..isRead = false;
      final bookmark2 = Bookmark()
        ..id = 2
        ..url = 'https://example.com/2'
        ..title = 'Bookmark 2'
        ..isRead = false;
      final bookmark3 = Bookmark()
        ..id = 3
        ..url = 'https://example.com/3'
        ..title = 'Bookmark 3'
        ..isRead = false;

      fakeRepo.bookmarks.addAll([bookmark1, bookmark2, bookmark3]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider.overrideWith(
                (ref) => Future.value([bookmark1, bookmark2, bookmark3])),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final nextButtonFinder =
          find.widgetWithIcon(GestureDetector, Icons.arrow_forward);
      final previousButtonFinder =
          find.widgetWithIcon(GestureDetector, Icons.arrow_back);

      // Verify initial state
      expect(find.text('01'), findsOneWidget);

      // Tapping next button advances through cards
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('02'), findsOneWidget);
      expect(find.text('Bookmark 2'), findsOneWidget);
      expect(bookmark1.isRead, isTrue);
      expect(bookmark2.isRead, isFalse);

      // Tapping previous button returns to prior card
      await tester.tap(previousButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('01'), findsOneWidget);
      expect(find.text('Bookmark 1'), findsOneWidget);
      expect(bookmark2.isRead, isFalse);

      // Advance again to Card 2
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('02'), findsOneWidget);

      // Advance to Card 3
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Bookmark 3'), findsOneWidget);
      expect(bookmark2.isRead, isTrue);
      expect(bookmark3.isRead, isFalse);

      // Advancing past final card presents caught-up screen with correct completion count
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up!"), findsOneWidget);
      expect(find.text('Viewed 3'), findsOneWidget);
      expect(bookmark3.isRead, isTrue);
    });

    testWidgets(
        'Test 5: Stable ValueKeys on Stack Deck Transform Elements',
        (tester) async {
      final fakeRepo = FakeIsarRepository();
      final bookmarks = List.generate(
        4,
        (i) => Bookmark()
          ..id = i + 1
          ..url = 'https://example.com/${i + 1}'
          ..title = 'Bookmark ${i + 1}'
          ..isRead = false,
      );
      fakeRepo.bookmarks.addAll(bookmarks);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider.overrideWith((ref) => Future.value(bookmarks)),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that each card transform has a stable ValueKey<int> corresponding to its bookmark index
      expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(2)), findsOneWidget);

      // Verify widget type of each key is Transform
      final transform0 = tester.widget<Transform>(find.byKey(const ValueKey<int>(0)));
      final transform1 = tester.widget<Transform>(find.byKey(const ValueKey<int>(1)));
      expect(transform0, isNotNull);
      expect(transform1, isNotNull);

      // Advance to next card
      final nextButtonFinder =
          find.widgetWithIcon(GestureDetector, Icons.arrow_forward);
      await tester.tap(nextButtonFinder);
      await tester.pumpAndSettle();

      // Keys remain stable and now include previous card (0), active card (1), and next cards (2, 3)
      expect(find.byKey(const ValueKey<int>(0)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(1)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(2)), findsOneWidget);
      expect(find.byKey(const ValueKey<int>(3)), findsOneWidget);
    });

    test(
        'Test 6: Continuous Z-Indices & Stable Card Transforms Across Page Boundaries',
        () {
      // 1. At Rest (page = 0.0)
      final atRest0 = ReviewModeScreen.calculateCardTransforms(
        page: 0.0,
        cardWidth: 300.0,
        totalCards: 5,
      );
      // Expected: Card 2 (zIndex 4), Card 1 (zIndex 8), Card 0 (zIndex 10)
      expect(atRest0.length, equals(3));
      expect(atRest0.map((c) => c.zIndex).toList(), equals([4, 8, 10]));
      final card0Rest = atRest0.firstWhere((c) => c.index == 0);
      final card1Rest = atRest0.firstWhere((c) => c.index == 1);
      final card2Rest = atRest0.firstWhere((c) => c.index == 2);
      expect(card0Rest.dx, equals(0.0));
      expect(card0Rest.scale, equals(1.0));
      expect(card0Rest.dim, equals(0.0));
      expect(card0Rest.zIndex, equals(10));
      expect(card1Rest.dx, equals(28.0));
      expect(card1Rest.scale, equals(0.94));
      expect(card1Rest.dim, equals(0.38));
      expect(card1Rest.zIndex, equals(8));
      expect(card2Rest.dx, equals(28.0));
      expect(card2Rest.zIndex, equals(4));

      // 2. Forward Swipe midpoint (page = 0.5)
      final swipeMid = ReviewModeScreen.calculateCardTransforms(
        page: 0.5,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card0Mid = swipeMid.firstWhere((c) => c.index == 0);
      final card1Mid = swipeMid.firstWhere((c) => c.index == 1);
      expect(card0Mid.dx, lessThan(0.0));
      expect(card1Mid.dx, closeTo(14.0, 0.01));
      expect(card1Mid.scale, closeTo(0.97, 0.01));

      // 3. Right before boundary (page = 0.999) - Verify continuous approach with ZERO teleportation
      final swipeEnd = ReviewModeScreen.calculateCardTransforms(
        page: 0.999,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card0End = swipeEnd.firstWhere((c) => c.index == 0);
      final card1End = swipeEnd.firstWhere((c) => c.index == 1);
      final card2End = swipeEnd.firstWhere((c) => c.index == 2);
      final card3End = swipeEnd.firstWhere((c) => c.index == 3);
      // Card 0 smoothly settles within 1dp of -28.0 (NO teleporting across 300dp)
      expect(card0End.dx, closeTo(-28.0, 1.0));
      expect(card0End.zIndex, equals(7));
      expect(card0End.scale, closeTo(0.94, 0.01));
      expect(card0End.dim, closeTo(0.38, 0.01));
      expect(card1End.dx, closeTo(0.028, 0.01));
      expect(card1End.scale, closeTo(1.0, 0.01));
      expect(card1End.zIndex, equals(10));
      expect(card2End.dx, equals(28.0));
      expect(card2End.zIndex, equals(4)); // Card 2 stays safely at background zIndex 4 without popping in front
      expect(card3End.dx, equals(28.0));
      expect(card3End.zIndex, equals(2));

      // 4. Crossing boundary to page = 1.000 (At rest at index 1)
      final atRest1 = ReviewModeScreen.calculateCardTransforms(
        page: 1.0,
        cardWidth: 300.0,
        totalCards: 5,
      );
      // Cards present: Card 3 (zIndex 4), Card 0 (zIndex 7), Card 2 (zIndex 8), Card 1 (zIndex 10)
      expect(atRest1.map((c) => c.zIndex).toList(), equals([4, 7, 8, 10]));
      final card1AtRest = atRest1.firstWhere((c) => c.index == 1);
      final card2AtRest = atRest1.firstWhere((c) => c.index == 2);
      final card0AtRest = atRest1.firstWhere((c) => c.index == 0);
      expect(card1AtRest.dx, equals(0.0));
      expect(card1AtRest.scale, equals(1.0));
      expect(card1AtRest.zIndex, equals(10));
      expect(card2AtRest.dx, equals(28.0));
      expect(card2AtRest.zIndex, equals(8));
      expect(card0AtRest.dx, equals(-28.0));
      expect(card0AtRest.zIndex, equals(7));

      // 5. Middle Index Forward Swipe (k = 2, page = 2.5) -> verify Card k-1 rests smoothly at -28.0
      final middleSwipe = ReviewModeScreen.calculateCardTransforms(
        page: 2.5,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card1InLeftStack = middleSwipe.firstWhere((c) => c.index == 1);
      final card0InLeftStack = middleSwipe.firstWhere((c) => c.index == 0);
      expect(card1InLeftStack.dx, equals(-28.0)); // Smoothly resting at -28.0, NO teleporting
      expect(card0InLeftStack.dx, equals(-28.0));

      // 6. Backward Swipe (page = 1.5, dragging back towards 1)
      final backSwipe = ReviewModeScreen.calculateCardTransforms(
        page: 1.5,
        cardWidth: 300.0,
        totalCards: 5,
        dragStartPage: 2,
        currentIndex: 2,
      );
      final card2Back = backSwipe.firstWhere((c) => c.index == 2);
      final card1Back = backSwipe.firstWhere((c) => c.index == 1);
      expect(card2Back.dx, greaterThan(0.0));
      expect(card1Back.dx, closeTo(-14.0, 0.01));
      expect(card1Back.angle, lessThan(0.0));

      // 7. Backward Drag Boundaries - Continuous tilt with zero angle pop at rest
      // Just beginning backward drag from card 2 (page = 1.999)
      final backDragStart = ReviewModeScreen.calculateCardTransforms(
        page: 1.999,
        cardWidth: 300.0,
        totalCards: 5,
        dragStartPage: 2,
        currentIndex: 2,
      );
      final card1AtBackDragStart = backDragStart.firstWhere((c) => c.index == 1);
      expect(card1AtBackDragStart.angle, closeTo(0.0, 0.001));

      // Right before landing on card 1 (page = 1.001)
      final backDragEnd = ReviewModeScreen.calculateCardTransforms(
        page: 1.001,
        cardWidth: 300.0,
        totalCards: 5,
        dragStartPage: 2,
        currentIndex: 2,
      );
      final card1AtBackDragEnd = backDragEnd.firstWhere((c) => c.index == 1);
      expect(card1AtBackDragEnd.angle, closeTo(0.0, 0.001));

      // Forward drag start from card 0 (page = 0.001)
      final forwardDragStart = ReviewModeScreen.calculateCardTransforms(
        page: 0.001,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card1AtForwardStart = forwardDragStart.firstWhere((c) => c.index == 1);
      expect(card1AtForwardStart.angle, closeTo(0.0, 0.001));
    });

    test('Test 7: Boundary Overscroll Transforms with Elastic Damping (page < 0 and page > totalCards - 1)', () {
      // 1. Overscroll before Card 0 (page = -0.5)
      final overscrollStart = ReviewModeScreen.calculateCardTransforms(
        page: -0.5,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card0 = overscrollStart.firstWhere((c) => c.index == 0);
      final card1 = overscrollStart.firstWhere((c) => c.index == 1);
      final card2 = overscrollStart.firstWhere((c) => c.index == 2);
      final card3 = overscrollStart.firstWhere((c) => c.index == 3);

      expect(card0.dx, greaterThan(0.0)); // Damped rightward offset
      expect(card0.scale, equals(1.0));
      expect(card0.dim, equals(0.0));
      expect(card0.zIndex, equals(10));
      expect(card1.dx, equals(28.0));
      expect(card1.scale, equals(0.94));
      expect(card1.dim, equals(0.38));
      expect(card1.zIndex, equals(8));
      expect(card2.dx, equals(28.0));
      expect(card2.zIndex, equals(4));
      expect(card3.dx, equals(28.0));
      expect(card3.zIndex, equals(2));
      expect(overscrollStart.map((c) => c.zIndex).toList(), equals([2, 4, 8, 10]));

      // Continuous approach at page = -0.001
      final nearZero = ReviewModeScreen.calculateCardTransforms(
        page: -0.001,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card0NearZero = nearZero.firstWhere((c) => c.index == 0);
      expect(card0NearZero.dx, closeTo(0.0, 0.2));
      expect(card0NearZero.angle, closeTo(0.0, 0.001));

      // 2. Overscroll past last card (page = 4.5 for totalCards = 5)
      final overscrollEnd = ReviewModeScreen.calculateCardTransforms(
        page: 4.5,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card4 = overscrollEnd.firstWhere((c) => c.index == 4);
      final card3Left = overscrollEnd.firstWhere((c) => c.index == 3);
      final card2Left = overscrollEnd.firstWhere((c) => c.index == 2);
      final card1Left = overscrollEnd.firstWhere((c) => c.index == 1);

      expect(card4.dx, lessThan(0.0)); // Damped leftward offset
      expect(card4.scale, equals(1.0));
      expect(card4.dim, equals(0.0));
      expect(card4.zIndex, equals(10));
      expect(card3Left.dx, equals(-28.0));
      expect(card3Left.scale, equals(0.94));
      expect(card3Left.dim, equals(0.38));
      expect(card3Left.zIndex, equals(7));
      expect(card2Left.dx, equals(-28.0));
      expect(card2Left.zIndex, equals(3));
      expect(card1Left.dx, equals(-28.0));
      expect(card1Left.zIndex, equals(2));
      expect(overscrollEnd.map((c) => c.zIndex).toList(), equals([2, 3, 7, 10]));

      // Continuous approach at page = 4.001
      final nearLast = ReviewModeScreen.calculateCardTransforms(
        page: 4.001,
        cardWidth: 300.0,
        totalCards: 5,
      );
      final card4NearLast = nearLast.firstWhere((c) => c.index == 4);
      expect(card4NearLast.dx, closeTo(0.0, 0.2));
      expect(card4NearLast.angle, closeTo(0.0, 0.001));

      // 3. Single card deck overscroll
      final singleDeckNeg = ReviewModeScreen.calculateCardTransforms(
        page: -0.2,
        cardWidth: 300.0,
        totalCards: 1,
      );
      expect(singleDeckNeg.length, equals(1));
      expect(singleDeckNeg.first.index, equals(0));
      expect(singleDeckNeg.first.dx, greaterThan(0.0));

      final singleDeckPos = ReviewModeScreen.calculateCardTransforms(
        page: 0.2,
        cardWidth: 300.0,
        totalCards: 1,
      );
      expect(singleDeckPos.length, equals(1));
      expect(singleDeckPos.first.index, equals(0));
      expect(singleDeckPos.first.dx, lessThan(0.0));
    });

    test('Test 8: ReviewDeckScrollPhysics Spring Parameters & Emil Ease Curve', () {
      expect(emilEaseOut, equals(const Cubic(0.23, 1.0, 0.32, 1.0)));

      const physics = ReviewDeckScrollPhysics();
      expect(physics.spring.mass, equals(1.0));
      expect(physics.spring.stiffness, equals(120.0));
      expect(physics.spring.damping, closeTo(21.908902300206645, 0.0001));

      final metrics = FixedScrollMetrics(
        minScrollExtent: 0.0,
        maxScrollExtent: 1000.0,
        pixels: -50.0,
        viewportDimension: 400.0,
        axisDirection: AxisDirection.right,
        devicePixelRatio: 1.0,
      );

      final tolerance = physics.toleranceFor(metrics);
      expect(tolerance.velocity, equals(700.0));

      // Boundary overscroll damping
      final dampedOffset = physics.applyPhysicsToUserOffset(metrics, -10.0);
      expect(dampedOffset.abs(), lessThan(10.0));

      // Out of range ballistic simulation springs back to edge
      final sim = physics.createBallisticSimulation(metrics, 0.0);
      expect(sim, isNotNull);
      expect(sim, isA<ScrollSpringSimulation>());
    });
  });
}
