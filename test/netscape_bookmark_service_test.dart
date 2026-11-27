import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/utils/netscape_bookmark_service.dart';

class _InMemoryFakeRepository extends Fake implements IsarRepository {
  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];
  int _nextCollectionId = 1;
  int _nextBookmarkId = 1;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async =>
      List<BookmarkCollection>.from(collections);

  @override
  Future<List<Bookmark>> getBookmarks() async => List<Bookmark>.from(bookmarks);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    if (collection.id == Isar.autoIncrement) {
      collection.id = _nextCollectionId++;
    }
    collections.add(collection);
  }

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    if (bookmark.id == Isar.autoIncrement) {
      bookmark.id = _nextBookmarkId++;
    }
    bookmarks.add(bookmark);
  }
}

void main() {
  group('NetscapeBookmarkService', () {
    test('parseNetscapeHtml handles Chrome/Firefox unclosed DT folders, nested folders, tags, and descriptions', () {
      const sampleHtml = '''
<!DOCTYPE NETSCAPE-Bookmark-file-1>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3 ADD_DATE="1700000000">Reading</H3>
    <DL><p>
        <DT><A HREF="https://flutter.dev" ADD_DATE="1700000100" TAGS="flutter,mobile">Flutter Docs</A>
        <DD>Official Flutter documentation
        <DT><H3>Nested Dart</H3>
        <DL><p>
            <DT><A HREF="https://dart.dev" ADD_DATE="1700000200">Dart Language</A>
        </DL><p>
    </DL><p>
    <DT><A HREF="https://news.ycombinator.com" ADD_DATE="1700000300">Hacker News</A>
    <DT><A HREF="javascript:alert(1)">Ignored JS</A>
</DL><p>
''';

      final entries = NetscapeBookmarkService.parseNetscapeHtml(sampleHtml);
      expect(entries.length, 3);

      expect(entries[0].url, 'https://flutter.dev');
      expect(entries[0].title, 'Flutter Docs');
      expect(entries[0].folderPath, ['Reading']);
      expect(entries[0].tags, ['flutter', 'mobile']);
      expect(entries[0].description, 'Official Flutter documentation');

      expect(entries[1].url, 'https://dart.dev');
      expect(entries[1].title, 'Dart Language');
      expect(entries[1].folderPath, ['Reading', 'Nested Dart']);

      expect(entries[2].url, 'https://news.ycombinator.com');
      expect(entries[2].folderPath, isEmpty);
    });

    test('generateNetscapeHtml round-trips collections, nested collections, tags, notes, and unsorted bookmarks', () async {
      final parentCol = BookmarkCollection()
        ..id = 1
        ..name = 'Design & UI'
        ..colorHex = 'FFD166'
        ..iconCodePoint = Icons.folder_outlined.codePoint
        ..iconFontFamily = kStoredIconFontFamily
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      final childCol = BookmarkCollection()
        ..id = 2
        ..name = 'Typography'
        ..colorHex = '3AC19F'
        ..iconCodePoint = Icons.folder_outlined.codePoint
        ..iconFontFamily = kStoredIconFontFamily
        ..parentId = 1
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000100000);

      final b1 = Bookmark()
        ..id = 1
        ..url = 'https://example.com/fonts'
        ..title = 'Great Fonts & "Quotes"'
        ..description = 'Curated font list'
        ..notes = 'Check licensing before use'
        ..tags = ['fonts', 'design']
        ..isPinned = true
        ..isRead = true
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000200000);
      b1.collection.value = childCol;

      final b2 = Bookmark()
        ..id = 2
        ..url = 'https://example.org/unsorted'
        ..title = 'Unsorted Link'
        ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000300000);

      final html = NetscapeBookmarkService.generateNetscapeHtml(
        collections: [parentCol, childCol],
        bookmarks: [b1, b2],
      );

      expect(html, contains('<!DOCTYPE NETSCAPE-Bookmark-file-1>'));
      expect(html, contains('Design &amp; UI'));
      expect(html, contains('Typography'));

      final fakeRepo = _InMemoryFakeRepository();
      final result = await NetscapeBookmarkService.importNetscapeHtml(
        htmlContent: html,
        repository: fakeRepo,
      );

      expect(result.importedCount, 2);
      expect(result.skippedCount, 0);
      expect(result.collectionsCreated, 2);
      expect(fakeRepo.collections.length, 2);
      expect(fakeRepo.collections[1].parentId, fakeRepo.collections[0].id);
      expect(fakeRepo.bookmarks[0].notes, 'Check licensing before use');
      expect(fakeRepo.bookmarks[0].isPinned, isTrue);
      expect(fakeRepo.bookmarks[0].isRead, isTrue);
      expect(fakeRepo.bookmarks[0].tags, ['fonts', 'design']);
      expect(fakeRepo.bookmarks[0].collection.value?.name, 'Typography');
      expect(fakeRepo.bookmarks[1].collection.value, isNull);

      // Re-importing the same file skips duplicates
      final secondResult = await NetscapeBookmarkService.importNetscapeHtml(
        htmlContent: html,
        repository: fakeRepo,
      );
      expect(secondResult.importedCount, 0);
      expect(secondResult.skippedCount, 2);
    });
  });
}
