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
import 'package:save_later/ui/screens/review_mode_screen.dart';
import 'package:save_later/theme/app_theme.dart';

class FakeIsarRepository implements IsarRepository {
  final List<Bookmark> bookmarks = [];

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
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks.toList();

  Future<List<Bookmark>> getUnreadBookmarks() async =>
      bookmarks.where((b) => !b.isRead).toList();

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks.add(bookmark);
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    final idx = bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (idx >= 0) {
      bookmarks[idx] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
  }

  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    await saveBookmark(bookmark);
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    for (final b in updated) {
      await updateBookmark(b);
    }
  }

  @override
  Future<void> deleteBookmark(Id id) async {
    bookmarks.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    bookmarks.removeWhere((b) => ids.contains(b.id));
  }
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
  testWidgets('ReviewModeScreen displays solid color swatch without icon inside for named collection', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final collection = BookmarkCollection()
      ..id = 10
      ..name = 'Code'
      ..colorHex = '#000000'
      ..iconCodePoint = Icons.code.codePoint;

    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Code Bookmark'
      ..isRead = false;
    bookmark.collection.value = collection;

    fakeRepo.bookmarks.add(bookmark);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          collectionBookmarksProvider(10).overrideWith((ref) => Future.value([bookmark])),
        ],
        child: buildTestApp(
          home: ReviewModeScreen(collection: collection),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "Code" badge text
    expect(find.text('Code'), findsOneWidget);

    // Locate the swatch Container (16x16 with collection color)
    final swatchFinder = find.byWidgetPredicate((w) {
      if (w is Container && w.decoration is BoxDecoration) {
        final dec = w.decoration as BoxDecoration;
        return dec.color == const Color(0xFF000000) &&
            dec.border == Border.all(color: AppTheme.border, width: 2);
      }
      return false;
    });

    expect(swatchFinder, findsOneWidget);

    // Verify that NO Icon widget is inside the swatch container
    final iconInsideSwatch = find.descendant(
      of: swatchFinder,
      matching: find.byType(Icon),
    );
    expect(iconInsideSwatch, findsNothing);

    // Verify badge container padding has horizontal 10 (no excessive left gap)
    final badgeContainerFinder = find.ancestor(
      of: swatchFinder,
      matching: find.byWidgetPredicate((w) => w is Container && w.padding == const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
    );
    expect(badgeContainerFinder, findsOneWidget);
  });

  testWidgets('ReviewModeScreen displays solid color swatch #E5E5E5 without icon for Unsorted', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Unsorted Bookmark'
      ..isRead = false;

    fakeRepo.bookmarks.add(bookmark);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([bookmark])),
        ],
        child: buildTestApp(
          home: const ReviewModeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "UNSORTED" top bar header text and no "NEW SAVES"
    expect(find.text('UNSORTED'), findsOneWidget);
    expect(find.text('NEW SAVES'), findsNothing);

    // Verify "Unsorted" badge text
    expect(find.text('Unsorted'), findsOneWidget);

    // Locate the swatch Container (16x16 with #E5E5E5)
    final swatchFinder = find.byWidgetPredicate((w) {
      if (w is Container && w.decoration is BoxDecoration) {
        final dec = w.decoration as BoxDecoration;
        return dec.color == const Color(0xFFE5E5E5) &&
            dec.border == Border.all(color: AppTheme.border, width: 2);
      }
      return false;
    });

    expect(swatchFinder, findsOneWidget);

    // Verify that NO Icon widget is inside the swatch container
    final iconInsideSwatch = find.descendant(
      of: swatchFinder,
      matching: find.byType(Icon),
    );
    expect(iconInsideSwatch, findsNothing);

    // Verify badge container padding has horizontal 10 (no excessive left gap)
    final badgeContainerFinder = find.ancestor(
      of: swatchFinder,
      matching: find.byWidgetPredicate((w) => w is Container && w.padding == const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
    );
    expect(badgeContainerFinder, findsOneWidget);
  });

  testWidgets('ReviewModeScreen displays bookmarks in Unsorted even when they are marked as read', (tester) async {
    final fakeRepo = FakeIsarRepository();
    final readBookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com/read'
      ..title = 'Already Read Unsorted Bookmark'
      ..isRead = true;

    fakeRepo.bookmarks.add(readBookmark);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([readBookmark])),
        ],
        child: buildTestApp(
          home: const ReviewModeScreen(collection: null),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "UNSORTED" top bar header text and no "NEW SAVES"
    expect(find.text('UNSORTED'), findsOneWidget);
    expect(find.text('NEW SAVES'), findsNothing);

    // Verify the card is visible with its title, rather than caught up screen
    expect(find.text('Already Read Unsorted Bookmark'), findsOneWidget);
    expect(find.text('Unsorted'), findsOneWidget);
    expect(find.text("You're all caught up!"), findsNothing);
  });
}
