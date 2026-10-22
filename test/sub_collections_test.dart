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
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/collection_grid_item.dart';

class SubCollectionTestRepo implements IsarRepository {
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
  Future<List<BookmarkCollection>> getAllCollections() async {
    return List.from(collections);
  }

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    if (collection.id == Isar.autoIncrement) {
      collection.id = collections.length + 1;
    }
    collections.removeWhere((c) => c.id == collection.id);
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    for (final c in collections) {
      if (c.parentId == collectionId) {
        c.parentId = null;
      }
    }
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
  Future<void> deleteBookmark(Id bookmarkId) async {
    bookmarks.removeWhere((b) => b.id == bookmarkId);
  }

  @override
  Future<void> deleteBookmarks(List<Id> bookmarkIds) async {
    bookmarks.removeWhere((b) => bookmarkIds.contains(b.id));
  }

  @override
  Future<List<String>> getAllTags() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SubCollectionTestRepo repo;

  setUp(() {
    repo = SubCollectionTestRepo();
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

  group('Sub-Collections Data & Hierarchy Logic', () {
    test('creates sub-collection with parentId and queries hierarchically', () async {
      final parent = BookmarkCollection()
        ..id = 1
        ..name = 'Development'
        ..colorHex = '#FFE4B5';

      final child = BookmarkCollection()
        ..id = 2
        ..name = 'Flutter'
        ..colorHex = '#C3E0E5'
        ..parentId = 1;

      final rootCol = BookmarkCollection()
        ..id = 3
        ..name = 'Design'
        ..colorHex = '#B4F8C8';

      repo.collections.addAll([parent, child, rootCol]);

      final rootCollections = await repo.getCollections();
      expect(rootCollections.map((c) => c.name), containsAll(['Development', 'Design']));
      expect(rootCollections.any((c) => c.name == 'Flutter'), isFalse);

      final subCollections = await repo.getSubCollections(1);
      expect(subCollections.length, 1);
      expect(subCollections.first.name, 'Flutter');
      expect(subCollections.first.parentId, 1);

      final allCols = await repo.getAllCollections();
      expect(allCols.length, 3);
    });

    test('deleting parent collection unparents child sub-collections', () async {
      final parent = BookmarkCollection()
        ..id = 10
        ..name = 'Parent'
        ..colorHex = '#FFE4B5';

      final child = BookmarkCollection()
        ..id = 11
        ..name = 'Child'
        ..colorHex = '#C3E0E5'
        ..parentId = 10;

      repo.collections.addAll([parent, child]);

      await repo.deleteCollection(10);

      expect(repo.collections.any((c) => c.id == 10), isFalse);
      final remaining = repo.collections.firstWhere((c) => c.id == 11);
      expect(remaining.parentId, isNull);
    });
  });

  group('CollectionEditorModal with parentId', () {
    testWidgets('shows "New sub-collection" and "Create sub-collection" for sub-collection', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Scaffold(
            body: CollectionEditorModal(parentId: 42),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New sub-collection'), findsOneWidget);
      expect(find.text('Create sub-collection'), findsOneWidget);
    });

    testWidgets('shows "Add new collection" for root collection', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Scaffold(
            body: CollectionEditorModal(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add new collection'), findsOneWidget);
      expect(find.text('Create collection'), findsOneWidget);
    });

    test('creates sub-collection assigning parentId via notifier', () async {
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      try {
        final notifier = container.read(collectionNotifierProvider.notifier);
        await notifier.addCollection('Sub Folder', '#4A90E2', 0xe2c7, parentId: 5);

        final subs = await repo.getSubCollections(5);
        expect(subs.length, 1);
        expect(subs.first.name, 'Sub Folder');
        expect(subs.first.parentId, 5);
        expect(subs.first.colorHex, '#4A90E2');
      } finally {
        container.dispose();
      }
    });
  });

  group('CollectionDetailScreen Sub-Collections Rendering', () {
    testWidgets('renders SUB-COLLECTIONS header and CollectionGridItem cards', (tester) async {
      final parentCol = BookmarkCollection()
        ..id = 1
        ..name = 'Tech'
        ..colorHex = '#FFE4B5'
        ..iconCodePoint = 0xe2c7
        ..iconFontFamily = 'MaterialIcons';

      final sub1 = BookmarkCollection()
        ..id = 2
        ..name = 'Mobile'
        ..colorHex = '#C3E0E5'
        ..iconCodePoint = 0xe2c7
        ..iconFontFamily = 'MaterialIcons'
        ..parentId = 1;

      final sub2 = BookmarkCollection()
        ..id = 3
        ..name = 'Web'
        ..colorHex = '#B4F8C8'
        ..iconCodePoint = 0xe2c7
        ..iconFontFamily = 'MaterialIcons'
        ..parentId = 1;

      repo.collections.addAll([parentCol, sub1, sub2]);

      await tester.pumpWidget(
        buildTestWidget(
          child: CollectionDetailScreen(
            collectionId: 1,
            collection: parentCol,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SUB-COLLECTIONS (2)'), findsOneWidget);
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Web'), findsOneWidget);
      expect(find.byType(CollectionGridItem), findsNWidgets(2));
    });
  });
}
