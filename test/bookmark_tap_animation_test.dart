import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/widgets/bookmark_grid_item.dart';
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';

class _MockRepo implements IsarRepository {
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

CustomTransitionPage<T> _buildBookmarkTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedScale = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      final curvedFade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      );
      return ScaleTransition(
        scale: curvedScale,
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: curvedFade,
          child: child,
        ),
      );
    },
    child: child,
  );
}

void main() {
  testWidgets('Bookmark tap uses center scale transition with easeOutBack', (tester) async {
    final repo = _MockRepo();
    final bookmark = Bookmark()
      ..id = 42
      ..title = 'Test Bookmark'
      ..url = 'https://example.com'
      ..notes = 'Notes'
      ..createdAt = DateTime.now();
    await repo.addBookmark(bookmark);

    late GoRouter router;
    router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 155,
                child: BookmarkGridItem(bookmark: bookmark),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/bookmark/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final b = state.extra as Bookmark?;
            return _buildBookmarkTransitionPage(
              context: context,
              state: state,
              child: BookmarkDetailScreen(
                bookmark: b,
                bookmarkId: id,
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Bookmark'), findsOneWidget);

    // Direct router push to inspect frame-by-frame animation of the transition
    router.push('/bookmark/42', extra: bookmark);
    await tester.pump(); // GoRouter processes route change
    await tester.pump(); // Navigator builds new route at t=0

    // ScaleTransition wrapping BookmarkDetailScreen should now be in tree
    final detailScaleFinder = find.ancestor(
      of: find.byType(BookmarkDetailScreen),
      matching: find.byType(ScaleTransition),
    );
    expect(detailScaleFinder, findsOneWidget);

    final initialScale = tester.widget<ScaleTransition>(detailScaleFinder);
    expect(initialScale.alignment, Alignment.center);
    expect(initialScale.scale.value, equals(0.0));

    // Pump halfway (150ms) - scale expands beyond 0.8 with easeOutBack
    await tester.pump(const Duration(milliseconds: 150));
    final midScale = tester.widget<ScaleTransition>(detailScaleFinder);
    expect(midScale.scale.value, greaterThan(0.8));

    // Finish transition
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkDetailScreen), findsOneWidget);

    // Pop the route to verify reverse transition
    router.pop();
    await tester.pump(); // Pop starts

    // In reverse transition, it scales back down
    await tester.pump(const Duration(milliseconds: 100));
    final reverseScale = tester.widget<ScaleTransition>(detailScaleFinder);
    expect(reverseScale.scale.value, lessThan(1.0));

    // Finish pop transition
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkDetailScreen), findsNothing);
  });

  testWidgets('Bookmark tap on card opens detail screen with pop transition on back button', (tester) async {
    final repo = _MockRepo();
    final bookmark = Bookmark()
      ..id = 42
      ..title = 'Test Bookmark'
      ..url = 'https://example.com'
      ..notes = 'Notes'
      ..createdAt = DateTime.now();
    await repo.addBookmark(bookmark);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 155,
                child: BookmarkGridItem(bookmark: bookmark),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/bookmark/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final b = state.extra as Bookmark?;
            return _buildBookmarkTransitionPage(
              context: context,
              state: state,
              child: BookmarkDetailScreen(
                bookmark: b,
                bookmarkId: id,
              ),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the card
    await tester.tap(find.text('Test Bookmark'));
    // Allow NeoPressable spring animation and route animation to finish
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkDetailScreen), findsOneWidget);

    // Tap the back button
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkDetailScreen), findsNothing);
  });
}
