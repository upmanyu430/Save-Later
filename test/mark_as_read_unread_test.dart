import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';

class MockIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  Bookmark? lastUpdatedBookmark;
  int updateCallCount = 0;

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
  Future<void> addBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    updateCallCount++;
    lastUpdatedBookmark = bookmark;
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    updateCallCount += updated.length;
    if (updated.isNotEmpty) {
      lastUpdatedBookmark = updated.last;
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

void main() {
  test('markAsUnread sets isRead to false, updates repository, and invalidates providers', () async {
    final mockRepo = MockIsarRepository();
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example'
      ..isRead = true;

    var bookmarksProviderInvalidated = false;
    var unsortedBookmarksProviderInvalidated = false;

    container.listen(bookmarksProvider, (previous, next) {
      bookmarksProviderInvalidated = true;
    });

    container.listen(unsortedBookmarksProvider, (previous, next) {
      unsortedBookmarksProviderInvalidated = true;
    });

    await container.read(bookmarkNotifierProvider.notifier).markAsUnread(bookmark);

    expect(bookmark.isRead, isFalse);
    expect(mockRepo.updateCallCount, equals(1));
    expect(mockRepo.lastUpdatedBookmark?.isRead, isFalse);
    expect(bookmarksProviderInvalidated, isTrue);
    expect(unsortedBookmarksProviderInvalidated, isTrue);
  });

  test('markAsRead sets isRead to true, updates repository, and invalidates providers', () async {
    final mockRepo = MockIsarRepository();
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);

    final bookmark = Bookmark()
      ..id = 2
      ..url = 'https://example.com'
      ..title = 'Example'
      ..isRead = false;

    var bookmarksProviderInvalidated = false;
    var unsortedBookmarksProviderInvalidated = false;

    container.listen(bookmarksProvider, (previous, next) {
      bookmarksProviderInvalidated = true;
    });

    container.listen(unsortedBookmarksProvider, (previous, next) {
      unsortedBookmarksProviderInvalidated = true;
    });

    await container.read(bookmarkNotifierProvider.notifier).markAsRead(bookmark);

    expect(bookmark.isRead, isTrue);
    expect(mockRepo.updateCallCount, equals(1));
    expect(mockRepo.lastUpdatedBookmark?.isRead, isTrue);
    expect(bookmarksProviderInvalidated, isTrue);
    expect(unsortedBookmarksProviderInvalidated, isTrue);
  });
}
