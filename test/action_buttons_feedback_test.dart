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
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';
import 'package:save_later/theme/app_theme.dart';

class FakeIsarRepository implements IsarRepository {
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

void main() {
  testWidgets('BookmarkDetailScreen action buttons render and respond to press feedback', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example Title';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: BookmarkDetailScreen(bookmark: bookmark),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 4 action buttons are present
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Verify ActionStripButton widgets exist inside each action button segment
    final actionButtons = find.descendant(
      of: find.byType(Row),
      matching: find.byType(ActionStripButton),
    );
    expect(actionButtons, findsAtLeastNWidgets(4));

    // Verify assigned highlight feedback colors (bold vibrant action palette)
    final btnWidgets = tester.widgetList<ActionStripButton>(actionButtons).toList();
    expect(btnWidgets[0].color, equals(const Color(0xFF7B61FF)));
    expect(btnWidgets[1].color, equals(const Color(0xFFFDD164)));
    expect(btnWidgets[2].color, equals(const Color(0xFF26D5A8)));
    expect(btnWidgets[3].color, equals(const Color(0xFFEF476F)));

    // Verify resting background is white for all buttons
    Color getButtonBgColor(String text) {
      final btn = find.ancestor(of: find.text(text), matching: find.byType(ActionStripButton));
      final container = tester.widget<Container>(
        find.descendant(of: btn, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      return decoration?.color ?? container.color ?? Colors.transparent;
    }

    expect(getButtonBgColor('Share'), equals(Colors.white));
    expect(getButtonBgColor('Move'), equals(Colors.white));
    expect(getButtonBgColor('Refresh'), equals(Colors.white));
    expect(getButtonBgColor('Delete'), equals(Colors.white));

    // Test pressing down on the Refresh button
    final refreshFinder = find.text('Refresh');
    final gesture = await tester.startGesture(tester.getCenter(refreshFinder));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify that tapping Refresh opened the RefreshDialog
    expect(find.text('Refresh link metadata?'), findsOneWidget);
  });

  testWidgets('ActionStripButton transitions background from white to target color on tap down', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ActionStripButton(
                icon: Icons.folder_outlined,
                label: 'Move',
                color: const Color(0xFFFDD164),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    Color getContainerColor() {
      final container = tester.widget<Container>(find.byType(Container).first);
      final dec = container.decoration as BoxDecoration?;
      return dec?.color ?? container.color ?? Colors.transparent;
    }

    // Initial resting color is white
    expect(getContainerColor(), equals(Colors.white));

    // Tap down starts forward animation
    final gesture = await tester.startGesture(tester.getCenter(find.text('Move')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 70));

    // Full target feedback color is reached
    expect(getContainerColor(), equals(const Color(0xFFFDD164)));

    // Release completes spring reverse
    await gesture.up();
    await tester.pumpAndSettle();

    // Reverted back to white resting state and invoked callback
    expect(getContainerColor(), equals(Colors.white));
    expect(tapped, isTrue);
  });
testWidgets('ActionStripButton exhibits mechanical depression with top/left recess shadows on press', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ActionStripButton(
                icon: Icons.folder_outlined,
                label: 'Move',
                color: const Color(0xFFFDD164),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    // Resting state: no Positioned recess shadows in Stack
    expect(find.byType(Positioned), findsNothing);

    // Press down
    final gesture = await tester.startGesture(tester.getCenter(find.text('Move')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 70));

    // Pressed state: top and left recess shadows exist
    expect(find.byType(Positioned), findsNWidgets(2));

    // Release
    await gesture.up();
    await tester.pumpAndSettle();

    // After release: recess shadows disappear and callback invoked
    expect(find.byType(Positioned), findsNothing);
    expect(tapped, isTrue);
  });

  testWidgets('ActionStripButton cancels press when dragged away beyond threshold', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ActionStripButton(
                icon: Icons.folder_outlined,
                label: 'Move',
                color: const Color(0xFFFDD164),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.text('Move'));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.byType(Positioned), findsNWidgets(2));

    // Drag away (e.g. scrolling)
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 150));

    // Depressed state canceled
    expect(find.byType(Positioned), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    // Tap callback should not be invoked on drag cancel
    expect(tapped, isFalse);
  });


testWidgets('ActionStripButton transitions foreground to high-contrast white when background is dark/vibrant', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              ActionStripButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                color: const Color(0xFFEF476F),
                isDestructive: true,
                onTap: () {},
              ),
              ActionStripButton(
                icon: Icons.refresh,
                label: 'Refresh',
                color: const Color(0xFF26D5A8),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    // Initial state: Delete has red text/icon, Refresh has black (AppTheme.border)
    Text getLabelText(String label) => tester.widget<Text>(find.text(label));
    expect(getLabelText('Delete').style?.color, equals(const Color(0xFFC0392B)));
    expect(getLabelText('Refresh').style?.color, equals(AppTheme.border));

    // Tap down on Delete (luminance < 0.35)
    final deleteGesture = await tester.startGesture(tester.getCenter(find.text('Delete')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 70));

    // Should transition to white for high contrast
    expect(getLabelText('Delete').style?.color, equals(Colors.white));
    await deleteGesture.up();
    await tester.pumpAndSettle();

    // Tap down on Refresh (luminance >= 0.35)
    final refreshGesture = await tester.startGesture(tester.getCenter(find.text('Refresh')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 70));

    // Should keep AppTheme.border for high contrast on light background
    expect(getLabelText('Refresh').style?.color, equals(AppTheme.border));
    await refreshGesture.up();
    await tester.pumpAndSettle();
  });
}
