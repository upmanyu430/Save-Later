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
import 'package:save_later/ui/widgets/share_save_modal.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';

class _MockRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');
  final List<BookmarkCollection> collections = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB');
  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => collections;
  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];
  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collections.where((c) => c.id == id).firstOrNull;
  @override
  Future<List<BookmarkCollection>> getAllCollections() async => collections;
  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }
  @override
  Future<void> deleteCollection(Id collectionId) async {}
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

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('ShareSaveModal folder options have horizontal margin and slim height', (tester) async {
    final repo = _MockRepo();
    final col1 = BookmarkCollection()
      ..id = 1
      ..name = 'Reading'
      ..colorHex = 'FF2196F3'
      ..iconCodePoint = Icons.book.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collections.add(col1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: ShareSaveModal(
            url: 'https://flutter.dev',
            onSave: (col, isPinned) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Unsorted tile has 16 horizontal margin
    final unsortedFinder = find.byKey(const ValueKey('share_modal_unsorted'));
    expect(unsortedFinder, findsOneWidget);
    final unsortedContainer = tester.widget<Container>(
      find.descendant(of: unsortedFinder, matching: find.byType(Container)).first,
    );
    expect(unsortedContainer.margin, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(unsortedContainer.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5));

    // Check Pin row has 16 horizontal margin
    final pinRowFinder = find.byKey(const ValueKey('share_modal_pin_row'));
    expect(pinRowFinder, findsOneWidget);
    final pinContainer = tester.widget<Container>(
      find.descendant(of: pinRowFinder, matching: find.byType(Container)).first,
    );
    expect(pinContainer.margin, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(pinContainer.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 5.5));

    // Check collection tile has 16 horizontal margin
    final colFinder = find.byKey(const ValueKey('share_modal_collection_1'));
    expect(colFinder, findsOneWidget);
    final colContainer = tester.widget<Container>(
      find.descendant(of: colFinder, matching: find.byType(Container)).first,
    );
    expect(colContainer.margin, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(colContainer.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5));
  });

  testWidgets('MoveToCollectionModal folder options have horizontal margin and slim height', (tester) async {
    final repo = _MockRepo();
    final col1 = BookmarkCollection()
      ..id = 2
      ..name = 'Work'
      ..colorHex = 'FF4CAF50'
      ..iconCodePoint = Icons.work.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collections.add(col1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: const MoveToCollectionModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Unsorted tile in MoveToCollectionModal
    final unsortedFinder = find.byKey(const ValueKey('collection_unsorted'));
    expect(unsortedFinder, findsOneWidget);
    final unsortedContainer = tester.widget<Container>(
      find.descendant(of: unsortedFinder, matching: find.byType(Container)).first,
    );
    expect(unsortedContainer.margin, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(unsortedContainer.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5));

    // Check collection tile in MoveToCollectionModal
    final colFinder = find.byKey(const ValueKey('collection_2'));
    expect(colFinder, findsOneWidget);
    final colContainer = tester.widget<Container>(
      find.descendant(of: colFinder, matching: find.byType(Container)).first,
    );
    expect(colContainer.margin, const EdgeInsets.symmetric(horizontal: 16.0));
    expect(colContainer.padding, const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5));
  });
}
