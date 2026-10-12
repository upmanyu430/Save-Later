// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/utils/url_launcher.dart';
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';
import 'package:save_later/ui/screens/review_mode_screen.dart';
import 'package:save_later/ui/widgets/bookmark_radial_menu.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  bool launchResult = true;
  bool shouldThrow = false;
  String? lastLaunchedUrl;
  LaunchOptions? lastOptions;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    lastOptions = options;
    if (shouldThrow) {
      throw Exception('Platform launch exception');
    }
    return launchResult;
  }
}

class FakeIsarRepository implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');

  @override
  Future<Isar> openDB() async => Future.error('No DB in test');

  @override
  Future<List<BookmarkCollection>> getCollections() async => [];

  @override
  Future<void> addCollection(BookmarkCollection collection) async {}

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
    supportedLocales: const [Locale('en', '')],
    home: home,
  );
}

void main() {
  late MockUrlLauncherPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockPlatform;
  });

  group('openUrl unit tests', () {
    test('returns false for empty or whitespace URL without calling launch', () async {
      expect(await openUrl(''), isFalse);
      expect(await openUrl('   '), isFalse);
      expect(mockPlatform.lastLaunchedUrl, isNull);
    });

    test('returns false for invalid URL without host', () async {
      expect(await openUrl('https://'), isFalse);
      expect(mockPlatform.lastLaunchedUrl, isNull);
    });

    test('prepends https:// when scheme is omitted', () async {
      final result = await openUrl('example.com/page');
      expect(result, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'https://example.com/page');
    });

    test('successfully launches valid http/https URLs', () async {
      final result = await openUrl('https://example.com');
      expect(result, isTrue);
      expect(mockPlatform.lastLaunchedUrl, 'https://example.com');
      expect(mockPlatform.lastOptions?.mode, PreferredLaunchMode.externalApplication);
    });

    test('returns false when launchUrl returns false without throwing', () async {
      mockPlatform.launchResult = false;
      final result = await openUrl('https://example.com');
      expect(result, isFalse);
    });

    test('catches platform exceptions and returns false without rethrowing', () async {
      mockPlatform.shouldThrow = true;
      final result = await openUrl('https://example.com');
      expect(result, isFalse);
    });
  });

  group('openUrl widget tests with context and snackbar feedback', () {
    testWidgets('shows snackbar when launch fails due to invalid url', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => openUrl('   ', context: context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });

    testWidgets('shows snackbar when platform launch returns false', (tester) async {
      mockPlatform.launchResult = false;

      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => openUrl('https://example.com', context: context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });

    testWidgets('shows snackbar when platform launch throws exception', (tester) async {
      mockPlatform.shouldThrow = true;

      await tester.pumpWidget(
        buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => openUrl('https://example.com', context: context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });
  });

  group('BookmarkDetailScreen open link button', () {
    testWidgets('tapping Open Link button invokes openUrl and shows snackbar on failure', (tester) async {
      mockPlatform.launchResult = false;
      final fakeRepo = FakeIsarRepository();
      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://example.com/details'
        ..title = 'Details Bookmark';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: buildTestApp(
            home: BookmarkDetailScreen(bookmark: bookmark),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Open link button
      final openButtonFinder = find.text('Open link');
      expect(openButtonFinder, findsOneWidget);

      await tester.tap(openButtonFinder);
      await tester.pumpAndSettle();

      expect(mockPlatform.lastLaunchedUrl, 'https://example.com/details');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });
  });

  group('BookmarkRadialMenu open action', () {
    testWidgets('triggering OPEN action invokes openUrl and shows snackbar on failure', (tester) async {
      mockPlatform.launchResult = false;
      final fakeRepo = FakeIsarRepository();
      final bookmark = Bookmark()
        ..id = 2
        ..url = 'https://example.com/radial'
        ..title = 'Radial Bookmark';

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
                        child: const SizedBox(width: 100, height: 100),
                        bookmark: bookmark,
                        cardRect: const Rect.fromLTWH(50, 50, 100, 100),
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

      // Tap to open radial menu
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // Verify open icon is rendered in the radial menu
      final openIconFinder = find.byIcon(Icons.open_in_new);
      expect(openIconFinder, findsOneWidget);

      // Move finger over OPEN icon and verify OPEN text appears
      BookmarkRadialMenu.updatePosition(tester.getCenter(openIconFinder));
      await tester.pump();
      expect(find.text('OPEN'), findsOneWidget);

      // Execute selected and verify URL launch attempted and failure handled
      BookmarkRadialMenu.executeSelectedAndClose();
      await tester.pumpAndSettle();

      expect(mockPlatform.lastLaunchedUrl, 'https://example.com/radial');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });
  });

  group('ReviewModeScreen open link button', () {
    testWidgets('tapping Open link button invokes openUrl and shows snackbar on failure', (tester) async {
      mockPlatform.launchResult = false;
      final fakeRepo = FakeIsarRepository();
      final bookmark = Bookmark()
        ..id = 3
        ..url = 'https://example.com/review'
        ..title = 'Review Bookmark'
        ..isRead = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
            unsortedBookmarksProvider.overrideWith((ref) => Future.value([bookmark])),
          ],
          child: buildTestApp(
            home: const ReviewModeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final openLinkFinder = find.text('Open link');
      expect(openLinkFinder, findsOneWidget);

      await tester.tap(openLinkFinder);
      await tester.pumpAndSettle();

      expect(mockPlatform.lastLaunchedUrl, 'https://example.com/review');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Could not open link'), findsOneWidget);
    });
  });
}
