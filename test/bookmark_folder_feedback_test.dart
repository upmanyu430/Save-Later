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
import 'package:save_later/ui/widgets/folder_box.dart';
import 'package:save_later/ui/widgets/bookmark_grid_item.dart';
import 'package:save_later/ui/widgets/neo_pressable.dart';

class FakeIsarRepository implements IsarRepository {
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
  Future<void> updateBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {}

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

void main() {
  testWidgets('FolderBox renders NeoPressable and responds to mechanical press tap cycle', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 140,
              child: FolderBox(
                title: 'Design Inspo',
                itemCountText: '12 items',
                folderColor: Colors.blue,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify NeoPressable is present in FolderBox
    expect(find.byType(NeoPressable), findsOneWidget);
    expect(find.text('Design Inspo'), findsOneWidget);

    // Tap down on the folder
    final folderFinder = find.text('Design Inspo');
    final gesture = await tester.startGesture(tester.getCenter(folderFinder));
    await tester.pump(const Duration(milliseconds: 70));

    // Tap has not executed yet during downstroke
    expect(tapped, isFalse);

    // Release finger
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    // Spring reverse in progress
    await tester.pumpAndSettle();

    // Tap callback should have fired after spring bounce
    expect(tapped, isTrue);
  });

  testWidgets('BookmarkGridItem renders NeoPressable and responds to mechanical press feedback', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 42
      ..url = 'https://example.com'
      ..title = 'Cool Web Article';

    bool selectTapped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
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
            body: Center(
              child: SizedBox(
                width: 170,
                height: 180,
                child: BookmarkGridItem(
                  bookmark: bookmark,
                  isSelectMode: true,
                  onSelectTapped: () {
                    selectTapped = true;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(NeoPressable), findsOneWidget);
    expect(find.text('Cool Web Article'), findsOneWidget);

    // Press down
    final cardFinder = find.text('Cool Web Article');
    final gesture = await tester.startGesture(tester.getCenter(cardFinder));
    await tester.pump(const Duration(milliseconds: 70));
    expect(selectTapped, isFalse);

    // Release and spring back
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectTapped, isTrue);
  });
}
