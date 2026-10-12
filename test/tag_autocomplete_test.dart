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

class TagTestIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  Bookmark? lastUpdatedBookmark;
  List<Bookmark> mockBookmarks = [];

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
  Future<List<Bookmark>> getBookmarks() async => mockBookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => mockBookmarks;

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

Widget createTestWidget({
  required Bookmark bookmark,
  required TagTestIsarRepository repo,
  List<String> existingTags = const [],
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      bookmarksProvider.overrideWith((ref) async => repo.mockBookmarks),
      allTagsProvider.overrideWith((ref) async => existingTags),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: BookmarkDetailScreen(bookmark: bookmark),
    ),
  );
}

void setScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  testWidgets('renders existing tags as suggestions when add tag sheet opens', (tester) async {
    setScreenSize(tester);
    final repo = TagTestIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://flutter.dev'
      ..title = 'Flutter'
      ..tags = ['Dart'];

    await tester.pumpWidget(
      createTestWidget(
        bookmark: bookmark,
        repo: repo,
        existingTags: ['UI', 'UX', 'Dart', 'Testing'],
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Add" button to open _AddTagSheet
    final addButton = find.text('Add');
    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Check modal opened with "Add Tag" title
    expect(find.text('Add Tag'), findsNWidgets(2)); // Header + Button

    // "Existing Tags" should be visible with 'UI', 'UX', 'Testing' ('Dart' excluded since bookmark already has it)
    expect(find.text('Existing Tags'), findsOneWidget);
    expect(find.text('UI'), findsOneWidget);
    expect(find.text('UX'), findsOneWidget);
    expect(find.text('Testing'), findsOneWidget);

    // Tapping 'UI' suggestion directly adds it
    await tester.tap(find.text('UI'));
    await tester.pumpAndSettle();

    // Sheet should be dismissed and bookmark updated with 'UI'
    expect(repo.lastUpdatedBookmark?.tags, contains('UI'));
  });

  testWidgets('typing a query shows dropdown suggestions', (tester) async {
    setScreenSize(tester);
    final repo = TagTestIsarRepository();
    final bookmark = Bookmark()
      ..id = 2
      ..url = 'https://flutter.dev'
      ..title = 'Flutter'
      ..tags = [];

    await tester.pumpWidget(
      createTestWidget(
        bookmark: bookmark,
        repo: repo,
        existingTags: ['Frontend', 'Backend', 'Flutter', 'Firebase'],
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    final addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Type 'front' into TextField
    final textField = find.byType(TextField).last;
    await tester.enterText(textField, 'front');
    await tester.pumpAndSettle();

    // Suggestion dropdown should show 'Frontend'
    expect(find.text('Frontend'), findsOneWidget);
    expect(find.text('Backend'), findsNothing);

    // Tap the suggestion in dropdown
    await tester.tap(find.text('Frontend'));
    await tester.pumpAndSettle();

    expect(repo.lastUpdatedBookmark?.tags, contains('Frontend'));
  });

  testWidgets('detects duplicate variation (e.g. U.I. when UI exists) and indicates canonical match', (tester) async {
    setScreenSize(tester);
    final repo = TagTestIsarRepository();
    final bookmark = Bookmark()
      ..id = 3
      ..url = 'https://flutter.dev'
      ..title = 'Flutter'
      ..tags = [];

    await tester.pumpWidget(
      createTestWidget(
        bookmark: bookmark,
        repo: repo,
        existingTags: ['UI', 'Mobile'],
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    final addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // User types "u.i."
    final textField = find.byType(TextField).last;
    await tester.enterText(textField, 'u.i.');
    await tester.pumpAndSettle();

    // Should display canonical match indicator
    expect(find.text('Will use existing tag: "UI"'), findsOneWidget);

    // Tap "Add Tag" button
    final addTagButton = find.text('Add Tag').last;
    await tester.tap(addTagButton);
    await tester.pumpAndSettle();

    // Bookmark should receive canonical 'UI' instead of 'u.i.'
    expect(repo.lastUpdatedBookmark?.tags, contains('UI'));
    expect(repo.lastUpdatedBookmark?.tags.contains('u.i.'), isFalse);
  });

  testWidgets('blocks adding tag if bookmark already contains variation', (tester) async {
    setScreenSize(tester);
    final repo = TagTestIsarRepository();
    final bookmark = Bookmark()
      ..id = 4
      ..url = 'https://flutter.dev'
      ..title = 'Flutter'
      ..tags = ['UI'];

    await tester.pumpWidget(
      createTestWidget(
        bookmark: bookmark,
        repo: repo,
        existingTags: ['UI'],
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    final addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // User types "u.i."
    final textField = find.byType(TextField).last;
    await tester.enterText(textField, 'u.i.');
    await tester.pumpAndSettle();

    // Should display warning that tag is already on bookmark
    expect(find.text('This tag is already added to this bookmark'), findsOneWidget);

    // Tap "Add Tag" button
    final addTagButton = find.text('Add Tag').last;
    await tester.tap(addTagButton);
    await tester.pumpAndSettle();

    // Nothing was updated because button was disabled / blocked
    expect(repo.lastUpdatedBookmark, isNull);
  });
}
