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
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks.where((b) => !b.isRead).toList();

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
  testWidgets('ReviewModeScreen does not inflate completedCount on backward navigation', (tester) async {
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
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([bookmark1, bookmark2, bookmark3])),
        ],
        child: buildTestApp(
          home: const ReviewModeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify first bookmark is displayed: "01 / 03"
    expect(find.text('Bookmark 1'), findsOneWidget);
    expect(find.text('01'), findsOneWidget); // 01 / 03

    // Find the next arrow button (Icons.arrow_forward)
    final nextButtonFinder = find.widgetWithIcon(GestureDetector, Icons.arrow_forward);
    final previousButtonFinder = find.widgetWithIcon(GestureDetector, Icons.arrow_back);

    // Tap next to review bookmark 1 and move to bookmark 2
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 2'), findsOneWidget);
    // Bookmark 1 should now be marked as read
    expect(bookmark1.isRead, isTrue);
    expect(bookmark2.isRead, isFalse);

    // Now tap previous button to go back to bookmark 1
    await tester.tap(previousButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 1'), findsOneWidget);

    // Tap next again to go to bookmark 2
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 2'), findsOneWidget);

    // Tap next to review bookmark 2 and move to bookmark 3
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 3'), findsOneWidget);
    expect(bookmark2.isRead, isTrue);

    // Tap next on last card (bookmark 3) -> moves to caught-up screen
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    // Now we should be on caught-up screen
    expect(find.text("You're all caught up!"), findsOneWidget);
    // completedCount should be exactly 3 (Viewed 3), not inflated by navigating backwards
    expect(find.text('Viewed 3'), findsOneWidget);

    // Tap previous button on caught-up screen
    final caughtUpPreviousButton = find.text('Previous');
    expect(caughtUpPreviousButton, findsOneWidget);
    await tester.tap(caughtUpPreviousButton);
    await tester.pumpAndSettle();

    // Returns to bookmark 3
    expect(find.text('Bookmark 3'), findsOneWidget);

    // Tap next again to complete review
    await tester.tap(nextButtonFinder);
    await tester.pumpAndSettle();

    // Caught up screen should still show exactly 3 viewed, never > 3
    expect(find.text('Viewed 3'), findsOneWidget);
  });

  testWidgets('ReviewModeScreen backward swipe does not apply action or inflate count', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark1 = Bookmark()
      ..id = 10
      ..url = 'https://example.com/10'
      ..title = 'Bookmark 10'
      ..isRead = false;
    final bookmark2 = Bookmark()
      ..id = 20
      ..url = 'https://example.com/20'
      ..title = 'Bookmark 20'
      ..isRead = false;

    fakeRepo.bookmarks.addAll([bookmark1, bookmark2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([bookmark1, bookmark2])),
        ],
        child: buildTestApp(
          home: const ReviewModeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bookmark 10'), findsOneWidget);

    // Swipe left (forward) from bookmark 10 to bookmark 20
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 20'), findsOneWidget);
    expect(bookmark1.isRead, isTrue);
    expect(bookmark2.isRead, isFalse);

    // Swipe right (backward) from bookmark 20 to bookmark 10
    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 10'), findsOneWidget);
    // Backward swipe must not mark bookmark 20 as read
    expect(bookmark2.isRead, isFalse);

    // Swipe left (forward) back to bookmark 20
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Bookmark 20'), findsOneWidget);

    // Swipe left (forward) off bookmark 20 into trailing page
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text("You're all caught up!"), findsOneWidget);
    expect(find.text('Viewed 2'), findsOneWidget);
    expect(bookmark2.isRead, isTrue);
  });

  testWidgets('ReviewModeScreen collection badge has neo-brutalist shadow', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark1 = Bookmark()
      ..id = 1
      ..url = 'https://example.com/1'
      ..title = 'Bookmark 1'
      ..isRead = false;

    fakeRepo.bookmarks.add(bookmark1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([bookmark1])),
        ],
        child: buildTestApp(
          home: const ReviewModeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find the collection badge container (contains "Unsorted")
    final badgeTextFinder = find.text('Unsorted');
    expect(badgeTextFinder, findsOneWidget);

    final containerFinder = find.ancestor(
      of: badgeTextFinder,
      matching: find.byType(Container),
    );

    // Verify the decoration has the 2.0 offset drop shadow and matches button padding
    bool hasMatchingShadow = false;
    bool hasMatchingPadding = false;
    for (final element in containerFinder.evaluate()) {
      final widget = element.widget as Container;
      if (widget.padding == const EdgeInsets.symmetric(horizontal: 20, vertical: 6)) {
        hasMatchingPadding = true;
      }
      if (widget.decoration is BoxDecoration) {
        final boxDec = widget.decoration as BoxDecoration;
        if (boxDec.boxShadow != null &&
            boxDec.boxShadow!.any((s) => s.offset == const Offset(2.0, 2.0))) {
          hasMatchingShadow = true;
        }
      }
    }

    expect(hasMatchingShadow, isTrue);
    expect(hasMatchingPadding, isTrue);
  });
}
