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
import 'package:save_later/ui/widgets/neo_button.dart';
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';

class _FakeRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');
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
  testWidgets('BookmarkGridItem renders REFRESHING... badge and spinner when actively refreshing', (tester) async {
    final repo = _FakeRepo();
    final bookmark = Bookmark()
      ..id = 42
      ..url = 'https://flutter.dev/'
      ..title = 'Flutter'
      ..sourceDomain = 'flutter.dev';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          refreshingBookmarkIdsProvider.overrideWith((ref) => {42}),
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

    // Verify REFRESHING... badge is displayed
    expect(find.text('REFRESHING...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // SourceDomain initial letter is shown
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'F' && w.style?.fontSize == 36),
      findsOneWidget,
    );
  });

  testWidgets('BookmarkGridItem hides REFRESHING... badge when not refreshing', (tester) async {
    final repo = _FakeRepo();
    final bookmark = Bookmark()
      ..id = 43
      ..url = 'https://flutter.dev/'
      ..title = 'Flutter - Build apps for any screen'
      ..sourceDomain = 'flutter.dev';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          refreshingBookmarkIdsProvider.overrideWith((ref) => <int>{}),
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

    expect(find.text('REFRESHING...'), findsNothing);
    expect(find.text('Flutter - Build apps for any screen'), findsOneWidget);
  });

  testWidgets('BookmarkDetailScreen Refresh button shows dialog, and Refresh button triggers refresh and pops', (tester) async {
    final repo = _FakeRepo();
    final bookmark = Bookmark()
      ..id = 55
      ..url = 'https://example.com/'
      ..title = 'Example Bookmark'
      ..sourceDomain = 'example.com';

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
          supportedLocales: const [Locale('en', '')],
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => BookmarkDetailScreen(bookmark: bookmark),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify detail screen is loaded
    expect(find.text('Example Bookmark'), findsWidgets);

    // Tap the Refresh action item in the bottom strip
    final refreshAction = find.text('Refresh');
    expect(refreshAction, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(refreshAction));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify confirmation dialog appeared
    expect(find.text('Refresh link metadata?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Tap Refresh button in dialog
    final dialogRefreshBtn = find.widgetWithText(NeoButton, 'Refresh');
    expect(dialogRefreshBtn, findsOneWidget);
    await tester.tap(dialogRefreshBtn);
    await tester.pump();

    // Dialog is popped and screen should pop
    await tester.pumpAndSettle();
    expect(find.text('Refresh link metadata?'), findsNothing);
  });
}
