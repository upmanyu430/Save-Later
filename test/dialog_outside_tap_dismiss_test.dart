import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/models/bookmark.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/no_url_dialog.dart';

Widget _buildTestApp(Widget child, [List<Override> overrides = const []]) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('MoveToCollectionModal closes when tapping grey area outside modal card', (tester) async {
    final mockCollections = [
      BookmarkCollection()
        ..id = 1
        ..name = 'Work'
        ..iconCodePoint = Icons.folder.codePoint
        ..iconFontFamily = 'MaterialIcons'
        ..colorHex = '#FF6B6B',
    ];

    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => MoveToCollectionModal(
                  bookmark: Bookmark()
                    ..id = 1
                    ..url = 'https://example.com'
                    ..title = 'Example',
                ),
              );
            },
            child: const Text('Open Move Modal'),
          ),
        ),
        [
          allCollectionsProvider.overrideWith((ref) => Future.value(mockCollections)),
        ],
      ),
    );

    await tester.tap(find.text('Open Move Modal'));
    await tester.pumpAndSettle();

    expect(find.text('Move to Collection'), findsWidgets);

    // Tap outside on the top grey area (e.g. Offset(100, 100))
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    // Modal should be dismissed
    expect(find.text('Move to Collection'), findsNothing);
  });

  testWidgets('CollectionEditorModal closes when tapping grey area outside modal card', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const CollectionEditorModal(),
              );
            },
            child: const Text('Open Collection Editor'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Collection Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Add new collection'), findsOneWidget);

    // Tap outside on the top grey area (e.g. Offset(100, 100))
    await tester.tapAt(const Offset(100, 100));
    await tester.pumpAndSettle();

    // Modal should be dismissed
    expect(find.text('Add new collection'), findsNothing);
  });

  testWidgets('showNoUrlDialog closes when tapping grey area outside dialog', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showNoUrlDialog(context),
            child: const Text('Open No URL Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open No URL Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('No URL'), findsOneWidget);

    // Tap top left corner outside dialog card
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('No URL'), findsNothing);
  });
}
