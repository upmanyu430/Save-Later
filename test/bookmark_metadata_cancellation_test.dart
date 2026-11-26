import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/utils/url_helper.dart';

class _Repo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<Bookmark> added = [];
  final List<Bookmark> updated = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');
  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => [];
  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];
  @override
  Future<BookmarkCollection?> getCollection(Id id) async => null;
  @override
  Future<List<BookmarkCollection>> getAllCollections() async => [];
  @override
  Future<void> addCollection(BookmarkCollection collection) async {}
  @override
  Future<void> deleteCollection(Id collectionId) async {}
  @override
  Future<Bookmark?> getBookmark(Id id) async => null;
  @override
  Future<List<Bookmark>> getBookmarks() async => List.from(added);
  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];
  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => List.from(added);
  @override
  Future<void> addBookmark(Bookmark bookmark) async => added.add(bookmark);
  @override
  Future<void> updateBookmark(Bookmark bookmark) async => updated.add(bookmark);
  @override
  Future<void> updateBookmarks(List<Bookmark> bookmarks) async {}
  @override
  Future<void> deleteBookmark(Id id) async {}
  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

class _HangingMetadataFetcher implements MetadataFetcher {
  MetadataCancelToken? lastToken;
  final Completer<String> resolveCompleter = Completer<String>();

  @override
  Future<String> resolveFinalUrl(
    String url, {
    Duration timeout = const Duration(seconds: 4),
    MetadataCancelToken? cancelToken,
  }) {
    lastToken = cancelToken;
    cancelToken?.addListener(() {
      if (!resolveCompleter.isCompleted) {
        resolveCompleter.complete(url);
      }
    });
    return resolveCompleter.future;
  }

  @override
  Future<Metadata?> fetchMetadata(
    String url, {
    Duration timeout = const Duration(seconds: 8),
    MetadataCancelToken? cancelToken,
  }) async =>
      null;
}

void main() {
  test('BookmarkNotifier cancels in-flight metadata fetch when disposed', () async {
    final repo = _Repo();
    final fetcher = _HangingMetadataFetcher();
    final container = ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        metadataFetcherProvider.overrideWithValue(fetcher),
      ],
    );

    await container
        .read(bookmarkNotifierProvider.notifier)
        .quickSave('https://example.com/slow');

    expect(fetcher.lastToken, isNotNull);
    expect(fetcher.lastToken!.isCancelled, isFalse);

    container.dispose();

    expect(fetcher.lastToken!.isCancelled, isTrue);
    expect(repo.updated, isEmpty);
  });

  testWidgets(
      'Widget disposal cancels real UrlHelper timeout timer without leaving pending timers',
      (tester) async {
    final repo = _Repo();

    await tester.pumpWidget(
      ProviderScope(
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
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () {
                ref
                    .read(bookmarkNotifierProvider.notifier)
                    .quickSave('https://example.com/unmocked');
              },
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    // Dispose ProviderScope immediately while background metadata fetch is running.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(repo.added.length, 1);
  });
}
