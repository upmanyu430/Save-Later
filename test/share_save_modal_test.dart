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
import 'package:save_later/ui/widgets/neo_button.dart';

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

    // Verify Pin row
    expect(find.text('Pin this link'), findsOneWidget);

    // Verify Unsorted is selected by default
    expect(find.text('Save to "Unsorted"'), findsOneWidget);

    // Tap Pin this link
    await tester.tap(find.byKey(const ValueKey('share_modal_pin_row')));
    await tester.pumpAndSettle();

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
}
