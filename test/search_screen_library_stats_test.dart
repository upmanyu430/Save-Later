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
import 'package:save_later/ui/screens/search_screen.dart';

class FakeIsarRepository implements IsarRepository {
  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];

  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async {
    return collections.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async {
    return collections.where((c) => c.parentId == parentId).toList();
  }

  @override
  Future<BookmarkCollection?> getCollection(Id id) async {
    try {
      return collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => collections;

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    collections.removeWhere((c) => c.id == collectionId);
  }

  @override
  Future<Bookmark?> getBookmark(Id id) async {
    try {
      return bookmarks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks.where((b) => !b.isRead).toList();

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks.add(bookmark);
  }

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    final idx = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx != -1) {
      bookmarks[idx] = bookmark;
    }
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
}

Widget buildTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: home,
  );
}

void main() {
  testWidgets('SearchScreen library stats includes sub-collections in collectionsCount', (tester) async {
    final fakeRepo = FakeIsarRepository();

    // 2 root collections (parentId == null)
    final rootCol1 = BookmarkCollection()
      ..id = 1
      ..name = 'Work'
      ..colorHex = 'FF5733';
    final rootCol2 = BookmarkCollection()
      ..id = 2
      ..name = 'Personal'
      ..colorHex = '33FF57';

    // 2 sub-collections (parentId != null)
    final subCol1 = BookmarkCollection()
      ..id = 3
      ..parentId = 1
      ..name = 'Projects'
      ..colorHex = '3357FF';
    final subCol2 = BookmarkCollection()
      ..id = 4
      ..parentId = 1
      ..name = 'Meeting Notes'
      ..colorHex = 'FFFF33';

    fakeRepo.collections.addAll([rootCol1, rootCol2, subCol1, subCol2]);

    final bookmark1 = Bookmark()
      ..id = 101
      ..title = 'Doc 1'
      ..url = 'https://example.com/1'
      ..isPinned = true
      ..tags = ['dev', 'flutter'];
    final bookmark2 = Bookmark()
      ..id = 102
      ..title = 'Doc 2'
      ..url = 'https://example.com/2'
      ..isPinned = false
      ..tags = ['flutter', 'dart'];

    fakeRepo.bookmarks.addAll([bookmark1, bookmark2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: buildTestApp(
          home: const SearchScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "YOUR LIBRARY" stats card is displayed
    expect(find.text('YOUR LIBRARY'), findsOneWidget);

    // Collections count should be 4 (including root and sub-collections), not 2
    expect(find.text('4'), findsOneWidget); // 4 collections
    expect(find.text('Collections'), findsOneWidget);

    // Bookmarks count: 2 saves
    expect(find.text('2'), findsOneWidget); // 2 saves
    expect(find.text('Saves'), findsOneWidget);

    // Pinned count: 1 pinned
    expect(find.text('1'), findsOneWidget); // 1 pinned
    expect(find.text('Pinned'), findsOneWidget);

    // Unique tags count: 3 unique tags ('dev', 'flutter', 'dart')
    expect(find.text('3'), findsOneWidget); // 3 tags
    expect(find.text('Tags'), findsOneWidget);
  });
}
