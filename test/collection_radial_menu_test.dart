import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async =>
      List.from(collections.where((c) => parentId != null ? c.parentId == parentId : c.parentId == null));

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async =>
      List.from(collections.where((c) => c.parentId == parentId));

  @override
  Future<List<BookmarkCollection>> getAllCollections() async =>
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
  GlobalKey? repaintKey,
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      builder: repaintKey != null
          ? (context, appChild) =>
              RepaintBoundary(key: repaintKey, child: appChild!)
          : null,
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

    // Perform long press with gesture to hold finger down
    final itemFinder = find.byType(CollectionGridItem);
    final gesture = await tester.startGesture(tester.getCenter(itemFinder));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    // Verify all 3 action icons are present in the radial menu while finger is held
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Releasing finger without selecting an action dismisses the menu
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('Dragging finger to Edit button and releasing opens CollectionEditorModal',
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CollectionGridItem)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    // Slide finger to Edit button and release
    final editCenter = tester.getCenter(find.byIcon(Icons.edit));
    await gesture.moveTo(editCenter);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify CollectionEditorModal is shown
    expect(find.byType(CollectionEditorModal), findsOneWidget);
    expect(find.text('Design Resources'), findsAtLeastNWidgets(1));
  });

  testWidgets(
      'Dragging finger to Delete button and releasing opens DeleteConfirmationDialog',
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CollectionGridItem)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    // Slide finger to Delete button and release
    final deleteCenter = tester.getCenter(find.byIcon(Icons.delete_outline));
    await gesture.moveTo(deleteCenter);
    await tester.pump();
    await gesture.up();
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
        child: Consumer(
          builder: (context, ref, _) => Center(
            child: ElevatedButton(
              onPressed: () {
                CollectionRadialMenu.show(
                  context: context,
                  child: const SizedBox(width: 180, height: 160),
                  collection: testCollection,
                  cardRect: const Rect.fromLTWH(100, 200, 180, 160),
                  ref: ref,
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Menu'));
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CollectionGridItem)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byIcon(Icons.edit), findsOneWidget);

    final editCenter = tester.getCenter(find.byIcon(Icons.edit));
    await gesture.moveTo(editCenter);
    await tester.pump();

    // Verify EDIT label is rendered in the center of the screen
    expect(find.text('EDIT'), findsOneWidget);

    // Releasing executes the selected action
    await gesture.up();
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CollectionGridItem)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    final editCenter = tester.getCenter(find.byIcon(Icons.edit));
    final shareCenter = tester.getCenter(find.byIcon(Icons.share));
    final deleteCenter = tester.getCenter(find.byIcon(Icons.delete_outline));

    final distEditShare = (editCenter - shareCenter).distance;
    final distShareDelete = (shareCenter - deleteCenter).distance;

    // Center-to-center distance should be equal (~76.1 dp)
    expect((distEditShare - distShareDelete).abs(), lessThan(1.0));
    expect(distEditShare, closeTo(76.1, 1.0));

    // Inter-button gap with button diameter 62.0 dp (2 * 31.0)
    final gap = distEditShare - 62.0;
    expect(gap, closeTo(14.1, 1.0));

    // When an option is selected (scaled 1.15x), radius becomes 35.65 dp.
    // Distance between selected center and unselected center is 76.1 dp.
    // Sum of radii = 35.65 + 31.0 = 66.65 dp.
    // Clearance = 76.1 - 66.65 = 9.45 dp > 0, ensuring zero overlap!
    const selectedScale = 1.15;
    const buttonRadius = 31.0;
    final selectedRadius = buttonRadius * selectedScale;
    final clearance = distEditShare - (selectedRadius + buttonRadius);
    expect(clearance, greaterThan(8.0));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Captures visual renders of radial menu with Edit, Share, and Delete selected',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      createTestApp(
        repo: testRepo,
        repaintKey: repaintKey,
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(CollectionGridItem)));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    final editCenter = tester.getCenter(find.byIcon(Icons.edit));
    final shareCenter = tester.getCenter(find.byIcon(Icons.share));
    final deleteCenter = tester.getCenter(find.byIcon(Icons.delete_outline));

    // 1. Move to Share
    await gesture.moveTo(shareCenter);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('SHARE'), findsOneWidget);

    await tester.binding.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test_selected_share.png').writeAsBytesSync(byteData!.buffer.asUint8List());
    });

    // 2. Move to Edit
    await gesture.moveTo(editCenter);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('EDIT'), findsOneWidget);

    await tester.binding.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test_selected_edit.png').writeAsBytesSync(byteData!.buffer.asUint8List());
    });

    // 3. Move to Delete
    await gesture.moveTo(deleteCenter);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('DELETE'), findsOneWidget);

    await tester.binding.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test_selected_delete.png').writeAsBytesSync(byteData!.buffer.asUint8List());
    });

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
