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
import 'package:save_later/ui/widgets/bookmark_grid_item.dart';

class _FakeSavingRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

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

void main() {
  testWidgets('BookmarkGridItem renders SAVING... badge and spinner when actively saving', (tester) async {
    final repo = _FakeSavingRepo();
    final bookmark = Bookmark()
      ..id = 99
      ..url = 'https://appllama.io/'
      ..title = 'https://appllama.io/'
      ..sourceDomain = 'appllama.io';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          savingBookmarkIdsProvider.overrideWith((ref) => {99}),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 220,
              child: BookmarkGridItem(bookmark: bookmark),
            ),
          ),
        ),
      ),
    );

    // Let entrance animations settle
    await tester.pump(const Duration(milliseconds: 500));

    // Verify SAVING... badge is displayed
    expect(find.text('SAVING...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Initial letter from sourceDomain 'appllama.io' (size 36)
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'A' && w.style?.fontSize == 36),
      findsOneWidget,
    );
    expect(find.text('https://appllama.io/'), findsOneWidget);
  });

  testWidgets('BookmarkGridItem hides SAVING... badge when not saving', (tester) async {
    final repo = _FakeSavingRepo();
    final bookmark = Bookmark()
      ..id = 100
      ..url = 'https://appllama.io/'
      ..title = 'Appllama - Discover app designs'
      ..sourceDomain = 'appllama.io';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          savingBookmarkIdsProvider.overrideWith((ref) => <int>{}),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 220,
              child: BookmarkGridItem(bookmark: bookmark),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // SAVING... should not be rendered
    expect(find.text('SAVING...'), findsNothing);
    expect(find.text('Appllama - Discover app designs'), findsOneWidget);
  });
}
