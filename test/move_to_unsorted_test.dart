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
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/neo_button.dart';

class MockMoveRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<Bookmark> bookmarks = [];
  final List<BookmarkCollection> collectionsList = [];
  int updateBookmarksCallCount = 0;
  List<Bookmark> lastUpdatedBookmarks = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => List.from(collectionsList);

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collectionsList.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => List.from(collectionsList);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collectionsList.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<Bookmark?> getBookmark(Id id) async =>
      bookmarks.where((b) => b.id == id).firstOrNull;

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
    updateBookmarks([bookmark]);
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    updateBookmarksCallCount++;
    lastUpdatedBookmarks = List.from(updated);
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

Widget _buildTestApp(Widget child, [List<Override> overrides = const []]) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('MoveToCollectionModal Unsorted option tests', () {
    testWidgets('Renders Unsorted option at the top and enables moving to Unsorted', (tester) async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 1
        ..name = 'Tech'
        ..iconCodePoint = Icons.computer.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#4A90E2';
      repo.collectionsList.add(col);

      BookmarkCollection? movedTarget;
      bool onMoveInvoked = false;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MoveToCollectionModal(
                    onMove: (target) async {
                      movedTarget = target;
                      onMoveInvoked = true;
                    },
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify "Unsorted" option exists
      expect(find.byKey(const ValueKey('collection_unsorted')), findsOneWidget);
      expect(find.text('Unsorted'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);

      // Initially, bottom button says 'Move to Collection' and is disabled
      final bottomBtnFinder = find.widgetWithText(NeoButton, 'Move to Collection');
      expect(bottomBtnFinder, findsOneWidget);
      final neoBtn = tester.widget<NeoButton>(bottomBtnFinder);
      expect(neoBtn.onPressed, isNull);

      // Tap on "Unsorted"
      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();

      // Button should now say 'Move to "Unsorted"'
      expect(find.text('Move to "Unsorted"'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Tap the 'Move to "Unsorted"' button
      await tester.tap(find.text('Move to "Unsorted"'));
      await tester.pumpAndSettle();

      expect(onMoveInvoked, isTrue);
      expect(movedTarget, isNull);
    });

    testWidgets('Toggling selection between Unsorted and a collection updates label and target', (tester) async {
      final repo = MockMoveRepository();
      final col1 = BookmarkCollection()
        ..id = 1
        ..name = 'Work'
        ..iconCodePoint = Icons.work.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FF6B6B';
      repo.collectionsList.add(col1);

      BookmarkCollection? movedTarget;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MoveToCollectionModal(
                    onMove: (target) async {
                      movedTarget = target;
                    },
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Tap Work
      await tester.tap(find.byKey(const ValueKey('collection_1')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Work"'), findsOneWidget);

      // Tap Unsorted
      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Unsorted"'), findsOneWidget);

      // Tap Work again
      await tester.tap(find.byKey(const ValueKey('collection_1')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Work"'), findsOneWidget);

      // Tap Unsorted again and confirm
      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to "Unsorted"'));
      await tester.pumpAndSettle();

      expect(movedTarget, isNull);
    });

    testWidgets('Unsorted option is present even when collections list is empty', (tester) async {
      final repo = MockMoveRepository();

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const MoveToCollectionModal(),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value([])),
          ],
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collection_unsorted')), findsOneWidget);
      expect(find.text('Unsorted'), findsOneWidget);
      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.text('Create New Collection'), findsOneWidget);

      // Tap Unsorted
      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Unsorted"'), findsOneWidget);
    });

    testWidgets('Moves single bookmark to Unsorted via BookmarkNotifier when onMove is null', (tester) async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 10
        ..name = 'Reading'
        ..iconCodePoint = Icons.book.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FFD166';
      repo.collectionsList.add(col);

      final bookmark = Bookmark()
        ..id = 42
        ..url = 'https://flutter.dev'
        ..title = 'Flutter';
      bookmark.collection.value = col;
      repo.bookmarks.add(bookmark);

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MoveToCollectionModal(
                    bookmark: bookmark,
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Move to "Unsorted"'));
      await tester.pumpAndSettle();

      expect(bookmark.collection.value, isNull);
      expect(repo.updateBookmarksCallCount, 1);
    });

    testWidgets('Moves multiple bookmarks to Unsorted in batch via BookmarkNotifier', (tester) async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 5
        ..name = 'Articles'
        ..iconCodePoint = Icons.article.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#06D6A0';
      repo.collectionsList.add(col);

      final b1 = Bookmark()
        ..id = 101
        ..url = 'https://a.com'
        ..title = 'A';
      b1.collection.value = col;

      final b2 = Bookmark()
        ..id = 102
        ..url = 'https://b.com'
        ..title = 'B';
      b2.collection.value = col;

      repo.bookmarks.addAll([b1, b2]);

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MoveToCollectionModal(
                    bookmarks: [b1, b2],
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('collection_unsorted')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Move to "Unsorted"'));
      await tester.pumpAndSettle();

      expect(b1.collection.value, isNull);
      expect(b2.collection.value, isNull);
      expect(repo.updateBookmarksCallCount, 1);
      expect(repo.lastUpdatedBookmarks.length, 2);
    });

    test('BookmarkNotifier.moveToCollection(bookmark, null) invalidates providers and unlinks collection', () async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 88
        ..name = 'Source Col'
        ..colorHex = '#4A90E2';
      repo.collectionsList.add(col);

      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://test.com'
        ..title = 'Test';
      bookmark.collection.value = col;
      repo.bookmarks.add(bookmark);

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      int colUpdates = 0;
      int unsortedUpdates = 0;
      int bookmarksUpdates = 0;

      await container.read(collectionBookmarksProvider(88).future);
      await container.read(unsortedBookmarksProvider.future);
      await container.read(bookmarksProvider.future);

      container.listen(collectionBookmarksProvider(88), (_, __) => colUpdates++, fireImmediately: false);
      container.listen(unsortedBookmarksProvider, (_, __) => unsortedUpdates++, fireImmediately: false);
      container.listen(bookmarksProvider, (_, __) => bookmarksUpdates++, fireImmediately: false);

      await container.read(bookmarkNotifierProvider.notifier).moveToCollection(bookmark, null);
      await container.pump();

      expect(bookmark.collection.value, isNull);
      expect(repo.updateBookmarksCallCount, 1);
      expect(colUpdates, 1);
      expect(unsortedUpdates, 1);
      expect(bookmarksUpdates, 1);
    });

    test('BookmarkNotifier.removeFromCollection and removeBookmarksFromCollection delegate to null move', () async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 99
        ..name = 'Temp'
        ..colorHex = '#FF6B6B';
      final b1 = Bookmark()..id = 1..url = 'https://1.com'..title = '1';
      b1.collection.value = col;
      final b2 = Bookmark()..id = 2..url = 'https://2.com'..title = '2';
      b2.collection.value = col;
      repo.bookmarks.addAll([b1, b2]);

      final container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(bookmarkNotifierProvider.notifier).removeFromCollection(b1);
      expect(b1.collection.value, isNull);

      await container.read(bookmarkNotifierProvider.notifier).removeBookmarksFromCollection([b2]);
      expect(b2.collection.value, isNull);
    });
  });
}
