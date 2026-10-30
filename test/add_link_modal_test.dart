import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/neo_box.dart';
import 'package:save_later/ui/widgets/neo_button.dart';

class MockAddLinkRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];
  final List<String> savedUrls = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async =>
      List.from(collections.where((c) => parentId != null ? c.parentId == parentId : c.parentId == null));

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async =>
      List.from(collections.where((c) => c.parentId == parentId));

  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collections.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async =>
      List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {}

  @override
  Future<Bookmark?> getBookmark(Id id) async => null;

  @override
  Future<List<Bookmark>> getBookmarks() async => List.from(bookmarks);

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async =>
      bookmarks.where((b) => b.collection.value?.id == collectionId).toList();

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async =>
      bookmarks.where((b) => b.collection.value == null).toList();

  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    savedUrls.add(bookmark.url);
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

Widget createAddLinkTestApp({
  required Widget child,
  required IsarRepository repo,
}) {
  return ProviderScope(
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAddLinkRepository testRepo;
  late BookmarkCollection testCollection;

  setUp(() {
    testRepo = MockAddLinkRepository();
    testCollection = BookmarkCollection()
      ..id = 101
      ..name = 'Articles'
      ..colorHex = 'FFD166'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = 'MaterialIcons';
    testRepo.collections.add(testCollection);
  });

  testWidgets('AddLinkModal renders Neo-Brutalist input styling, Paste button, and Save NeoButton',
      (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: AddLinkModal(
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Add Link to Collection'), findsOneWidget);

    // Verify NeoBox styling for the input
    expect(find.byType(NeoBox), findsOneWidget);

    // Verify TextField with hint
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('https://...'), findsOneWidget);

    // Verify Paste button (IconButton with icon & 'Paste' text)
    expect(find.byIcon(Icons.paste_outlined), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);

    // Verify Save NeoButton
    expect(find.widgetWithText(NeoButton, 'Save'), findsOneWidget);

    // Verify Close button
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('Tapping Paste button populates TextField from clipboard', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.getData') {
          return const <String, dynamic>{'text': 'https://flutter.dev/gems'};
        }
        return null;
      },
    );

    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: AddLinkModal(
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Paste button
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();

    // Verify text field got populated
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'https://flutter.dev/gems');
  });

  testWidgets('Empty input triggers UrlHelper validation and shows showNoUrlDialog', (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: AddLinkModal(
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Save with empty input
    await tester.tap(find.widgetWithText(NeoButton, 'Save'));
    await tester.pumpAndSettle();

    // Verify No URL dialog is displayed
    expect(find.text('No URL'), findsOneWidget);
    expect(find.text('Please enter a link to save'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('No URL'), findsNothing);
  });

  testWidgets('Invalid URL triggers UrlHelper validation and shows showNoUrlDialog', (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: AddLinkModal(
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter invalid text
    await tester.enterText(find.byType(TextField), 'just some random words');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.widgetWithText(NeoButton, 'Save'));
    await tester.pumpAndSettle();

    // Verify No URL dialog is displayed
    expect(find.text('No URL'), findsOneWidget);
    expect(find.text('Please enter a link to save'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('No URL'), findsNothing);
  });

  testWidgets('Valid URL saves successfully via Save NeoButton and pops modal', (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (modalCtx) => AddLinkModal(
                  collection: testCollection,
                  parentContext: context,
                ),
              );
            },
            child: const Text('Open Modal'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Enter valid URL
    await tester.enterText(find.byType(TextField), 'https://dart.dev');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.widgetWithText(NeoButton, 'Save'));
    await tester.pumpAndSettle();

    // Modal should be dismissed
    expect(find.text('Add Link to Collection'), findsNothing);

    // SnackBar should be displayed
    expect(find.text('Saving link...'), findsOneWidget);
  });

  testWidgets('Valid URL saves successfully via keyboard onSubmitted', (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (modalCtx) => AddLinkModal(
                  collection: testCollection,
                  parentContext: context,
                ),
              );
            },
            child: const Text('Open Modal'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Enter valid URL and submit via keyboard
    await tester.enterText(find.byType(TextField), 'github.com/flutter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Modal should be dismissed
    expect(find.text('Add Link to Collection'), findsNothing);

    // SnackBar should be displayed
    expect(find.text('Saving link...'), findsOneWidget);
  });

  testWidgets('Tapping Add Link from CollectionDetailScreen menu opens AddLinkModal', (tester) async {
    await tester.pumpWidget(
      createAddLinkTestApp(
        repo: testRepo,
        child: CollectionDetailScreen(
          collectionId: testCollection.id,
          collection: testCollection,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open top right menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Add Link
    expect(find.text('Add Link'), findsOneWidget);
    await tester.tap(find.text('Add Link'));
    await tester.pumpAndSettle();

    // Verify AddLinkModal opens with all elements
    expect(find.text('Add Link to Collection'), findsOneWidget);
    expect(find.byType(NeoBox), findsOneWidget);
    expect(find.byIcon(Icons.paste_outlined), findsOneWidget);
    expect(find.widgetWithText(NeoButton, 'Save'), findsOneWidget);

    // Tap close button (X)
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Modal should be dismissed
    expect(find.text('Add Link to Collection'), findsNothing);
  });
}
