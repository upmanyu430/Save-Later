import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/empty_collection_view.dart';

class MockEmptyCollectionRepo implements IsarRepository {
  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];

  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async {
    if (parentId != null) {
      return collections.where((c) => c.parentId == parentId).toList();
    }
    return collections.where((c) => c.parentId == null).toList();
  }

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async {
    return collections.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    collections.removeWhere((c) => c.id == collectionId);
  }

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
    final idx = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx != -1) bookmarks[idx] = bookmark;
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

  @override
  Future<void> clearAllData() async {
    collections.clear();
    bookmarks.clear();
  }

  @override
  Future<List<String>> getAllTags() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockEmptyCollectionRepo repo;

  setUp(() {
    repo = MockEmptyCollectionRepo();
  });

  Widget buildTestWidget({required Widget child}) {
    return ProviderScope(
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
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('Empty Collection Folder Tests', () {
    testWidgets('renders EmptyFolderGraphic and EmptyCollectionView correctly', (tester) async {
      bool seeHowTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EmptyCollectionView(
              onSeeHowPressed: () {
                seeHowTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyFolderGraphic), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Tap + or share to save one.'), findsOneWidget);
      expect(find.text('See how'), findsOneWidget);

      await tester.tap(find.text('See how'));
      await tester.pump();
      expect(seeHowTapped, isTrue);
    });

    testWidgets('CollectionDetailScreen displays empty state when collection has 0 items and 0 subcollections', (tester) async {
      final appsCollection = BookmarkCollection()
        ..id = 1
        ..name = 'Apps'
        ..colorHex = '#FFE4B5';

      repo.collections.add(appsCollection);

      await tester.pumpWidget(
        buildTestWidget(
          child: CollectionDetailScreen(
            collectionId: 1,
            collection: appsCollection,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top header
      expect(find.text('Apps'), findsOneWidget);
      expect(find.text('0 items · 0 subcollections'), findsOneWidget);

      // Section header
      expect(find.text('SAVES (0)'), findsOneWidget);

      // Empty folder elements
      expect(find.byType(EmptyFolderGraphic), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.text('Tap + or share to save one.'), findsOneWidget);
      expect(find.text('See how'), findsOneWidget);
    });

    testWidgets('CollectionDetailScreen displays subcollections and SAVES (0) empty state when 0 bookmarks', (tester) async {
      final parentCol = BookmarkCollection()
        ..id = 1
        ..name = 'Work'
        ..colorHex = '#FFE4B5';

      final subCol = BookmarkCollection()
        ..id = 2
        ..name = 'Docs'
        ..colorHex = '#C3E0E5'
        ..iconCodePoint = 0xe2c7
        ..iconFontFamily = 'MaterialIcons'
        ..parentId = 1;

      repo.collections.addAll([parentCol, subCol]);

      await tester.pumpWidget(
        buildTestWidget(
          child: CollectionDetailScreen(
            collectionId: 1,
            collection: parentCol,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('0 items · 1 subcollection'), findsOneWidget);
      expect(find.text('SUB-COLLECTIONS (1)'), findsOneWidget);
      expect(find.text('Docs'), findsOneWidget);

      expect(find.text('SAVES (0)'), findsOneWidget);
      expect(find.byType(EmptyFolderGraphic), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('CollectionDetailScreen hides empty state when collection contains bookmarks', (tester) async {
      final col = BookmarkCollection()
        ..id = 1
        ..name = 'Apps'
        ..colorHex = '#FFE4B5';

      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://example.com'
        ..title = 'Example Site';
      bookmark.collection.value = col;

      repo.collections.add(col);
      repo.bookmarks.add(bookmark);

      await tester.pumpWidget(
        buildTestWidget(
          child: CollectionDetailScreen(
            collectionId: 1,
            collection: col,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apps'), findsOneWidget);
      expect(find.text('1 item · 0 subcollections'), findsOneWidget);
      expect(find.text('SAVES (1)'), findsOneWidget);

      // Empty state should not be rendered
      expect(find.byType(EmptyFolderGraphic), findsNothing);
      expect(find.text('No items yet'), findsNothing);
      expect(find.text('See how'), findsNothing);
    });
  });
}
