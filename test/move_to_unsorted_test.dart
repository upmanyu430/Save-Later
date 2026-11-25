import 'package:save_later/ui/widgets/collection_editor_modal.dart';
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
  group('MoveToCollectionModal Unsorted option removal tests', () {
    testWidgets('Does not render Unsorted option and enables moving to a collection', (tester) async {
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

      // Verify "Unsorted" option does NOT exist
      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);
      expect(find.text('Unsorted'), findsNothing);
      expect(find.text('Tech'), findsOneWidget);

      // Initially, bottom button says 'Move to Collection' and is disabled with exact height 56.0
      final bottomBtnFinder = find.widgetWithText(NeoButton, 'Move to Collection');
      expect(bottomBtnFinder, findsOneWidget);
      final neoBtn = tester.widget<NeoButton>(bottomBtnFinder);
      expect(neoBtn.onPressed, isNull);
      final buttonSizedBox = tester.widget<SizedBox>(
        find.ancestor(of: bottomBtnFinder, matching: find.byType(SizedBox)).first,
      );
      expect(buttonSizedBox.height, 56.0);

      // Tap on "Tech"
      await tester.tap(find.byKey(const ValueKey('collection_1')));
      await tester.pumpAndSettle();

      // Button should now say 'Move to "Tech"' without a checkmark tick
      expect(find.text('Move to "Tech"'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      // Tap the 'Move to "Tech"' button
      await tester.tap(find.text('Move to "Tech"'));
      await tester.pumpAndSettle();

      expect(onMoveInvoked, isTrue);
      expect(movedTarget?.id, 1);
    });

    testWidgets('Selecting a collection updates button label and target', (tester) async {
      final repo = MockMoveRepository();
      final col1 = BookmarkCollection()
        ..id = 1
        ..name = 'Work'
        ..iconCodePoint = Icons.work.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FF6B6B';
      final col2 = BookmarkCollection()
        ..id = 2
        ..name = 'Personal'
        ..iconCodePoint = Icons.person.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#4ECDC4';
      repo.collectionsList.addAll([col1, col2]);

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

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);

      // Tap Work
      await tester.tap(find.byKey(const ValueKey('collection_1')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Work"'), findsOneWidget);

      // Tap Personal
      await tester.tap(find.byKey(const ValueKey('collection_2')));
      await tester.pumpAndSettle();
      expect(find.text('Move to "Personal"'), findsOneWidget);

      await tester.tap(find.text('Move to "Personal"'));
      await tester.pumpAndSettle();

      expect(movedTarget?.id, 2);
    });

    testWidgets('Unsorted option is absent when collections list is empty', (tester) async {
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

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);
      expect(find.text('Unsorted'), findsNothing);
      expect(find.text('No collections yet'), findsOneWidget);
      expect(find.text('Create New Collection'), findsNothing);
    });

    testWidgets('uses a compact sheet when there are no collections', (tester) async {
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

      expect(
        tester.getSize(find.byKey(const ValueKey('move_to_collection_modal_sheet'))).height,
        lessThan(352.0),
      );
    });

    testWidgets('Moves single bookmark to a collection via BookmarkNotifier when onMove is null', (tester) async {
      final repo = MockMoveRepository();
      final col1 = BookmarkCollection()
        ..id = 10
        ..name = 'Reading'
        ..iconCodePoint = Icons.book.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FFD166';
      final col2 = BookmarkCollection()
        ..id = 11
        ..name = 'Archive'
        ..iconCodePoint = Icons.archive.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#06D6A0';
      repo.collectionsList.addAll([col1, col2]);

      final bookmark = Bookmark()
        ..id = 42
        ..url = 'https://flutter.dev'
        ..title = 'Flutter';
      bookmark.collection.value = col1;
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

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('collection_11')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Move to "Archive"'));
      await tester.pumpAndSettle();

      expect(bookmark.collection.value?.id, 11);
      expect(repo.updateBookmarksCallCount, 1);
    });

    testWidgets('Moves multiple bookmarks to a collection in batch via BookmarkNotifier', (tester) async {
      final repo = MockMoveRepository();
      final col1 = BookmarkCollection()
        ..id = 5
        ..name = 'Articles'
        ..iconCodePoint = Icons.article.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#06D6A0';
      final col2 = BookmarkCollection()
        ..id = 6
        ..name = 'Favorites'
        ..iconCodePoint = Icons.star.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FFD166';
      repo.collectionsList.addAll([col1, col2]);

      final b1 = Bookmark()
        ..id = 101
        ..url = 'https://a.com'
        ..title = 'A';
      b1.collection.value = col1;

      final b2 = Bookmark()
        ..id = 102
        ..url = 'https://b.com'
        ..title = 'B';
      b2.collection.value = col1;

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

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('collection_6')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Move to "Favorites"'));
      await tester.pumpAndSettle();

      expect(b1.collection.value?.id, 6);
      expect(b2.collection.value?.id, 6);
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
    testWidgets('MoveToCollectionModal wraps content compactly and caps height at CollectionEditorModal height when many collections', (tester) async {
      final repo = MockMoveRepository();
      repo.collectionsList.add(
        BookmarkCollection()
          ..id = 1
          ..name = 'Reading'
          ..iconCodePoint = Icons.book.codePoint
          ..iconFontFamily = 'MaterialIcons'
          ..colorHex = '#FFD166',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
          child: _buildTestApp(
            Builder(
              builder: (context) {
                return Column(
                  children: [
                    Expanded(
                      child: MoveToCollectionModal(
                        bookmark: Bookmark()..id = 1..url = 'https://flutter.dev'..title = 'Flutter',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardFinder = find.byKey(const ValueKey('move_to_collection_modal_sheet'));
      final cardSize = tester.getSize(cardFinder);
      final context = tester.element(cardFinder);
      final expected = CollectionEditorModal.getCollapsedModalHeight(context);
      expect(cardSize.height, lessThan(expected));

      // When there are many collections, height is capped at expected
      for (int i = 0; i < 15; i++) {
        repo.collectionsList.add(BookmarkCollection()
          ..id = 100 + i
          ..name = 'Collection $i'
          ..colorHex = '#FFD166'
          ..iconCodePoint = Icons.folder.codePoint
          ..iconFontFamily = 'MaterialIcons');
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
          child: _buildTestApp(
            Builder(
              builder: (context) {
                return Column(
                  children: [
                    Expanded(
                      child: MoveToCollectionModal(
                        bookmark: Bookmark()..id = 1..url = 'https://flutter.dev'..title = 'Flutter',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cappedCardSize = tester.getSize(cardFinder);
      expect(cappedCardSize.height, closeTo(expected, 0.01));
    });

    testWidgets('Hides Unsorted option for both unsorted and sorted bookmarks', (tester) async {
      final repo = MockMoveRepository();
      final col = BookmarkCollection()
        ..id = 1
        ..name = 'Tech'
        ..iconCodePoint = Icons.computer.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#4A90E2';
      repo.collectionsList.add(col);

      final unsortedBookmark = Bookmark()
        ..id = 10
        ..url = 'https://example.com'
        ..title = 'Unsorted Item';

      await tester.pumpWidget(
        _buildTestApp(
          MoveToCollectionModal(bookmark: unsortedBookmark),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);
      expect(find.byKey(const ValueKey('collection_1')), findsOneWidget);

      // Also verify batch unsorted bookmarks
      await tester.pumpWidget(
        _buildTestApp(
          MoveToCollectionModal(bookmarks: [unsortedBookmark]),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);
      expect(find.byKey(const ValueKey('collection_1')), findsOneWidget);

      // Verify Unsorted is ALSO hidden when bookmark belongs to another collection
      final sortedBookmark = Bookmark()
        ..id = 11
        ..url = 'https://example.org'
        ..title = 'Sorted Item'
        ..collection.value = col;

      await tester.pumpWidget(
        _buildTestApp(
          MoveToCollectionModal(bookmark: sortedBookmark),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collection_unsorted')), findsNothing);
      expect(find.byKey(const ValueKey('collection_1')), findsOneWidget);
    });

    testWidgets('renders gray divider line above the bottom action button', (tester) async {
      final repo = MockMoveRepository();
      repo.collectionsList.add(
        BookmarkCollection()
          ..id = 1
          ..name = 'Tech'
          ..iconCodePoint = Icons.computer.codePoint
          ..iconFontFamily = 'MaterialIcons'
          ..colorHex = '#4A90E2',
      );

      await tester.pumpWidget(
        _buildTestApp(
          const MoveToCollectionModal(),
          [
            repositoryProvider.overrideWithValue(repo),
            allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final dividerFinder = find.byKey(const ValueKey('move_to_collection_divider'));
      expect(dividerFinder, findsOneWidget);

      final dividerContainer = tester.widget<Container>(dividerFinder);
      expect(dividerContainer.color, Colors.black.withValues(alpha: 0.08));
      expect(tester.getSize(dividerFinder).height, 19.0);
      final coloredBoxFinder = find.descendant(
        of: dividerFinder,
        matching: find.byType(ColoredBox),
      );
      expect(tester.getSize(coloredBoxFinder).height, 1.0);

      final buttonFinder = find.widgetWithText(NeoButton, 'Move to Collection');
      expect(
        tester.getBottomLeft(coloredBoxFinder).dy,
        lessThan(tester.getTopLeft(buttonFinder).dy),
      );
    });
  });
}
