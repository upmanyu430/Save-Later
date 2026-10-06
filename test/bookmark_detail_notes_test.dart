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
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';

class FakeIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  Bookmark? lastUpdatedBookmark;

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections() async => [];

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

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
    lastUpdatedBookmark = bookmark;
  }

  @override
  Future<void> deleteBookmark(Id id) async {}
}

void main() {
  testWidgets('BookmarkDetailScreen saves notes on onChanged and onEditingComplete', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example Title'
      ..description = 'Initial note';

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
          home: BookmarkDetailScreen(bookmark: bookmark),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial note is loaded in the notes text field
    final textFieldFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'Initial note',
    );
    expect(textFieldFinder, findsOneWidget);

    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.onChanged, isNotNull);
    expect(textField.onEditingComplete, isNotNull);

    // Test onChanged trigger
    await tester.enterText(textFieldFinder, 'Updated note via onChanged');
    expect(fakeRepo.lastUpdatedBookmark?.description, 'Updated note via onChanged');

    // Test onEditingComplete trigger
    textField.onEditingComplete?.call();
    expect(fakeRepo.lastUpdatedBookmark?.description, 'Updated note via onChanged');
  });
}
