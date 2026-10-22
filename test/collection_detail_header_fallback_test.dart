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

class FallbackTestIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final Map<Id, BookmarkCollection> collectionsMap = {};

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<BookmarkCollection?> getCollection(Id id) async => collectionsMap[id];

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => collectionsMap.values.toList();

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => collectionsMap.values.toList();

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collectionsMap[collection.id] = collection;
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    collectionsMap.remove(collectionId);
  }

  @override
  Future<Bookmark?> getBookmark(Id id) async => null;

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

Widget createTestApp({required Widget child, required IsarRepository repo}) {
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
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

void main() {
  testWidgets('CollectionDetailScreen fetches collection name via singleCollectionProvider when collection is null', (tester) async {
    final repo = FallbackTestIsarRepository();
    final collection = BookmarkCollection()
      ..id = 99
      ..name = 'Design Resources'
      ..colorHex = 'FFD166'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = 'MaterialIcons';
    repo.collectionsMap[99] = collection;

    await tester.pumpWidget(
      createTestApp(
        repo: repo,
        child: const CollectionDetailScreen(
          collectionId: 99,
          collection: null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it renders the real collection name, NOT "Unsorted"
    expect(find.text('Design Resources'), findsOneWidget);
    expect(find.text('Unsorted'), findsNothing);
  });

  testWidgets('CollectionDetailScreen renders Unsorted when collectionId is null', (tester) async {
    final repo = FallbackTestIsarRepository();

    await tester.pumpWidget(
      createTestApp(
        repo: repo,
        child: const CollectionDetailScreen(
          collectionId: null,
          collection: null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unsorted'), findsOneWidget);
  });
}
