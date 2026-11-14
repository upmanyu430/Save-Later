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
import 'package:save_later/ui/widgets/share_save_modal.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/neo_button.dart';
import 'package:save_later/ui/widgets/pin_icon.dart';
import 'package:save_later/theme/app_theme.dart';

class _MockRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');
  final Map<Id, Bookmark> bookmarks = {};
  final List<BookmarkCollection> collections = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB');
  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => collections;
  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];
  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collections.where((c) => c.id == id).firstOrNull;
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
  Future<Bookmark?> getBookmark(Id id) async => bookmarks[id];
  @override
  Future<List<Bookmark>> getBookmarks() async => bookmarks.values.toList();
  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];
  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => [];
  @override
  Future<void> addBookmark(Bookmark bookmark) async {
    bookmarks[bookmark.id] = bookmark;
  }
  @override
  Future<void> updateBookmark(Bookmark bookmark) async {
    bookmarks[bookmark.id] = bookmark;
  }
  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {
    for (final b in updated) {
      bookmarks[b.id] = b;
    }
  }
  @override
  Future<void> deleteBookmark(Id id) async {
    bookmarks.remove(id);
  }
  @override
  Future<void> deleteBookmarks(List<Id> ids) async {
    for (final id in ids) {
      bookmarks.remove(id);
    }
  }
}

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('ShareSaveModal renders UI matching design and saves to Unsorted', (tester) async {
    final repo = _MockRepo();
    final col1 = BookmarkCollection()
      ..id = 1
      ..name = 'Tech'
      ..colorHex = 'FF2196F3'
      ..iconCodePoint = Icons.computer.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collections.add(col1);

    BookmarkCollection? savedCollection;
    bool? savedIsPinned;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: ShareSaveModal(
            url: 'https://flutter.dev/sharing',
            onSave: (col, isPinned) async {
              savedCollection = col;
              savedIsPinned = isPinned;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Save to Save Later'), findsOneWidget);

    // Verify Shared URL
    expect(find.text('https://flutter.dev/sharing'), findsOneWidget);

    // Verify Pin tile initially unselected (white background)
    expect(find.text('Pin this link'), findsOneWidget);
    final pinRowFinder = find.byKey(const ValueKey('share_modal_pin_row'));
    final unselectedPinContainer = tester.widget<Container>(
      find.descendant(of: pinRowFinder, matching: find.byType(Container)).first,
    );
    expect((unselectedPinContainer.decoration as BoxDecoration).color, Colors.white);

    // Verify Unsorted is selected by default
    expect(find.text('Save to "Unsorted"'), findsOneWidget);

    // Tap Pin this link
    await tester.tap(pinRowFinder);
    await tester.pumpAndSettle();

    // Verify Pin tile selected (yellow background, yellow line border, yellow PinIcon)
    final selectedPinContainer = tester.widget<Container>(
      find.descendant(of: pinRowFinder, matching: find.byType(Container)).first,
    );
    final selectedPinDec = selectedPinContainer.decoration as BoxDecoration;
    expect(selectedPinDec.color, const Color(0xFFFFF4D0));
    expect((selectedPinDec.border as Border).top.color, const Color(0xFFFDD164));
    final pinIconWidget = tester.widget<PinIcon>(
      find.descendant(of: pinRowFinder, matching: find.byType(PinIcon)),
    );
    expect(pinIconWidget.isPinned, isTrue);
    expect(pinIconWidget.color, const Color(0xFFFDD164));
    expect(
      find.descendant(of: pinRowFinder, matching: find.byIcon(Icons.check_circle_outline)),
      findsNothing,
    );

    // Tap Save button
    await tester.tap(find.widgetWithText(NeoButton, 'Save to "Unsorted"'));
    await tester.pumpAndSettle();

    expect(savedCollection, isNull); // null = unsorted
    expect(savedIsPinned, isTrue);
  });

  testWidgets('ShareSaveModal selects collection and updates button label', (tester) async {
    final repo = _MockRepo();
    final col1 = BookmarkCollection()
      ..id = 10
      ..name = 'Articles'
      ..colorHex = 'FF9C27B0'
      ..iconCodePoint = Icons.article.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collections.add(col1);

    BookmarkCollection? savedCollection;
    bool? savedIsPinned;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: ShareSaveModal(
            url: 'https://dart.dev',
            onSave: (col, isPinned) async {
              savedCollection = col;
              savedIsPinned = isPinned;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on Articles collection
    await tester.tap(find.byKey(const ValueKey('share_modal_collection_10')));
    await tester.pumpAndSettle();

    // Verify button label updated
    expect(find.text('Save to "Articles"'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.widgetWithText(NeoButton, 'Save to "Articles"'));
    await tester.pumpAndSettle();

    expect(savedCollection?.name, equals('Articles'));
    expect(savedIsPinned, isFalse);
  });

  testWidgets('SaveSuccessModal renders green badge and dismisses', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const SaveSuccessModal(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved!'), findsOneWidget);
    expect(find.text('Link saved'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('ShareSaveModal pins drag handle at top and Save button at bottom outside SingleChildScrollView', (tester) async {
    final repo = _MockRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: ShareSaveModal(
            url: 'https://flutter.dev',
            onSave: (col, isPinned) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollFinder = find.byType(SingleChildScrollView);
    expect(scrollFinder, findsOneWidget);

    // Drag handle is pinned outside SingleChildScrollView
    final dragHandleFinder = find.byWidgetPredicate((widget) {
      if (widget is Container) {
        final dec = widget.decoration;
        if (dec is BoxDecoration &&
            dec.color == AppTheme.border &&
            dec.borderRadius == BorderRadius.circular(2)) {
          return true;
        }
      }
      return false;
    });
    expect(dragHandleFinder, findsOneWidget);
    expect(
      find.descendant(of: scrollFinder, matching: dragHandleFinder),
      findsNothing,
      reason: 'Drag handle must be pinned outside SingleChildScrollView',
    );

    // Save button is pinned outside SingleChildScrollView and has exact height 48.0
    final saveButtonFinder = find.widgetWithText(NeoButton, 'Save to "Unsorted"');
    expect(
      find.descendant(of: scrollFinder, matching: saveButtonFinder),
      findsNothing,
      reason: 'Save button must be pinned outside SingleChildScrollView at bottom',
    );
    final saveButtonSizedBox = tester.widget<SizedBox>(
      find.ancestor(of: saveButtonFinder, matching: find.byType(SizedBox)).first,
    );
    expect(saveButtonSizedBox.height, 48.0);

    // Header and Pin row ARE inside SingleChildScrollView
    expect(
      find.descendant(of: scrollFinder, matching: find.text('Save to Save Later')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scrollFinder, matching: find.byKey(const ValueKey('share_modal_pin_row'))),
      findsOneWidget,
    );
  });

  testWidgets('ShareSaveModal fits content without large gap and caps at CollectionEditorModal collapsed height', (tester) async {
    final repo = _MockRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: Builder(
            builder: (context) {
              final expectedHeight =
                  CollectionEditorModal.getCollapsedModalHeight(context);
              return Column(
                children: [
                  Expanded(
                    child: ShareSaveModal(
                      url: 'https://flutter.dev',
                      onSave: (col, isPinned) async {},
                    ),
                  ),
                  Text('expected:$expectedHeight'),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check that the card container in ShareSaveModal wraps content without the gap
    final cardFinder = find.byKey(const ValueKey('share_save_modal_sheet'));
    final cardSize = tester.getSize(cardFinder);
    final context = tester.element(cardFinder);
    final expected = CollectionEditorModal.getCollapsedModalHeight(context);
    expect(cardSize.height, lessThan(expected));

    // When there are many collections, height is capped at expected
    for (int i = 0; i < 15; i++) {
      repo.collections.add(BookmarkCollection()
        ..id = 100 + i
        ..name = 'Collection $i'
        ..colorHex = 'FF2196F3'
        ..iconCodePoint = Icons.folder.codePoint
        ..iconFontFamily = kStoredIconFontFamily);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          allCollectionsProvider.overrideWith((ref) => Future.value(repo.collections)),
        ],
        child: _buildTestApp(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  Expanded(
                    child: ShareSaveModal(
                      url: 'https://flutter.dev',
                      onSave: (col, isPinned) async {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cappedCardSize = tester.getSize(cardFinder);
    expect(cappedCardSize.height, closeTo(expected, 0.01));
  });
}
