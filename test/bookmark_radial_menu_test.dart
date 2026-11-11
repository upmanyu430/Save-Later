import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/widgets/bookmark_radial_menu.dart';


class _FakeIsarRepository implements IsarRepository {
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
  Future<void> updateBookmark(Bookmark bookmark) async {}

  @override
  Future<void> updateBookmarks(List<Bookmark> updated) async {}

  @override
  Future<void> deleteBookmark(Id id) async {}

  @override
  Future<void> deleteBookmarks(List<Id> ids) async {}
}

Widget buildTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: home,
  );
}

void main() {
  late _FakeIsarRepository fakeRepo;
  late Bookmark testBookmark;

  setUp(() {
    fakeRepo = _FakeIsarRepository();
    testBookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Test Bookmark';
  });

  tearDown(() {
    BookmarkRadialMenu.dismiss();
  });

  testWidgets('All radial menu icons turn white when selected, and remain black when unselected', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: buildTestApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    BookmarkRadialMenu.show(
                      context: context,
                      child: const SizedBox(width: 150, height: 150),
                      bookmark: testBookmark,
                      cardRect: const Rect.fromLTWH(40, 100, 150, 150),
                      ref: ref,
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open menu
    await tester.tap(find.text('Show Menu'));
    await tester.pumpAndSettle();

    final openFinder = find.byIcon(Icons.open_in_new);
    final pinFinder = find.byIcon(Icons.push_pin_outlined);
    final shareFinder = find.byIcon(Icons.share_outlined);
    final deleteFinder = find.byIcon(Icons.delete_outline);

    expect(openFinder, findsOneWidget);
    expect(pinFinder, findsOneWidget);
    expect(shareFinder, findsOneWidget);
    expect(deleteFinder, findsOneWidget);

    // Helper to get painter color from CustomPaint by painter runtimeType name
    Color getPainterColor(String typeSubstring) {
      final finder = find.byWidgetPredicate((w) =>
          w is CustomPaint &&
          w.painter != null &&
          w.painter.runtimeType.toString().contains(typeSubstring));
      final customPaint = tester.widget<CustomPaint>(finder);
      return (customPaint.painter as dynamic).color as Color;
    }

    // Initial state: No button selected, all icons are black
    expect(getPainterColor('ExternalLink'), Colors.black);
    expect(getPainterColor('PinIcon'), Colors.black);
    expect(getPainterColor('ShareIcon'), Colors.black);
    expect(getPainterColor('TrashIcon'), Colors.black);

    // 1. Select OPEN button
    BookmarkRadialMenu.updatePosition(tester.getCenter(openFinder));
    await tester.pump();
    expect(find.text('OPEN'), findsOneWidget);
    expect(getPainterColor('ExternalLink'), Colors.white, reason: 'Open icon must turn white when selected');
    expect(getPainterColor('PinIcon'), Colors.black);
    expect(getPainterColor('ShareIcon'), Colors.black);
    expect(getPainterColor('TrashIcon'), Colors.black);

    // 2. Select PIN button
    BookmarkRadialMenu.updatePosition(tester.getCenter(pinFinder));
    await tester.pump();
    expect(find.text('PIN'), findsOneWidget);
    expect(getPainterColor('PinIcon'), Colors.white, reason: 'Pin icon must turn white when selected');
    expect(getPainterColor('ExternalLink'), Colors.black);
    expect(getPainterColor('ShareIcon'), Colors.black);
    expect(getPainterColor('TrashIcon'), Colors.black);

    // 3. Select SHARE button
    BookmarkRadialMenu.updatePosition(tester.getCenter(shareFinder));
    await tester.pump();
    expect(find.text('SHARE'), findsOneWidget);
    expect(getPainterColor('ShareIcon'), Colors.white, reason: 'Share icon must turn white when selected');
    expect(getPainterColor('ExternalLink'), Colors.black);
    expect(getPainterColor('PinIcon'), Colors.black);
    expect(getPainterColor('TrashIcon'), Colors.black);

    // 4. Select DELETE button
    BookmarkRadialMenu.updatePosition(tester.getCenter(deleteFinder));
    await tester.pump();
    expect(find.text('DELETE'), findsOneWidget);
    expect(getPainterColor('TrashIcon'), Colors.white, reason: 'Delete icon must turn white when selected');
    expect(getPainterColor('ExternalLink'), Colors.black);
    expect(getPainterColor('PinIcon'), Colors.black);
    expect(getPainterColor('ShareIcon'), Colors.black);

    // Dismiss menu
    BookmarkRadialMenu.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Bookmark radial menu buttons maintain non-overlapping balanced spacing when card is near top edge',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 0, left: 0, right: 0);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: buildTestApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    BookmarkRadialMenu.show(
                      context: context,
                      child: const SizedBox(width: 180, height: 200),
                      bookmark: testBookmark,
                      cardRect: const Rect.fromLTWH(16, 40, 180, 200),
                      ref: ref,
                    );
                  },
                  child: const Text('Show Menu'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open menu
    await tester.tap(find.text('Show Menu'));
    await tester.pumpAndSettle();

    final openFinder = find.byIcon(Icons.open_in_new);
    final pinFinder = find.byIcon(Icons.push_pin_outlined);
    final shareFinder = find.byIcon(Icons.share_outlined);
    final deleteFinder = find.byIcon(Icons.delete_outline);

    final openCenter = tester.getCenter(openFinder);
    final pinCenter = tester.getCenter(pinFinder);
    final shareCenter = tester.getCenter(shareFinder);
    final deleteCenter = tester.getCenter(deleteFinder);

    final distOpenPin = (openCenter - pinCenter).distance;
    final distPinShare = (pinCenter - shareCenter).distance;
    final distShareDelete = (shareCenter - deleteCenter).distance;

    // All consecutive buttons must maintain equidistant spacing (~75.3 dp)
    expect(distOpenPin, closeTo(75.3, 1.0));
    expect(distPinShare, closeTo(75.3, 1.0));
    expect(distShareDelete, closeTo(75.3, 1.0));

    // Every button center must be far enough from every other button (diameter 62.0 dp + gap >= 13 dp)
    expect(distOpenPin, greaterThan(70.0));
    expect(distPinShare, greaterThan(70.0));
    expect(distShareDelete, greaterThan(70.0));

    // Check all pairwise distances to guarantee no overlaps
    final centers = [openCenter, pinCenter, shareCenter, deleteCenter];
    for (int i = 0; i < centers.length; i++) {
      for (int j = i + 1; j < centers.length; j++) {
        expect((centers[i] - centers[j]).distance, greaterThan(62.0),
            reason: 'Buttons $i and $j must not overlap');
      }
    }

    BookmarkRadialMenu.dismiss();
    await tester.pumpAndSettle();
  });
}
