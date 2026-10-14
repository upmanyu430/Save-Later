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
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';

class FakeIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => [];

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => [];

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<List<Bookmark>> getBookmarks() async => [];

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => [];

  @override
  Future<void> addBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {}

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

void main() {
  testWidgets('Top bar hides on scroll down, stays hidden during upward scroll mid-card, and only reappears at top', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example Title'
      ..description = 'A very long description ' * 20
      ..tags = ['test', 'dev']
      ..notes = 'Some notes ' * 20;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BookmarkDetailScreen(bookmark: bookmark),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify top bar initially visible
    final slideFinder = find.byType(AnimatedSlide);
    expect(slideFinder, findsOneWidget);
    AnimatedSlide slideWidget = tester.widget<AnimatedSlide>(slideFinder);
    expect(slideWidget.offset, Offset.zero);

    // Scroll down by 200px
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();

    // Top bar should now be hidden (offset (0, -1.3))
    slideWidget = tester.widget<AnimatedSlide>(slideFinder);
    expect(slideWidget.offset, const Offset(0, -1.3));

    // Swipe up in the middle of the card (scroll up by 50px, finger moves down by 50px)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 50));
    await tester.pumpAndSettle();

    // Top bar should STILL be hidden (still at pixels ~150 > 20)
    slideWidget = tester.widget<AnimatedSlide>(slideFinder);
    expect(slideWidget.offset, const Offset(0, -1.3));

    // Another upward scroll mid-card (scroll up by 50px, pixels now ~100 > 20)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 50));
    await tester.pumpAndSettle();

    // Top bar should STILL be hidden
    slideWidget = tester.widget<AnimatedSlide>(slideFinder);
    expect(slideWidget.offset, const Offset(0, -1.3));

    // Now scroll all the way back to the top (drag down by 150px to reach pixels <= 20)
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
    await tester.pumpAndSettle();

    // Top bar should now be visible again
    slideWidget = tester.widget<AnimatedSlide>(slideFinder);
    expect(slideWidget.offset, Offset.zero);
  });
}
