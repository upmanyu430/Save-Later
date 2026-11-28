import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import '../models/bookmark.dart';
import '../models/collection.dart';
import '../repositories/isar_repository.dart';

class ParsedBookmarkEntry {
  final String url;
  final String title;
  final DateTime createdAt;
  final List<String> tags;
  String? description;
  final String notes;
  final bool isPinned;
  final bool isRead;
  final List<String> folderPath;

  ParsedBookmarkEntry({
    required this.url,
    required this.title,
    required this.createdAt,
    required this.tags,
    this.description,
    this.notes = '',
    this.isPinned = false,
    this.isRead = false,
    required this.folderPath,
  });
}

class BookmarkImportResult {
  final int importedCount;
  final int skippedCount;
  final int collectionsCreated;

  const BookmarkImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.collectionsCreated,
  });
}

class NetscapeBookmarkService {
  static const HtmlEscape _attrEscape = HtmlEscape(HtmlEscapeMode.attribute);
  static const HtmlEscape _textEscape = HtmlEscape(HtmlEscapeMode.element);

  static const List<String> _defaultPalette = [
    'FFD166',
    'FF9EAA',
    '3AC19F',
    '4A90E2',
    'B19CD9',
    'F39C12',
    '2ECC71',
    'E74C3C',
  ];

  /// Generates a standard Netscape Bookmark HTML document from collections and bookmarks.
  static String generateNetscapeHtml({
    required List<BookmarkCollection> collections,
    required List<Bookmark> bookmarks,
    String title = 'Save Later Bookmarks',
  }) {
    final buffer = StringBuffer();
    final escapedTitle = _textEscape.convert(title);

    buffer.writeln('<!DOCTYPE NETSCAPE-Bookmark-file-1>');
    buffer.writeln('<!-- This is an automatically generated file.');
    buffer.writeln('     It will be read and overwritten.');
    buffer.writeln('     DO NOT EDIT! -->');
    buffer.writeln(
        '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">');
    buffer.writeln('<TITLE>$escapedTitle</TITLE>');
    buffer.writeln('<H1>$escapedTitle</H1>');
    buffer.writeln('<DL><p>');

    final collectionById = <int, BookmarkCollection>{
      for (final c in collections) c.id: c,
    };

    final childrenByParent = <int?, List<BookmarkCollection>>{};
    for (final c in collections) {
      final parentKey =
          (c.parentId != null && collectionById.containsKey(c.parentId))
              ? c.parentId
              : null;
      childrenByParent.putIfAbsent(parentKey, () => []).add(c);
    }

    final bookmarksByCollection = <int?, List<Bookmark>>{};
    for (final b in bookmarks) {
      final colId = b.collection.value?.id;
      final key =
          (colId != null && collectionById.containsKey(colId)) ? colId : null;
      bookmarksByCollection.putIfAbsent(key, () => []).add(b);
    }

    final visitedCollections = <int>{};

    void writeCollectionNode(BookmarkCollection col, int indentLevel) {
      if (!visitedCollections.add(col.id)) return;
      final indent = '    ' * indentLevel;
      final addDate = (col.createdAt.millisecondsSinceEpoch ~/ 1000).toString();
      final colName = _textEscape.convert(col.name);

      buffer.writeln(
          '$indent<DT><H3 ADD_DATE="$addDate" LAST_MODIFIED="$addDate">$colName</H3>');
      buffer.writeln('$indent<DL><p>');

      final childBookmarks = bookmarksByCollection[col.id] ?? const [];
      for (final b in childBookmarks) {
        _writeBookmarkLine(buffer, b, indentLevel + 1);
      }

      final childCols = childrenByParent[col.id] ?? const [];
      for (final child in childCols) {
        writeCollectionNode(child, indentLevel + 1);
      }

      buffer.writeln('$indent</DL><p>');
    }

    final rootCollections = childrenByParent[null] ?? const [];
    for (final col in rootCollections) {
      writeCollectionNode(col, 1);
    }

    final unsortedBookmarks = bookmarksByCollection[null] ?? const [];
    for (final b in unsortedBookmarks) {
      _writeBookmarkLine(buffer, b, 1);
    }

    buffer.writeln('</DL><p>');
    return buffer.toString();
  }

  static void _writeBookmarkLine(
    StringBuffer buffer,
    Bookmark bookmark,
    int indentLevel,
  ) {
    final indent = '    ' * indentLevel;
    final href = _attrEscape.convert(bookmark.url);
    final addDate =
        (bookmark.createdAt.millisecondsSinceEpoch ~/ 1000).toString();
    final displayTitle = _textEscape.convert(
      (bookmark.title != null && bookmark.title!.trim().isNotEmpty)
          ? bookmark.title!.trim()
          : bookmark.url,
    );

    final attrs = StringBuffer('HREF="$href" ADD_DATE="$addDate"');
    if (bookmark.tags.isNotEmpty) {
      final cleanTags = bookmark.tags
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .join(',');
      if (cleanTags.isNotEmpty) {
        attrs.write(' TAGS="${_attrEscape.convert(cleanTags)}"');
      }
    }
    if (bookmark.notes.trim().isNotEmpty) {
      attrs.write(' DATA-NOTES="${_attrEscape.convert(bookmark.notes)}"');
    }
    if (bookmark.isPinned) {
      attrs.write(' DATA-PINNED="1"');
    }
    if (bookmark.isRead) {
      attrs.write(' DATA-READ="1"');
    }

    buffer.writeln('$indent<DT><A $attrs>$displayTitle</A>');
    if (bookmark.description != null &&
        bookmark.description!.trim().isNotEmpty) {
      buffer.writeln(
          '$indent<DD>${_textEscape.convert(bookmark.description!.trim())}');
    }
  }

  /// Parses a Netscape Bookmark HTML string into structured [ParsedBookmarkEntry] items.
  static List<ParsedBookmarkEntry> parseNetscapeHtml(String htmlContent) {
    final document = html_parser.parse(htmlContent);
    final entries = <ParsedBookmarkEntry>[];

    final rootDl = document.querySelector('dl');
    if (rootDl != null) {
      _walkContainer(rootDl, const [], entries);
      return entries;
    }

    // Fallback: scan anchors if no <DL> wrapper exists.
    for (final anchor in document.querySelectorAll('a[href]')) {
      final entry = _entryFromAnchor(anchor, const []);
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  static void _walkContainer(
    dom.Element container,
    List<String> currentPath,
    List<ParsedBookmarkEntry> entries,
  ) {
    String? pendingFolder;
    ParsedBookmarkEntry? lastEntry;

    void handleElement(dom.Element child) {
      final tag = child.localName?.toLowerCase();
      if (tag == 'dt') {
        final h3 = child.children
            .where((c) => c.localName?.toLowerCase() == 'h3')
            .firstOrNull;
        final anchor = child.children
            .where((c) => c.localName?.toLowerCase() == 'a')
            .firstOrNull;
        final nestedDl = child.children
            .where((c) => c.localName?.toLowerCase() == 'dl')
            .firstOrNull;
        final nestedDd = child.children
            .where((c) => c.localName?.toLowerCase() == 'dd')
            .firstOrNull;

        if (h3 != null) {
          final folderName = BookmarkCollection.sanitizeName(h3.text);
          pendingFolder = folderName.isNotEmpty ? folderName : null;
          lastEntry = null;
          if (nestedDl != null) {
            final nextPath = pendingFolder != null
                ? [...currentPath, pendingFolder!]
                : currentPath;
            pendingFolder = null;
            _walkContainer(nestedDl, nextPath, entries);
          }
          // Handle malformed HTML where <dt> wraps sibling <dt>/<p> elements.
          for (final sub in child.children) {
            final subTag = sub.localName?.toLowerCase();
            if (subTag == 'dt' || subTag == 'p') {
              handleElement(sub);
            }
          }
          return;
        }

        if (anchor != null) {
          final entry = _entryFromAnchor(anchor, currentPath);
          if (entry != null) {
            if (nestedDd != null && nestedDd.text.trim().isNotEmpty) {
              entry.description = nestedDd.text.trim();
            }
            entries.add(entry);
            lastEntry = entry;
          }
          pendingFolder = null;
          for (final sub in child.children) {
            final subTag = sub.localName?.toLowerCase();
            if (subTag == 'dt' || subTag == 'dl' || subTag == 'p') {
              handleElement(sub);
            }
          }
          return;
        }

        if (nestedDl != null) {
          final nextPath = pendingFolder != null
              ? [...currentPath, pendingFolder!]
              : currentPath;
          pendingFolder = null;
          _walkContainer(nestedDl, nextPath, entries);
          return;
        }

        for (final sub in child.children) {
          handleElement(sub);
        }
      } else if (tag == 'dl') {
        final nextPath = pendingFolder != null
            ? [...currentPath, pendingFolder!]
            : currentPath;
        pendingFolder = null;
        lastEntry = null;
        _walkContainer(child, nextPath, entries);
      } else if (tag == 'dd') {
        final desc = child.text.trim();
        if (desc.isNotEmpty && lastEntry != null) {
          lastEntry!.description = desc;
        }
      } else if (tag == 'p') {
        for (final sub in child.children) {
          handleElement(sub);
        }
      }
    }

    for (final child in container.children) {
      handleElement(child);
    }
  }

  static ParsedBookmarkEntry? _entryFromAnchor(
    dom.Element anchor,
    List<String> folderPath,
  ) {
    final rawHref = anchor.attributes['href']?.trim() ?? '';
    final uri = Uri.tryParse(rawHref);
    if (uri == null ||
        (uri.scheme.toLowerCase() != 'http' &&
            uri.scheme.toLowerCase() != 'https') ||
        uri.host.isEmpty) {
      return null;
    }

    final titleText = anchor.text.trim();
    final addDateRaw = anchor.attributes['add_date']?.trim();
    DateTime createdAt = DateTime.now();
    if (addDateRaw != null && addDateRaw.isNotEmpty) {
      final seconds = int.tryParse(addDateRaw);
      if (seconds != null && seconds > 0) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }

    final tagsAttr = anchor.attributes['tags'] ?? '';
    final tags = tagsAttr
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final notes = anchor.attributes['data-notes'] ?? '';
    final isPinned = anchor.attributes['data-pinned'] == '1';
    final isRead = anchor.attributes['data-read'] == '1';

    return ParsedBookmarkEntry(
      url: rawHref,
      title: titleText.isNotEmpty ? titleText : uri.host,
      createdAt: createdAt,
      tags: tags,
      notes: notes,
      isPinned: isPinned,
      isRead: isRead,
      folderPath: List<String>.unmodifiable(folderPath),
    );
  }

  /// Imports parsed Netscape HTML bookmarks into [IsarRepository], creating
  /// missing collections (including nested folders) and skipping duplicate URLs.
  static Future<BookmarkImportResult> importNetscapeHtml({
    required String htmlContent,
    required IsarRepository repository,
  }) async {
    final parsedEntries = parseNetscapeHtml(htmlContent);
    if (parsedEntries.isEmpty) {
      return const BookmarkImportResult(
        importedCount: 0,
        skippedCount: 0,
        collectionsCreated: 0,
      );
    }

    final existingBookmarks = await repository.getBookmarks();
    final existingUrls = <String>{
      for (final b in existingBookmarks) b.url.trim().toLowerCase(),
    };

    final existingCollections = await repository.getAllCollections();
    final collectionLookup = <String, BookmarkCollection>{};
    for (final c in existingCollections) {
      collectionLookup[_collectionKey(c.parentId, c.name)] = c;
    }

    var collectionsCreated = 0;
    var importedCount = 0;
    var skippedCount = 0;

    Future<BookmarkCollection?> resolveFolderPath(List<String> path) async {
      BookmarkCollection? current;
      for (final rawSegment in path) {
        final clean = BookmarkCollection.sanitizeName(rawSegment);
        if (clean.isEmpty) continue;
        final key = _collectionKey(current?.id, clean);
        var match = collectionLookup[key];
        if (match == null) {
          final colorHex = _defaultPalette[
              (existingCollections.length + collectionsCreated) %
                  _defaultPalette.length];
          match = BookmarkCollection()
            ..name = clean
            ..colorHex = colorHex
            ..iconCodePoint = Icons.folder_outlined.codePoint
            ..iconFontFamily = kStoredIconFontFamily
            ..parentId = current?.id
            ..createdAt = DateTime.now();
          await repository.addCollection(match);
          collectionLookup[key] = match;
          collectionsCreated++;
        }
        current = match;
      }
      return current;
    }

    for (final entry in parsedEntries) {
      final normalizedUrl = entry.url.trim().toLowerCase();
      if (existingUrls.contains(normalizedUrl)) {
        skippedCount++;
        continue;
      }

      final targetCollection = await resolveFolderPath(entry.folderPath);
      final uri = Uri.tryParse(entry.url);

      final bookmark = Bookmark()
        ..url = entry.url
        ..title = entry.title
        ..description = entry.description
        ..notes = entry.notes
        ..sourceDomain = uri?.host
        ..createdAt = entry.createdAt
        ..tags = List<String>.from(entry.tags)
        ..isPinned = entry.isPinned
        ..isRead = entry.isRead;

      if (targetCollection != null) {
        bookmark.collection.value = targetCollection;
      }

      await repository.addBookmark(bookmark);
      existingUrls.add(normalizedUrl);
      importedCount++;
    }

    return BookmarkImportResult(
      importedCount: importedCount,
      skippedCount: skippedCount,
      collectionsCreated: collectionsCreated,
    );
  }

  static String _collectionKey(int? parentId, String name) =>
      '${parentId ?? 'root'}::${name.trim().toLowerCase()}';
}
