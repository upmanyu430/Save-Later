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
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';

class BatchTestIsarRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<Bookmark> bookmarks = [];
  final List<BookmarkCollection> collectionsList = [];
  int deleteCallCount = 0;
  int deleteBookmarksCallCount = 0;
  int updateCallCount = 0;
  int updateBookmarksCallCount = 0;
  List<Id> lastDeletedIds = [];
  List<Bookmark> lastUpdatedBookmarks = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => List.from(collectionsList);

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<BookmarkCollection?> getCollection(Id id) async => null;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => List.from(collectionsList);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<Bookmark?> getBookmark(Id id) async => null;

  @override
  Future<List<Bookmark>> getBookmarks() async => List.from(bookmarks);

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async =>
      bookmarks.where((b) => b.collection.value?.id == collectionId).toList();

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async =>
      bookmarks.where((b) => b.collection.value == null).toList();

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks.add(bookmark);
  }

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    updateCallCount++;
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    updateBookmarksCallCount++;
    lastUpdatedBookmarks = List.from(updated);
  }

  @override
  Future<void> deleteBookmark(Id id) async {
    deleteCallCount++;
    bookmarks.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    deleteBookmarksCallCount++;
    lastDeletedIds = List.from(ids);
    bookmarks.removeWhere((b) => ids.contains(b.id));
  }
}

void main() {
  group('BookmarkNotifier batch operations', () {
    test('deleteBookmarks performs a single repo batch call and a single provider invalidation cycle', () async {
      final repo = BatchTestIsarRepo();
      final col = BookmarkCollection()..id = 42..name = 'Tech';

      final b1 = Bookmark()..id = 1..url = 'https://a.com'..title = 'A';
      b1.collection.value = col;
      final b2 = Bookmark()..id = 2..url = 'https://b.com'..title = 'B';
      b2.collection.value = col;
      final b3 = Bookmark()..id = 3..url = 'https://c.com'..title = 'C';
      b3.collection.value = col;

      repo.bookmarks.addAll([b1, b2, b3]);

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      int colListUpdates = 0;
      int allListUpdates = 0;

      // Prime providers and listen for changes
      await container.read(collectionBookmarksProvider(42).future);
      await container.read(bookmarksProvider.future);

      container.listen(collectionBookmarksProvider(42), (prev, next) {
        colListUpdates++;
      }, fireImmediately: false);

      container.listen(bookmarksProvider, (prev, next) {
        allListUpdates++;
      }, fireImmediately: false);

      // Perform batch delete
      await container.read(bookmarkNotifierProvider.notifier).deleteBookmarks(
        [b1, b2, b3],
        collectionId: 42,
      );
      await container.pump();

      // Repo verification
      expect(repo.deleteBookmarksCallCount, 1, reason: 'Expected 1 batch delete call');
      expect(repo.deleteCallCount, 0, reason: 'Should not call single deleteBookmark in loop');
      expect(repo.lastDeletedIds, [1, 2, 3]);
      expect(repo.bookmarks, isEmpty);

      // Provider invalidation count verification
      // A batch operation should only trigger a single re-evaluation cycle per provider
      expect(colListUpdates, 1, reason: 'collectionBookmarksProvider should only be invalidated once');
      expect(allListUpdates, 1, reason: 'bookmarksProvider should only be invalidated once');
    });

    test('moveBookmarksToCollection performs a single repo batch call and single invalidation cycle', () async {
      final repo = BatchTestIsarRepo();
      final sourceCol = BookmarkCollection()..id = 10..name = 'Source';
      final targetCol = BookmarkCollection()..id = 20..name = 'Target';

      final b1 = Bookmark()..id = 1..url = 'https://a.com'..title = 'A';
      b1.collection.value = sourceCol;
      final b2 = Bookmark()..id = 2..url = 'https://b.com'..title = 'B';
      b2.collection.value = sourceCol;

      repo.bookmarks.addAll([b1, b2]);

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      int sourceColUpdates = 0;
      int targetColUpdates = 0;
      int allListUpdates = 0;

      await container.read(collectionBookmarksProvider(10).future);
      await container.read(collectionBookmarksProvider(20).future);
      await container.read(bookmarksProvider.future);

      container.listen(collectionBookmarksProvider(10), (prev, next) {
        sourceColUpdates++;
      }, fireImmediately: false);

      container.listen(collectionBookmarksProvider(20), (prev, next) {
        targetColUpdates++;
      }, fireImmediately: false);

      container.listen(bookmarksProvider, (prev, next) {
        allListUpdates++;
      }, fireImmediately: false);

      await container.read(bookmarkNotifierProvider.notifier).moveBookmarksToCollection(
        [b1, b2],
        targetCol,
      );
      await container.pump();

      expect(repo.updateBookmarksCallCount, 1, reason: 'Expected 1 batch update call');
      expect(repo.updateCallCount, 0, reason: 'Should not call single updateBookmark in loop');
      expect(repo.lastUpdatedBookmarks.length, 2);
      expect(b1.collection.value, targetCol);
      expect(b2.collection.value, targetCol);

      expect(sourceColUpdates, 1, reason: 'Source collection provider should be invalidated once');
      expect(targetColUpdates, 1, reason: 'Target collection provider should be invalidated once');
      expect(allListUpdates, 1, reason: 'bookmarksProvider should only be invalidated once');
    });

    testWidgets('CollectionDetailScreen _deleteSelected invokes batch deleteBookmarks in single call', (WidgetTester tester) async {
      final repo = BatchTestIsarRepo();
      final col = BookmarkCollection()..id = 42..name = 'Tech';

      final b1 = Bookmark()..id = 1..url = 'https://a.com'..title = 'Link A';
      b1.collection.value = col;
      final b2 = Bookmark()..id = 2..url = 'https://b.com'..title = 'Link B';
      b2.collection.value = col;

      repo.bookmarks.addAll([b1, b2]);

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
            home: CollectionDetailScreen(collectionId: 42, collection: col),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap 'Select Links'
      await tester.tap(find.text('Select Links'));
      await tester.pumpAndSettle();

      // Tap 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Tap 'Delete' in top bar
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm dialog (tap Delete button in DeleteConfirmationDialog)
      final dialogDeleteButton = find.descendant(
        of: find.byType(DeleteConfirmationDialog),
        matching: find.text('Delete'),
      );
      expect(dialogDeleteButton, findsOneWidget);
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(repo.deleteBookmarksCallCount, 1, reason: 'Expected 1 batch delete call');
      expect(repo.deleteCallCount, 0, reason: 'Should not call deleteBookmark individually');
      expect(repo.lastDeletedIds, [1, 2]);
    });

    testWidgets('CollectionDetailScreen _moveSelected invokes batch moveBookmarksToCollection in single call', (WidgetTester tester) async {
      final repo = BatchTestIsarRepo();
      final sourceCol = BookmarkCollection()
        ..id = 42
        ..name = 'Source'
        ..colorHex = 'FF0000'
        ..iconCodePoint = 0xe123
        ..iconFontFamily = 'MaterialIcons';
      final targetCol = BookmarkCollection()
        ..id = 99
        ..name = 'Target'
        ..colorHex = '00FF00'
        ..iconCodePoint = 0xe123
        ..iconFontFamily = 'MaterialIcons';

      repo.collectionsList.addAll([sourceCol, targetCol]);

      final b1 = Bookmark()..id = 1..url = 'https://a.com'..title = 'Link A';
      b1.collection.value = sourceCol;
      final b2 = Bookmark()..id = 2..url = 'https://b.com'..title = 'Link B';
      b2.collection.value = sourceCol;

      repo.bookmarks.addAll([b1, b2]);

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
            home: CollectionDetailScreen(collectionId: 42, collection: sourceCol),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap 'Select Links'
      await tester.tap(find.text('Select Links'));
      await tester.pumpAndSettle();

      // Tap 'All'
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Tap 'Move' in top bar
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();

      // Tap Target collection
      await tester.tap(find.text('Target'));
      await tester.pumpAndSettle();

      // Tap 'Move to "Target"'
      await tester.tap(find.text('Move to "Target"'));
      await tester.pumpAndSettle();

      expect(repo.updateBookmarksCallCount, 1, reason: 'Expected 1 batch update call');
      expect(repo.updateCallCount, 0, reason: 'Should not call updateBookmark individually');
      expect(b1.collection.value, targetCol);
      expect(b2.collection.value, targetCol);
    });
  });
}
