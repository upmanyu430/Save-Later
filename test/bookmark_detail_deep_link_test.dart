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

class DeepLinkTestIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final Map<Id, Bookmark> bookmarksMap = {};

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
  Future<Bookmark?> getBookmark(Id id) async => bookmarksMap[id];

  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarksMap.values.toList();

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => [];

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarksMap[bookmark.id] = bookmark;
  }

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    bookmarksMap[bookmark.id] = bookmark;
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    for (final b in updated) {
      bookmarksMap[b.id] = b;
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {
    bookmarksMap.remove(id);
  }

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    for (final id in ids) {
      bookmarksMap.remove(id);
    }
  }
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
  testWidgets('BookmarkDetailScreen loads bookmark by ID when bookmark is null (deep link / process death)', (tester) async {
    final repo = DeepLinkTestIsarRepository();
    final bookmark = Bookmark()
      ..id = 42
      ..url = 'https://flutter.dev'
      ..title = 'Flutter Official Website'
      ..notes = 'My notes about Flutter';
    repo.bookmarksMap[42] = bookmark;

    await tester.pumpWidget(
      createTestApp(
        repo: repo,
        child: const BookmarkDetailScreen(
          bookmark: null,
          bookmarkId: 42,
        ),
      ),
    );

    // Initial state shows loader
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the async microtask resolve
    await tester.pumpAndSettle();

    // Verify loaded content is displayed
    expect(find.text('Flutter Official Website'), findsOneWidget);
    expect(find.text('My notes about Flutter'), findsOneWidget);
  });

  testWidgets('BookmarkDetailScreen displays Bookmark not found when ID does not exist', (tester) async {
    final repo = DeepLinkTestIsarRepository();

    await tester.pumpWidget(
      createTestApp(
        repo: repo,
        child: const BookmarkDetailScreen(
          bookmark: null,
          bookmarkId: 999,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bookmark not found'), findsOneWidget);
    expect(find.text('Go back'), findsOneWidget);
  });
}
