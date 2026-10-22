import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';

class MockSharePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements SharePlatform {
  String? sharedText;

  @override
  Future<ShareResult> share(
    String text, {
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    sharedText = text;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

class FakeIsarRepository implements IsarRepository {
  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];

  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => collections;

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

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
  Future<void> addCollection(BookmarkCollection collection) async {}

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<Bookmark?> getBookmark(Id id) async => null;

  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async {
    return bookmarks.where((b) => b.collection.value?.id == collectionId).toList();
  }

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks;

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
  late MockSharePlatform mockShare;

  setUp(() {
    mockShare = MockSharePlatform();
    SharePlatform.instance = mockShare;
  });

  testWidgets('Tapping Share Collection in menu modal shares all bookmarks in the collection', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final collection = BookmarkCollection()
      ..id = 42
      ..name = 'Design'
      ..colorHex = 'FF5733';
    fakeRepo.collections.add(collection);

    final b1 = Bookmark()
      ..id = 1
      ..url = 'https://example.com/figma'
      ..title = 'Figma'
      ..collection.value = collection;

    final b2 = Bookmark()
      ..id = 2
      ..url = 'https://example.com/dribbble'
      ..title = 'Dribbble'
      ..collection.value = collection;

    fakeRepo.bookmarks.addAll([b1, b2]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          collectionBookmarksProvider(42).overrideWith((ref) => Future.value([b1, b2])),
          subCollectionsProvider(42).overrideWith((ref) => Future.value([])),
        ],
        child: buildTestApp(
          home: CollectionDetailScreen(
            collectionId: 42,
            collection: collection,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open more menu (Icons.more_vert)
    final moreButton = find.byIcon(Icons.more_vert);
    expect(moreButton, findsOneWidget);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    // Find and tap "Share Collection"
    final shareMenuItem = find.text('Share Collection');
    expect(shareMenuItem, findsOneWidget);
    await tester.tap(shareMenuItem);
    await tester.pumpAndSettle();

    // Verify SharePlatform.share was called with collection name and URLs
    expect(mockShare.sharedText, 'Design:\nhttps://example.com/figma\nhttps://example.com/dribbble');
  });

  testWidgets('Tapping Share Collection in empty collection shares collection name header', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final collection = BookmarkCollection()
      ..id = 99
      ..name = 'Articles'
      ..colorHex = '33FF57';
    fakeRepo.collections.add(collection);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          collectionBookmarksProvider(99).overrideWith((ref) => Future.value([])),
          subCollectionsProvider(99).overrideWith((ref) => Future.value([])),
        ],
        child: buildTestApp(
          home: CollectionDetailScreen(
            collectionId: 99,
            collection: collection,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final moreButton = find.byIcon(Icons.more_vert);
    await tester.tap(moreButton);
    await tester.pumpAndSettle();

    final shareMenuItem = find.text('Share Collection');
    await tester.tap(shareMenuItem);
    await tester.pumpAndSettle();

    expect(mockShare.sharedText, 'Collection: Articles');
  });
}
