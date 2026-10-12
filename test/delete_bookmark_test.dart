import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';

class MockIsarRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<Bookmark> bookmarks = [];
  int deleteCallCount = 0;

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections() async => [];

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

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
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    for (final b in updated) {
      await updateBookmark(b);
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {
    deleteCallCount++;
    bookmarks.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    for (final id in ids) {
      await deleteBookmark(id);
    }
  }
}

void main() {
  test('BookmarkNotifier.deleteBookmark invalidates providers and removes bookmark immediately', () async {
    final mockRepo = MockIsarRepo();
    final col = BookmarkCollection()
      ..id = 42
      ..name = 'New';

    final bookmark = Bookmark()
      ..id = 101
      ..url = 'https://example.com'
      ..title = 'Test Link';
    bookmark.collection.value = col;

    mockRepo.bookmarks.add(bookmark);

    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Initial check
    final initialList = await container.read(collectionBookmarksProvider(42).future);
    expect(initialList.length, 1);
    expect(initialList.first.id, 101);

    // Perform deletion with collectionId
    await container.read(bookmarkNotifierProvider.notifier).deleteBookmark(bookmark, collectionId: 42);

    expect(mockRepo.deleteCallCount, 1);
    expect(mockRepo.bookmarks, isEmpty);

    // After invalidation, collectionBookmarksProvider reflects deletion immediately
    final updatedList = await container.read(collectionBookmarksProvider(42).future);
    expect(updatedList, isEmpty);
  });
}
