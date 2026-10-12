import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/icon_picker_screen.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';

class MockModalRepository implements IsarRepository {
  final List<BookmarkCollection> collections = [];

  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => List.from(collections);

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    if (collection.id == Isar.autoIncrement) {
      collection.id = collections.length + 1;
    }
    collections.add(collection);
  }

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
  Future<void> deleteBookmark(Id bookmarkId) async {}

  @override
  Future<void> deleteBookmarks(List<Id> bookmarkIds) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockModalRepository repo;

  setUp(() {
    repo = MockModalRepository();
  });

  Widget buildTestWidget({required Widget child}) {
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
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('CollectionEditorModal shows 3-dots icon in grid and opens full page IconPickerScreen on tap', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: const Scaffold(
          body: CollectionEditorModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 dots icon is rendered in the icon grid
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    // Scroll to and tap the 3 dots icon
    await tester.ensureVisible(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    // Verify IconPickerScreen full page opened
    expect(find.byType(IconPickerScreen), findsOneWidget);
    expect(find.text('Choose Icon'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Tech & Code'), findsOneWidget);

    // Search for code
    await tester.enterText(find.byType(TextField).last, 'code');
    await tester.pumpAndSettle();

    // Find the code icon and tap it
    expect(find.byIcon(Icons.code), findsOneWidget);
    await tester.tap(find.byIcon(Icons.code));
    await tester.pumpAndSettle();

    // Verify IconPickerScreen closed and returned to CollectionEditorModal
    expect(find.byType(IconPickerScreen), findsNothing);
    expect(find.byType(CollectionEditorModal), findsOneWidget);

    // Verify the code icon is now visible in CollectionEditorModal in the 24th slot
    expect(find.byIcon(Icons.code), findsOneWidget);

    // Fill in name and create collection
    await tester.enterText(find.byType(TextField).first, 'Coding Resources');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create collection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create collection'));
    await tester.pumpAndSettle();

    // Verify collection was added with the code icon's code point
    expect(repo.collections.length, 1);
    expect(repo.collections.first.name, 'Coding Resources');
    expect(repo.collections.first.iconCodePoint, Icons.code.codePoint);
  });

  testWidgets('IconPickerScreen category filtering and Select Icon button', (tester) async {
    int? returnedCode;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedCode = await Navigator.push<int>(
                context,
                MaterialPageRoute(
                  builder: (context) => const IconPickerScreen(
                    selectedColorHex: 'FFD166',
                    currentIconCode: 0xe2c7,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify IconPickerScreen is visible
    expect(find.byType(IconPickerScreen), findsOneWidget);

    // Tap Travel category
    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();

    // Verify travel icon is shown
    expect(find.byIcon(Icons.flight_takeoff), findsOneWidget);

    // Tap airplane icon
    await tester.tap(find.byIcon(Icons.flight_takeoff));
    await tester.pumpAndSettle();

    // Verify it popped and returned airplane icon
    expect(returnedCode, Icons.flight_takeoff.codePoint);
  });

  testWidgets('CollectionEditorModal with existing collection having custom icon shows that icon in slot 24', (tester) async {
    final existing = BookmarkCollection()
      ..id = 99
      ..name = 'Gaming Hub'
      ..colorHex = '4A90E2'
      ..iconCodePoint = Icons.sports_esports_outlined.codePoint;

    await tester.pumpWidget(
      buildTestWidget(
        child: Scaffold(
          body: CollectionEditorModal(existingCollection: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the custom icon is displayed in the modal
    expect(find.byIcon(Icons.sports_esports_outlined), findsOneWidget);
    // Since custom icon is selected, more_horiz is replaced by the custom icon
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });
}

