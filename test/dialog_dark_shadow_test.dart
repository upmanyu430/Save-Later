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
import 'package:save_later/theme/app_theme.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';
import 'package:save_later/ui/widgets/moved_success_dialog.dart';
import 'package:save_later/ui/widgets/no_url_dialog.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/screens/bookmark_detail_screen.dart';

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
  Future<List<BookmarkCollection>> getAllCollections() async => [];

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

void main() {
  testWidgets('CollectionEditorModal card container has dark shadow (Offset(2.8, 2.8))', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();

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
          home: const Scaffold(body: CollectionEditorModal()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(find.byType(Container));
    final modalContainer = containers.firstWhere(
      (c) => c.decoration is BoxDecoration && (c.decoration as BoxDecoration).boxShadow != null && (c.decoration as BoxDecoration).boxShadow!.isNotEmpty,
    );
    final boxDecoration = modalContainer.decoration as BoxDecoration;
    expect(boxDecoration.boxShadow, isNotNull);
    final shadow = boxDecoration.boxShadow!.first;
    expect(shadow.color, AppTheme.border);
    expect(shadow.offset, const Offset(2.8, 2.8));
    expect(shadow.blurRadius, 0.0);
  });

  testWidgets('DeleteConfirmationDialog has dark shadow (Offset(2.8, 2.8))', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const Scaffold(
          body: DeleteConfirmationDialog(
            title: 'Delete Test',
            message: 'Are you sure?',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialog = tester.widget<DeleteConfirmationDialog>(find.byType(DeleteConfirmationDialog));
    final container = tester.widget<Container>(find.descendant(of: find.byWidget(dialog), matching: find.byType(Container)).first);
    final boxDecoration = container.decoration as BoxDecoration;
    expect(boxDecoration.boxShadow, isNotNull);
    final shadow = boxDecoration.boxShadow!.first;
    expect(shadow.color, AppTheme.border);
    expect(shadow.offset, const Offset(2.8, 2.8));
  });

  testWidgets('MovedSuccessDialog has dark shadow (Offset(2.8, 2.8))', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const Scaffold(
          body: MovedSuccessDialog(
            title: 'Moved',
            message: 'Moved successfully',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dialog = tester.widget<MovedSuccessDialog>(find.byType(MovedSuccessDialog));
    final container = tester.widget<Container>(find.descendant(of: find.byWidget(dialog), matching: find.byType(Container)).first);
    final boxDecoration = container.decoration as BoxDecoration;
    expect(boxDecoration.boxShadow, isNotNull);
    final shadow = boxDecoration.boxShadow!.first;
    expect(shadow.color, AppTheme.border);
    expect(shadow.offset, const Offset(2.8, 2.8));
  });

  testWidgets('BookmarkDetailScreen card container has reduced dark shadow (Offset(2.8, 2.8))', (WidgetTester tester) async {
    final fakeRepo = FakeIsarRepository();
    final bookmark = Bookmark()
      ..id = 1
      ..url = 'https://example.com'
      ..title = 'Example'
      ..createdAt = DateTime.now();

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

    final cardContainer = tester.widget<Container>(
      find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.borderRadius == const BorderRadius.all(Radius.circular(32)) &&
              box.boxShadow != null &&
              box.boxShadow!.isNotEmpty;
        }
        return false;
      }),
    );
    final boxDecoration = cardContainer.decoration as BoxDecoration;
    expect(boxDecoration.boxShadow, isNotNull);
    final shadow = boxDecoration.boxShadow!.first;
    expect(shadow.color, AppTheme.border);
    expect(shadow.offset, const Offset(2.8, 2.8));
    expect(shadow.blurRadius, 0.0);
  });
}
