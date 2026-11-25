import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/app_modal_sheet.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/share_save_modal.dart';

class _SmoothnessMockRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  final List<BookmarkCollection> collections = [];
  final List<Bookmark> bookmarks = [];

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async =>
      List.from(collections);

  @override
  Future<List<BookmarkCollection>> getSubCollections(Id parentId) async => [];

  @override
  Future<BookmarkCollection?> getCollection(Id id) async =>
      collections.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<BookmarkCollection>> getAllCollections() async =>
      List.from(collections);

  @override
  Future<void> addCollection(BookmarkCollection collection) async {
    if (collection.id == Isar.autoIncrement) {
      collection.id = collections.length + 1;
    }
    collections.add(collection);
  }

  @override
  Future<void> deleteCollection(Id collectionId) async {
    collections.removeWhere((c) => c.id == collectionId);
  }

  @override
  Future<Bookmark?> getBookmark(Id id) async =>
      bookmarks.where((b) => b.id == id).firstOrNull;

  @override
  Future<List<Bookmark>> getBookmarks() async => List.from(bookmarks);

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => [];

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

Widget _buildHostApp({
  required IsarRepository repo,
  required Widget Function(BuildContext context) builder,
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
        resizeToAvoidBottomInset: false,
        body: Builder(builder: builder),
      ),
    ),
  );
}

void _configurePhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2332);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 96, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 96, bottom: 48);
  tester.view.viewInsets = FakeViewPadding.zero;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    tester.view.resetViewInsets();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SmoothnessMockRepository repo;

  setUp(() {
    repo = _SmoothnessMockRepository();
    repo.collections.add(
      BookmarkCollection()
        ..id = 1
        ..name = 'Tech'
        ..colorHex = '4A90E2'
        ..iconCodePoint = Icons.code.codePoint
        ..iconFontFamily = kStoredIconFontFamily,
    );
  });

  group('Phase 3 Smooth Modal Sheets verification', () {
    testWidgets(
      'CollectionEditorModal lifts cleanly on keyboard inset changes without clipping header, stretching bottom padding, or rebuilding color/icon tiles on typing',
      (tester) async {
        _configurePhoneView(tester);
        const dpr = 3.0;
        const viewportHeight = 2332.0 / dpr;

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppModalSheet<void>(
                    context: context,
                    builder: (_) => const CollectionEditorModal(),
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();

        final cardFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(55),
          ),
        );
        final scrollFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byType(SingleChildScrollView),
        );
        final titleFinder = find.text('Add new collection');

        expect(titleFinder, findsOneWidget);
        final initialCardRect = tester.getRect(cardFinder);
        final initialTitleRect = tester.getRect(titleFinder);
        final initialScrollPadding =
            tester.widget<SingleChildScrollView>(scrollFinder).padding!
                as EdgeInsets;

        expect(initialTitleRect.top, greaterThanOrEqualTo(0));
        expect(initialTitleRect.bottom, lessThanOrEqualTo(viewportHeight));
        expect(initialTitleRect.top, greaterThanOrEqualTo(initialCardRect.top));
        expect(
          initialScrollPadding.bottom,
          closeTo(AppDimensions.modalActionButtonBottomPadding + 16.0, 0.1),
        );

        // Capture GridView widget instances before typing.
        final gridsFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byType(GridView),
        );
        expect(gridsFinder, findsNWidgets(2));
        final colorGridBefore = tester.widget<GridView>(gridsFinder.first);
        final iconGridBefore = tester.widget<GridView>(gridsFinder.last);

        // Open keyboard (350dp viewInsets.bottom).
        tester.view.viewInsets = FakeViewPadding(bottom: 350.0 * dpr);
        await tester.pumpAndSettle();

        final kbdCardRect = tester.getRect(cardFinder);
        final kbdTitleRect = tester.getRect(titleFinder);
        final kbdScrollPadding =
            tester.widget<SingleChildScrollView>(scrollFinder).padding!
                as EdgeInsets;

        // Header remains unclipped inside viewport and inside card.
        expect(kbdTitleRect.top, greaterThanOrEqualTo(0));
        expect(kbdTitleRect.top, greaterThanOrEqualTo(kbdCardRect.top));

        // Card stays anchored to bottom of screen (bottom: 0) as a bottom sheet.
        expect(kbdCardRect.bottom, closeTo(viewportHeight, 0.1));
        expect(kbdScrollPadding.bottom, equals(14.0 + 350.0));

        // Typing updates ValueListenableBuilder widgets without rebuilding color/icon grids.
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Design');
        await tester.pump();

        expect(find.text('6/40'), findsOneWidget);
        expect(
          identical(tester.widget<GridView>(gridsFinder.first), colorGridBefore),
          isTrue,
        );
        expect(
          identical(tester.widget<GridView>(gridsFinder.last), iconGridBefore),
          isTrue,
        );

        // Dismiss keyboard (viewInsets.bottom -> 0).
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        final closedCardRect = tester.getRect(cardFinder);
        final closedTitleRect = tester.getRect(titleFinder);
        final closedScrollPadding =
            tester.widget<SingleChildScrollView>(scrollFinder).padding!
                as EdgeInsets;

        expect(closedTitleRect.top, greaterThanOrEqualTo(0));
        expect(closedTitleRect.bottom, lessThanOrEqualTo(viewportHeight));
        expect(closedCardRect.bottom, closeTo(initialCardRect.bottom, 0.1));
        expect(
          closedScrollPadding.bottom,
          closeTo(AppDimensions.modalActionButtonBottomPadding + 16.0, 0.1),
        );
      },
    );

    testWidgets(
      'Stacked MoveToCollectionModal covered by CollectionEditorModal freezes its AppModalKeyboardLift height when viewInsets change',
      (tester) async {
        _configurePhoneView(tester);
        const dpr = 3.0;
        const viewportHeight = 2332.0 / dpr;

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  MoveToCollectionModal.show(context: context);
                },
                child: const Text('Open Move'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Move'));
        await tester.pumpAndSettle();

        final moveLiftFinder = find.ancestor(
          of: find.byKey(const ValueKey('move_to_collection_modal_sheet')),
          matching: find.byType(AppModalKeyboardLift),
        );
        final moveConstrainedBoxFinder = find.descendant(
          of: moveLiftFinder,
          matching: find.byWidgetPredicate(
            (w) => w is ConstrainedBox && w.constraints.maxWidth == 420.0,
          ),
        );
        final moveLiftPaddingFinder = find.descendant(
          of: moveLiftFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Padding &&
                w.padding is EdgeInsets &&
                (w.padding as EdgeInsets).left == 5.0 &&
                (w.padding as EdgeInsets).right == 5.0,
          ),
        );

        final initialSheetHeight = tester
            .getSize(find.byKey(const ValueKey('move_to_collection_modal_sheet')))
            .height;
        final initialMaxHeight = tester
            .widget<ConstrainedBox>(moveConstrainedBoxFinder.first)
            .constraints
            .maxHeight;
        final initialLiftBottom = (tester
                .widget<Padding>(moveLiftPaddingFinder.first)
                .padding as EdgeInsets)
            .bottom;
        expect(initialLiftBottom, equals(0.0));

        // Open stacked CollectionEditorModal on top of MoveToCollectionModal.
        await tester.tap(find.byIcon(Icons.create_new_folder_outlined));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsOneWidget);

        // Simulate keyboard opening while MoveToCollectionModal is covered.
        tester.view.viewInsets = FakeViewPadding(bottom: 350.0 * dpr);
        await tester.pumpAndSettle();

        // Top CollectionEditorModal stays anchored to bottom of screen (bottom: 0).
        final editorCardFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(55),
          ),
        );
        expect(
          tester.getRect(editorCardFinder).bottom,
          closeTo(viewportHeight, 0.1),
        );

        // Covered MoveToCollectionModal freezes its AppModalKeyboardLift inset & maxHeight.
        final coveredMaxHeight = tester
            .widget<ConstrainedBox>(moveConstrainedBoxFinder.first)
            .constraints
            .maxHeight;
        final coveredLiftBottom = (tester
                .widget<Padding>(moveLiftPaddingFinder.first)
                .padding as EdgeInsets)
            .bottom;
        final coveredSheetHeight = tester
            .getSize(find.byKey(const ValueKey('move_to_collection_modal_sheet')))
            .height;

        expect(coveredLiftBottom, equals(0.0));
        expect(coveredMaxHeight, equals(initialMaxHeight));
        expect(coveredSheetHeight, equals(initialSheetHeight));

        // Dismiss top modal and reset insets cleanly.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Backdrop tap and close button clear primary focus when dismissing CollectionEditorModal and AddLinkModal',
      (tester) async {
        _configurePhoneView(tester);

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showAppModalSheet<void>(
                      context: context,
                      builder: (_) => const CollectionEditorModal(),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showAppModalSheet<void>(
                      context: context,
                      builder: (_) => AddLinkModal(collection: repo.collections.first),
                    );
                  },
                  child: const Text('Open AddLink'),
                ),
              ],
            ),
          ),
        );

        // 1. CollectionEditorModal close button clears primary focus.
        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final editorCloseNode = FocusManager.instance.primaryFocus;
        expect(editorCloseNode, isNotNull);
        expect(editorCloseNode, isNot(isA<FocusScopeNode>()));
        expect(editorCloseNode!.hasPrimaryFocus, isTrue);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsNothing);
        expect(editorCloseNode.hasFocus, isFalse);
        expect(
          FocusManager.instance.primaryFocus == null ||
              FocusManager.instance.primaryFocus is FocusScopeNode,
          isTrue,
        );

        // 2. CollectionEditorModal backdrop tap clears primary focus.
        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pump();
        final editorBackdropNode = FocusManager.instance.primaryFocus;
        expect(editorBackdropNode, isNotNull);
        expect(editorBackdropNode, isNot(isA<FocusScopeNode>()));
        expect(editorBackdropNode!.hasPrimaryFocus, isTrue);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsNothing);
        expect(editorBackdropNode.hasFocus, isFalse);
        expect(
          FocusManager.instance.primaryFocus == null ||
              FocusManager.instance.primaryFocus is FocusScopeNode,
          isTrue,
        );

        // 3. AddLinkModal close button clears primary focus (auto-focused via AppModalDeferredFocusMixin).
        await tester.tap(find.text('Open AddLink'));
        await tester.pumpAndSettle();
        final addLinkCloseNode = FocusManager.instance.primaryFocus;
        expect(addLinkCloseNode, isNotNull);
        expect(addLinkCloseNode, isNot(isA<FocusScopeNode>()));
        expect(addLinkCloseNode!.hasPrimaryFocus, isTrue);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.byType(AddLinkModal), findsNothing);
        expect(addLinkCloseNode.hasFocus, isFalse);
        expect(
          FocusManager.instance.primaryFocus == null ||
              FocusManager.instance.primaryFocus is FocusScopeNode,
          isTrue,
        );

        // 4. AddLinkModal backdrop tap clears primary focus.
        await tester.tap(find.text('Open AddLink'));
        await tester.pumpAndSettle();
        final addLinkBackdropNode = FocusManager.instance.primaryFocus;
        expect(addLinkBackdropNode, isNotNull);
        expect(addLinkBackdropNode, isNot(isA<FocusScopeNode>()));
        expect(addLinkBackdropNode!.hasPrimaryFocus, isTrue);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(AddLinkModal), findsNothing);
        expect(addLinkBackdropNode.hasFocus, isFalse);
        expect(
          FocusManager.instance.primaryFocus == null ||
              FocusManager.instance.primaryFocus is FocusScopeNode,
          isTrue,
        );
      },
    );

    testWidgets(
      'SaveSuccessModal does NOT dismiss when tapping inside the card, and only backdrop tap dismisses',
      (tester) async {
        _configurePhoneView(tester);

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  SaveSuccessModal.show(
                    context: context,
                    autoDismissDuration: const Duration(seconds: 10),
                  );
                },
                child: const Text('Open Success'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Success'));
        await tester.pumpAndSettle();
        expect(find.byType(SaveSuccessModal), findsOneWidget);

        // Tapping inside the card must NOT dismiss SaveSuccessModal.
        await tester.tap(find.text('Saved!'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SaveSuccessModal), findsOneWidget);

        await tester.tap(find.text('Link saved'));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(SaveSuccessModal), findsOneWidget);

        // Tapping outside on the backdrop dismisses SaveSuccessModal (and cancels timer).
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(SaveSuccessModal), findsNothing);
      },
    );

    testWidgets(
      'showAppModalSheet animates smoothly at 120fps frame steps without rebuilding child or jumping on mid-entrance dismiss or drag',
      (tester) async {
        _configurePhoneView(tester);
        var buildCount = 0;

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showAppModalSheet<void>(
                    context: context,
                    builder: (_) {
                      buildCount++;
                      return const CollectionEditorModal();
                    },
                  );
                },
                child: const Text('Open Editor'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Editor'));
        await tester.pump();
        expect(buildCount, equals(1));

        final cardFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).borderRadius ==
                    BorderRadius.circular(55),
          ),
        );

        // Step at ~120fps (8.33ms -> 8333us) and verify monotonic rise with 0 child rebuilds.
        double prevTop = tester.getRect(cardFinder).top;
        for (int i = 0; i < 12; i++) {
          await tester.pump(const Duration(microseconds: 8333));
          final currentTop = tester.getRect(cardFinder).top;
          expect(currentTop, lessThanOrEqualTo(prevTop));
          prevTop = currentTop;
        }
        expect(buildCount, equals(1));

        // Interrupt mid-entrance via backdrop tap: no jump downward on first reverse tick.
        final topBeforeInterrupt = tester.getRect(cardFinder).top;
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(microseconds: 8333));
        final topAfterInterrupt = tester.getRect(cardFinder).top;
        expect(topAfterInterrupt - topBeforeInterrupt, lessThan(25.0));

        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsNothing);

        // Re-open and test drag-to-dismiss gesture.
        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsOneWidget);

        // Slight drag snaps back open.
        await tester.drag(find.text('Add new collection'), const Offset(0, 40));
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsOneWidget);

        // Strong downward fling dismisses cleanly.
        await tester.fling(
          find.text('Add new collection'),
          const Offset(0, 260),
          1400,
        );
        await tester.pumpAndSettle();
        expect(find.byType(CollectionEditorModal), findsNothing);
      },
    );

    testWidgets(
      'CollectionEditorModal and AddLinkModal interpolate IME bottom padding continuously without jumps or rebuilding content',
      (tester) async {
        _configurePhoneView(tester);
        const dpr = 3.0;

        await tester.pumpWidget(
          _buildHostApp(
            repo: repo,
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showAppModalSheet<void>(
                      context: context,
                      builder: (_) => const CollectionEditorModal(),
                    );
                  },
                  child: const Text('Open Editor'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showAppModalSheet<void>(
                      context: context,
                      builder: (_) => AddLinkModal(collection: repo.collections.first),
                    );
                  },
                  child: const Text('Open AddLink'),
                ),
              ],
            ),
          ),
        );

        // 1. CollectionEditorModal continuous IME bottomPadding & identical GridViews.
        await tester.tap(find.text('Open Editor'));
        await tester.pumpAndSettle();

        final editorScrollFinder = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byType(SingleChildScrollView),
        );
        final editorGrids = find.descendant(
          of: find.byType(CollectionEditorModal),
          matching: find.byType(GridView),
        );
        final colorGridBefore = tester.widget<GridView>(editorGrids.first);
        final iconGridBefore = tester.widget<GridView>(editorGrids.last);

        double prevEditorBottom = (tester
                .widget<SingleChildScrollView>(editorScrollFinder)
                .padding! as EdgeInsets)
            .bottom;
        for (final inset in [8.0, 24.0, 120.0, 240.0, 350.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset * dpr);
          await tester.pump();
          final currentBottom = (tester
                  .widget<SingleChildScrollView>(editorScrollFinder)
                  .padding! as EdgeInsets)
              .bottom;
          expect(currentBottom, greaterThanOrEqualTo(prevEditorBottom));
          prevEditorBottom = currentBottom;
        }
        expect(prevEditorBottom, equals(14.0 + 350.0));
        expect(
          identical(tester.widget<GridView>(editorGrids.first), colorGridBefore),
          isTrue,
        );
        expect(
          identical(tester.widget<GridView>(editorGrids.last), iconGridBefore),
          isTrue,
        );

        // Dismiss editor and reset insets.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // 2. AddLinkModal continuous IME bottomPadding without 31.5dp snap.
        await tester.tap(find.text('Open AddLink'));
        await tester.pumpAndSettle();

        Container findAddLinkCard() => tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(AddLinkModal),
                matching: find.byType(Container),
              ),
            )
            .firstWhere(
              (c) =>
                  c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).borderRadius ==
                      BorderRadius.circular(55),
            );

        final idlePadding = (findAddLinkCard().padding! as EdgeInsets).bottom;
        expect(
          idlePadding,
          closeTo(AppDimensions.modalActionButtonBottomPadding + 16.0, 0.1),
        );

        tester.view.viewInsets = FakeViewPadding(bottom: 10.0 * dpr);
        await tester.pump();
        final earlyImePadding =
            (findAddLinkCard().padding! as EdgeInsets).bottom;
        expect(earlyImePadding, closeTo(idlePadding - 10.0, 0.1));

        tester.view.viewInsets = FakeViewPadding(bottom: 350.0 * dpr);
        await tester.pump();
        final fullImePadding =
            (findAddLinkCard().padding! as EdgeInsets).bottom;
        expect(fullImePadding, equals(16.0));
      },
    );
  });
}
