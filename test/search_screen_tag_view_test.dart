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
import 'package:save_later/ui/screens/search_screen.dart';
import 'package:save_later/ui/widgets/neo_tag_badge.dart';

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
  Future<BookmarkCollection?> getCollection(Id id) async => null;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => collections;

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    collections.removeWhere((c) => c.id == collectionId);
  }

  @override
  Future<Bookmark?> getBookmark(Id id) async {
    try {
      return bookmarks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks;

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks.add(bookmark);
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
  group('SearchScreen Tags View', () {
    testWidgets('Tapping Tags stat switches to Tags view with highlighted card and tag badges', (tester) async {
      final fakeRepo = FakeIsarRepository();

      final bookmark1 = Bookmark()
        ..id = 1
        ..title = 'Pasta Carbonara'
        ..url = 'https://recipes.com/carbonara'
        ..tags = ['recipes', 'cooking'];

      final bookmark2 = Bookmark()
        ..id = 2
        ..title = 'Tokyo Trip Guide'
        ..url = 'https://travel.com/tokyo'
        ..tags = ['travel', 'japan'];

      final bookmark3 = Bookmark()
        ..id = 3
        ..title = 'Pizza Dough'
        ..url = 'https://recipes.com/pizza'
        ..tags = ['recipes'];

      fakeRepo.bookmarks.addAll([bookmark1, bookmark2, bookmark3]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: buildTestApp(
            home: const SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in Overview mode: shows RECENTLY SAVED
      expect(find.text('RECENTLY SAVED'), findsOneWidget);
      expect(find.text('TAGS'), findsNothing);

      // Verify stats: 4 unique tags (recipes, cooking, travel, japan)
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);

      // Tap on Tags stat tab
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();

      // Now TAGS section is displayed!
      expect(find.text('TAGS'), findsOneWidget);
      expect(find.text('RECENTLY SAVED'), findsNothing);

      // Verify the tag badges are present with counts
      expect(find.text('#recipes'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // recipes has count 2
      expect(find.text('#travel'), findsOneWidget);
      expect(find.text('#cooking'), findsOneWidget);
      expect(find.text('#japan'), findsOneWidget);

      // Tap Overview button to return
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      // Back to Overview mode
      expect(find.text('RECENTLY SAVED'), findsOneWidget);
      expect(find.text('TAGS'), findsNothing);
    });

    testWidgets('Tapping a tag badge populates search field and filters bookmarks', (tester) async {
      final fakeRepo = FakeIsarRepository();

      final bookmark1 = Bookmark()
        ..id = 1
        ..title = 'Pasta Carbonara'
        ..url = 'https://recipes.com/carbonara'
        ..tags = ['recipes'];

      final bookmark2 = Bookmark()
        ..id = 2
        ..title = 'Tokyo Trip Guide'
        ..url = 'https://travel.com/tokyo'
        ..tags = ['travel'];

      fakeRepo.bookmarks.addAll([bookmark1, bookmark2]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: buildTestApp(
            home: const SearchScreen(initialTab: LibraryTab.tags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In tags view
      expect(find.text('TAGS'), findsOneWidget);
      expect(find.text('#recipes'), findsOneWidget);

      // Tap on '#recipes' tag
      await tester.tap(find.text('#recipes'));
      await tester.pumpAndSettle();

      // Search bar should now contain 'recipes'
      expect(find.text('recipes'), findsWidgets);
      // Results should show Pasta Carbonara, but not Tokyo Trip Guide
      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Tokyo Trip Guide'), findsNothing);
    });

    testWidgets('When library has no tags, sample tags from design mockup are displayed', (tester) async {
      final fakeRepo = FakeIsarRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: buildTestApp(
            home: const SearchScreen(initialTab: LibraryTab.tags),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // TAGS header is present
      expect(find.text('TAGS'), findsOneWidget);

      // Sample tags from image are rendered
      expect(find.text('#recipes'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('#travel'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('#design'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('#japan'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('#reading list'), findsOneWidget);
      expect(find.text('#interior'), findsOneWidget);
      expect(find.text('#workout'), findsOneWidget);
      expect(find.text('#coffee'), findsOneWidget);
      expect(find.text('#gift ideas'), findsOneWidget);
      expect(find.text('#weeknight'), findsOneWidget);
      expect(find.text('#typography'), findsOneWidget);
      expect(find.text('#beach'), findsOneWidget);
      expect(find.text('#podcast'), findsOneWidget);
      expect(find.text('#music'), findsOneWidget);
      expect(find.text('#diy'), findsOneWidget);
    });
  });

  group('NeoTagBadge widget', () {
    testWidgets('Renders tag with custom color, text color, and count', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoTagBadge(
                name: 'customtag',
                count: 42,
                color: const Color(0xFFFF7E33),
                tilt: -0.035,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('#customtag'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      await tester.tap(find.text('#customtag'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
