import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';

class QuickSaveTestRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  Bookmark? savedBookmark;

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
  Future<Bookmark?> getBookmark(Id id) async => null;

  @override
  Future<List<Bookmark>> getBookmarks() async => [];

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => [];

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    savedBookmark = bookmark;
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

void main() {
  test('quickSave cleans and extracts URL when passed shared text containing link and description', () async {
    final repo = QuickSaveTestRepo();
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    const sharedPayload = 'Check this out: https://flutter.dev/multi-platform';
    await container.read(bookmarkNotifierProvider.notifier).quickSave(sharedPayload);

    expect(repo.savedBookmark, isNotNull);
    expect(repo.savedBookmark!.url, 'https://flutter.dev/multi-platform');
    expect(repo.savedBookmark!.sourceDomain, 'flutter.dev');
  });

  test('quickSave handles multi-line shared intent text', () async {
    final repo = QuickSaveTestRepo();
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    const multilinePayload = '''
Breaking news!
Read the full story here:
https://example.com/world/news-123.
Have a great day!
''';
    await container.read(bookmarkNotifierProvider.notifier).quickSave(multilinePayload);

    expect(repo.savedBookmark, isNotNull);
    expect(repo.savedBookmark!.url, 'https://example.com/world/news-123');
    expect(repo.savedBookmark!.sourceDomain, 'example.com');
  });
}
