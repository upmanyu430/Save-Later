import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/collection_grid_item.dart';
import 'package:save_later/ui/widgets/collection_radial_menu.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CollectionTestIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];
  int deleteCollectionCallCount = 0;

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections() async =>
      List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    deleteCollectionCallCount++;
    collections.removeWhere((c) => c.id == collectionId);
  }

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

Widget createTestApp({
  required Widget child,
  required CollectionTestIsarRepository repo,
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
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  late CollectionTestIsarRepository testRepo;
  late BookmarkCollection testCollection;

  setUp(() {
    testRepo = CollectionTestIsarRepository();
    testCollection = BookmarkCollection()
      ..id = 1
      ..name = 'Design Resources'
      ..colorHex = 'FFD166'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = 'MaterialIcons';
    testRepo.collections.add(testCollection);
  });

  tearDown(() {
    CollectionRadialMenu.dismiss();
  });

  testWidgets(
      'Long press on CollectionGridItem displays radial menu with Edit, Share, and Delete buttons',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Design Resources'), findsOneWidget);

    // Perform long press to open CollectionRadialMenu
    final itemFinder = find.byType(CollectionGridItem);
    await tester.longPress(itemFinder);
    await tester.pumpAndSettle();

    // Verify all 3 action icons are present in the radial menu
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('Tapping Edit button in radial menu opens CollectionEditorModal',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CollectionGridItem));
    await tester.pumpAndSettle();

    // Tap the Edit button
    await tester.tap(find.byIcon(Icons.edit), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify CollectionEditorModal is shown
    expect(find.byType(CollectionEditorModal), findsOneWidget);
    expect(find.text('Design Resources'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'Tapping Delete button in radial menu opens DeleteConfirmationDialog',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CollectionGridItem));
    await tester.pumpAndSettle();

    // Tap the Delete button
    await tester.tap(find.byIcon(Icons.delete_outline), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify DeleteConfirmationDialog is shown
    expect(find.byType(DeleteConfirmationDialog), findsOneWidget);
  });

  testWidgets('Tapping background dismisses the radial menu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CollectionGridItem));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsOneWidget);

    // Tap outside (top-left background at 10, 10)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Menu should be dismissed
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets(
      'Hovering finger over button displays uppercase action label in center',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CollectionGridItem));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit), findsOneWidget);

    final editPos = tester.getCenter(find.byIcon(Icons.edit));
    CollectionRadialMenu.updatePosition(editPos);
    await tester.pump();

    // Verify EDIT label is rendered in the center of the screen
    expect(find.text('EDIT'), findsOneWidget);

    // Test handleLongPressEnd executes the selected action
    CollectionRadialMenu.handleLongPressEnd();
    await tester.pumpAndSettle();

    expect(find.byType(CollectionEditorModal), findsOneWidget);
  });

  testWidgets(
      'Radial menu buttons maintain balanced equidistant spacing',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        child: Center(
          child: SizedBox(
            width: 180,
            height: 160,
            child: CollectionGridItem(
              collection: testCollection,
              itemCount: 4,
              hasNewItems: false,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CollectionGridItem));
    await tester.pumpAndSettle();

    final editCenter = tester.getCenter(find.byIcon(Icons.edit));
    final shareCenter = tester.getCenter(find.byIcon(Icons.share));
    final deleteCenter = tester.getCenter(find.byIcon(Icons.delete_outline));

    final distEditShare = (editCenter - shareCenter).distance;
    final distShareDelete = (shareCenter - deleteCenter).distance;

    // Center-to-center distance should be equal (~78.0 dp)
    expect((distEditShare - distShareDelete).abs(), lessThan(1.0));
    expect(distEditShare, closeTo(78.0, 1.0));

    // Inter-button gap with button diameter 62.0 dp (2 * 31.0)
    final gap = distEditShare - 62.0;
    expect(gap, closeTo(16.0, 4.0));
  });
}
