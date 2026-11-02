import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/home_screen.dart';
import 'package:save_later/ui/widgets/neo_button.dart';

class TestReceiveSharingIntent extends ReceiveSharingIntent {
  final List<SharedMediaFile> initialMedia;
  final StreamController<List<SharedMediaFile>> streamController;
  int resetCount = 0;

  TestReceiveSharingIntent({
    required this.initialMedia,
    required this.streamController,
  });

  @override
  Future<List<SharedMediaFile>> getInitialMedia() async {
    return initialMedia;
  }

  @override
  Stream<List<SharedMediaFile>> getMediaStream() {
    return streamController.stream;
  }

  @override
  Future<dynamic> reset() async {
    resetCount++;
    initialMedia.clear();
  }
}

class FakeIsarRepository implements IsarRepository {
  final List<Bookmark> bookmarks = [];

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
  Future<List<Bookmark>> getBookmarks() async => bookmarks;

  @override
  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async => [];

  @override
  Future<List<Bookmark>> getUnsortedBookmarks() async => bookmarks;

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

Widget buildTestApp({required Widget home}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => home,
      ),
      GoRoute(
        path: '/unsorted',
        builder: (context, state) => const Scaffold(body: Text('Unsorted Screen')),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
  );
}

void main() {
  testWidgets('HomeScreen calls ReceiveSharingIntent.reset() when initial media arrives', (tester) async {
    final streamController = StreamController<List<SharedMediaFile>>.broadcast();
    final sharedFile = SharedMediaFile(
      path: 'https://flutter.dev/shared-link',
      type: SharedMediaType.text,
    );

    final mockIntent = TestReceiveSharingIntent(
      initialMedia: [sharedFile],
      streamController: streamController,
    );
    ReceiveSharingIntent.instance = mockIntent;

    final fakeRepo = FakeIsarRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          collectionsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: buildTestApp(
          home: const HomeScreen(),
        ),
      ),
    );

    // Initial microtasks and async getInitialMedia completion
    await tester.pumpAndSettle();

    // Verify reset was called once to consume initial media
    expect(mockIntent.resetCount, 1);
    expect(mockIntent.initialMedia, isEmpty);

    // Verify bookmark was saved from the intent URL
    expect(find.text('Save Later'), findsOneWidget);
    await tester.tap(find.widgetWithText(NeoButton, 'Save to "Unsorted"'));
    await tester.pumpAndSettle();

    // Dismiss success modal
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(fakeRepo.bookmarks.any((b) => b.url == 'https://flutter.dev/shared-link'), isTrue);

    // Now emit media on stream while app is running
    streamController.add([
      SharedMediaFile(
        path: 'https://dart.dev/stream-link',
        type: SharedMediaType.text,
      ),
    ]);

    await tester.pumpAndSettle();

    // Verify reset was called again
    expect(mockIntent.resetCount, 2);
    expect(find.text('Save Later'), findsOneWidget);
    await tester.tap(find.widgetWithText(NeoButton, 'Save to "Unsorted"'));
    await tester.pumpAndSettle();

    // Dismiss success modal
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(fakeRepo.bookmarks.any((b) => b.url == 'https://dart.dev/stream-link'), isTrue);

    await streamController.close();
  });

  testWidgets('Quick saving a URL navigates to /unsorted folder', (tester) async {
    final streamController = StreamController<List<SharedMediaFile>>.broadcast();
    final mockIntent = TestReceiveSharingIntent(
      initialMedia: [],
      streamController: streamController,
    );
    ReceiveSharingIntent.instance = mockIntent;

    final fakeRepo = FakeIsarRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          collectionsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: buildTestApp(
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter a URL
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'https://flutter.dev/docs');
    await tester.pumpAndSettle();

    // Tap the quick save (+) NeoButton
    final saveButtonFinder = find.widgetWithIcon(NeoButton, Icons.add);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verify it navigated to /unsorted
    expect(find.text('Unsorted Screen'), findsOneWidget);
    expect(fakeRepo.bookmarks.any((b) => b.url == 'https://flutter.dev/docs'), isTrue);

    await streamController.close();
  });
}
