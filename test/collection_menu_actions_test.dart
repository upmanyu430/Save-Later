import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';

class TestMenuIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];
  int deleteCollectionCallCount = 0;

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async =>
      List.from(collections.where((c) => parentId != null ? c.parentId == parentId : c.parentId == null));

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async =>
      List.from(collections.where((c) => c.parentId == parentId));

  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collections.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async =>
      List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.removeWhere((c) => c.id == collection.id);
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    deleteCollectionCallCount++;
    collections.removeWhere((c) => c.id == collectionId);
  }

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
  Future<void> updateBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {}

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

Widget createTestApp({
  required Widget child,
  required IsarRepository repo,
  NavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  late TestMenuIsarRepository testRepo;
  late BookmarkCollection testCollection;

  setUp(() {
    testRepo = TestMenuIsarRepository();
    testCollection = BookmarkCollection()
      ..id = 42
      ..name = 'Design Assets'
      ..colorHex = 'FFD166'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = 'MaterialIcons';
    testRepo.collections.add(testCollection);
  });

  testWidgets(
      '_showMenuModal does NOT display Edit Collection or Delete Collection when collectionId is null (Unsorted)',
      (tester) async {
    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: const CollectionDetailScreen(
          collectionId: null,
          collection: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open more menu
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Verify items present in Unsorted
    expect(find.text('Add Link'), findsOneWidget);
    expect(find.text('Select Links'), findsOneWidget);
    expect(find.text('Share Collection'), findsOneWidget);

    // Verify Create Sub-collection, Edit Collection, and Delete Collection are NOT present in Unsorted
    expect(find.text('Create Sub-collection'), findsNothing);
    expect(find.text('Edit Collection'), findsNothing);
    expect(find.text('Delete Collection'), findsNothing);
  });

  testWidgets(
      '_showMenuModal displays Edit Collection and Delete Collection when collectionId != null',
      (tester) async {
    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: CollectionDetailScreen(
          collectionId: testCollection.id,
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open more menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Verify Create Sub-collection, Edit Collection and Delete Collection are present
    expect(find.text('Create Sub-collection'), findsOneWidget);
    expect(find.text('Edit Collection'), findsOneWidget);
    expect(find.text('Delete Collection'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets(
      'Tapping Edit Collection in _showMenuModal opens CollectionEditorModal',
      (tester) async {
    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: CollectionDetailScreen(
          collectionId: testCollection.id,
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Edit Collection
    await tester.tap(find.text('Edit Collection'));
    await tester.pumpAndSettle();

    // Verify CollectionEditorModal is shown with pre-populated name
    expect(find.byType(CollectionEditorModal), findsOneWidget);
    expect(find.text('Design Assets'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'Tapping Delete Collection in _showMenuModal shows DeleteConfirmationDialog and cancelling does not delete',
      (tester) async {
    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: CollectionDetailScreen(
          collectionId: testCollection.id,
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Delete Collection
    await tester.tap(find.text('Delete Collection'));
    await tester.pumpAndSettle();

    // Verify DeleteConfirmationDialog is shown
    expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
    expect(find.text('Permanently delete "Design Assets"? Links inside will be moved to Unsorted.'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed, collection not deleted
    expect(find.byType(DeleteConfirmationDialog), findsNothing);
    expect(testRepo.deleteCollectionCallCount, equals(0));
    expect(testRepo.collections.length, equals(1));
  });

  testWidgets(
      'Tapping Delete Collection in _showMenuModal and confirming deletes collection and pops screen',
      (tester) async {
    final mockObserver = _MockNavigatorObserver();

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        navigatorObserver: mockObserver,
        child: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (ctx) => CollectionDetailScreen(
              collectionId: testCollection.id,
              collection: testCollection,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Delete Collection
    await tester.tap(find.text('Delete Collection'));
    await tester.pumpAndSettle();

    expect(find.byType(DeleteConfirmationDialog), findsOneWidget);

    // Tap Delete button in dialog
    await tester.tap(find.descendant(
      of: find.byType(DeleteConfirmationDialog),
      matching: find.text('Delete'),
    ));
    await tester.pumpAndSettle();

    // Repository deleteCollection was called
    expect(testRepo.deleteCollectionCallCount, equals(1));
    expect(testRepo.collections.isEmpty, isTrue);

    // Screen was popped
    expect(mockObserver.didPopCalled, isTrue);
  });
}

class _MockNavigatorObserver extends NavigatorObserver {
  bool didPopCalled = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    didPopCalled = true;
  }
}
