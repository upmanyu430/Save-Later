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
import 'package:save_later/ui/widgets/pin_icon.dart';

class PinTestIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  Bookmark? lastUpdatedBookmark;
  int updateCallCount = 0;

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
  Future<void> updateBookmark(Bookmark bookmark) async {
    updateCallCount++;
    lastUpdatedBookmark = bookmark;
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    updateCallCount += updated.length;
    if (updated.isNotEmpty) {
      lastUpdatedBookmark = updated.last;
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

void main() {
  group('Bookmark pin toggle state management', () {
    test('BookmarkNotifier.togglePin toggles isPinned and invalidates providers', () async {
      final repo = PinTestIsarRepository();
      final col = BookmarkCollection()
        ..id = 42
        ..name = 'Reading'
        ..colorHex = 'FF0000'
        ..iconCodePoint = 0xe123
        ..iconFontFamily = 'MaterialIcons';

      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://flutter.dev'
        ..title = 'Flutter'
        ..isPinned = false;
      bookmark.collection.value = col;

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      int bookmarksUpdates = 0;
      int colUpdates = 0;

      await container.read(bookmarksProvider.future);
      await container.read(collectionBookmarksProvider(42).future);

      container.listen(bookmarksProvider, (prev, next) {
        bookmarksUpdates++;
      }, fireImmediately: false);

      container.listen(collectionBookmarksProvider(42), (prev, next) {
        colUpdates++;
      }, fireImmediately: false);

      // Toggle pin on
      await container.read(bookmarkNotifierProvider.notifier).togglePin(bookmark);
      await container.read(bookmarksProvider.future);
      await container.read(collectionBookmarksProvider(42).future);

      expect(bookmark.isPinned, isTrue);
      expect(repo.lastUpdatedBookmark?.isPinned, isTrue);
      expect(repo.updateCallCount, 1);
      final initialBookmarksUpdates = bookmarksUpdates;
      final initialColUpdates = colUpdates;
      expect(initialBookmarksUpdates, greaterThanOrEqualTo(1));
      expect(initialColUpdates, greaterThanOrEqualTo(1));

      // Toggle pin off
      await container.read(bookmarkNotifierProvider.notifier).togglePin(bookmark);
      await container.read(bookmarksProvider.future);
      await container.read(collectionBookmarksProvider(42).future);

      expect(bookmark.isPinned, isFalse);
      expect(repo.lastUpdatedBookmark?.isPinned, isFalse);
      expect(repo.updateCallCount, 2);
      expect(bookmarksUpdates, greaterThan(initialBookmarksUpdates));
      expect(colUpdates, greaterThan(initialColUpdates));
    });

    testWidgets('BookmarkDetailScreen pin button toggles pin via BookmarkNotifier', (WidgetTester tester) async {
      final repo = PinTestIsarRepository();
      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://flutter.dev'
        ..title = 'Flutter'
        ..isPinned = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
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

      final pinIconFinder = find.byType(PinIcon);
      expect(pinIconFinder, findsOneWidget);
      expect(tester.widget<PinIcon>(pinIconFinder).isPinned, isFalse);

      // Tap the pin button
      await tester.tap(pinIconFinder);
      await tester.pumpAndSettle();

      expect(bookmark.isPinned, isTrue);
      expect(repo.lastUpdatedBookmark?.isPinned, isTrue);
      expect(tester.widget<PinIcon>(pinIconFinder).isPinned, isTrue);
    });
  });
}
