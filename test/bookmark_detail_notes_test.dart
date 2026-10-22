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
    lastUpdatedBookmark = bookmark;
  }

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
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
  testWidgets('BookmarkDetailScreen saves notes on onChanged and onEditingComplete', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example Title'
      ..notes = 'Initial note';

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
    textField.onTap?.call();
    await tester.pump();
    final editableTextField = tester.widget<TextField>(find.byType(TextField));
    editableTextField.controller!.text = 'Updated note via onChanged';
    editableTextField.onChanged?.call('Updated note via onChanged');
    await tester.pump(const Duration(milliseconds: 500));
    expect(fakeRepo.lastUpdatedBookmark?.notes, 'Updated note via onChanged');

    // Test onEditingComplete trigger
    editableTextField.onEditingComplete?.call();
    expect(fakeRepo.lastUpdatedBookmark?.notes, 'Updated note via onChanged');
  });

  testWidgets('Cancel and Save buttons appear on upper side of note box during editing', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));

    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 2
      ..url = 'https://example.com/2'
      ..title = 'Note Box Test'
      ..notes = 'Hello Note';

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

    // Initially buttons should not be present
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Save'), findsNothing);

    // Scroll down so notes section is fully visible
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final noteBoxFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'Hello Note',
    );
    await tester.tap(noteBoxFinder);
    await tester.pumpAndSettle();

    // Now Cancel and Save buttons should be visible
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Verify Cancel and Save buttons are positioned above the note box
    final cancelCenter = tester.getCenter(find.text('Cancel'));
    final noteBoxTop = tester.getTopLeft(noteBoxFinder);
    expect(cancelCenter.dy < noteBoxTop.dy, isTrue, reason: 'Buttons must be on the upper side of the note box');

    // Tap Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Buttons should disappear after cancel
    expect(find.text('Cancel'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });
}

