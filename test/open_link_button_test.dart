// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';
import 'package:isar/isar.dart';

class _FakeLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool launchResult = true;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    return launchResult;
  }
}

class _FakeRepo implements IsarRepository {
  @override
  late Future<Isar> db = Future.error('No DB in test');
  final Map<Id, Bookmark> bookmarks = {};

  @override
  Future<Isar> openDB() async => Future.error('No DB');
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

Widget _buildTestApp({required Widget home}) {
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
  late _FakeLauncherPlatform mockPlatform;

  setUp(() {
    mockPlatform = _FakeLauncherPlatform();
    UrlLauncherPlatform.instance = mockPlatform;
  });

  group('Open link button animation in BookmarkDetailScreen', () {
    testWidgets('animates immediately on touch down and opens link on tap up', (tester) async {
      final fakeRepo = _FakeRepo();
      final bookmark = Bookmark()
        ..id = 1
        ..url = 'https://flutter.dev'
        ..title = 'Flutter'
        ..createdAt = DateTime.now();
      await fakeRepo.addBookmark(bookmark);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: _buildTestApp(
            home: BookmarkDetailScreen(bookmark: bookmark),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openLinkFinder = find.text('Open link');
      expect(openLinkFinder, findsOneWidget);

      // Touch down (start gesture)
      final gesture = await tester.startGesture(tester.getCenter(openLinkFinder));
      await tester.pump(const Duration(milliseconds: 30));

      // Check that the button is pressed down (Transform has translated)
      final transformFinder = find.ancestor(
        of: openLinkFinder,
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsWidgets);

      // Release touch
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify link was opened
      expect(mockPlatform.lastLaunchedUrl, equals('https://flutter.dev'));
    });

    testWidgets('cancels animation and does not open link when dragged beyond threshold', (tester) async {
      final fakeRepo = _FakeRepo();
      final bookmark = Bookmark()
        ..id = 2
        ..url = 'https://dart.dev'
        ..title = 'Dart'
        ..createdAt = DateTime.now();
      await fakeRepo.addBookmark(bookmark);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: _buildTestApp(
            home: BookmarkDetailScreen(bookmark: bookmark),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openLinkFinder = find.text('Open link');
      final gesture = await tester.startGesture(tester.getCenter(openLinkFinder));
      await tester.pump(const Duration(milliseconds: 20));

      // Drag vertically beyond 14px threshold (scrolling the detail view)
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pumpAndSettle();

      // Link should NOT have been opened because user was scrolling
      expect(mockPlatform.lastLaunchedUrl, isNull);
    });
  });
}
