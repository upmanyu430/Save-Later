import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/screens/collection_detail_screen.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/neo_button.dart';
import 'package:save_later/ui/widgets/share_save_modal.dart';

class _MockRepo implements IsarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => [];

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => [];

  @override
  Future<List<BookmarkCollection>> getSubCollections(int parentId) async => [];

  @override
  Future<BookmarkCollection?> getCollection(int id) async => null;
}

Widget _wrapWithApp(Widget child) {
  final repo = _MockRepo();
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      allCollectionsProvider.overrideWith((ref) => Future.value([])),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('All dialog modals share consistent modalActionButtonBottomPadding (36.5)', (tester) async {
    // 1. MoveToCollectionModal
    await tester.pumpWidget(_wrapWithApp(const MoveToCollectionModal()));
    await tester.pumpAndSettle();

    final moveBtnFinder = find.descendant(
      of: find.byType(NeoButton),
      matching: find.text('Move to Collection'),
    );
    expect(moveBtnFinder, findsOneWidget);
    final movePaddings = tester.widgetList<Padding>(
      find.ancestor(of: moveBtnFinder, matching: find.byType(Padding)),
    );
    // Find the padding whose bottom matches modalActionButtonBottomPadding
    final moveActionPadding = movePaddings.firstWhere(
      (p) => p.padding is EdgeInsets && (p.padding as EdgeInsets).bottom == AppDimensions.modalActionButtonBottomPadding,
    );
    expect((moveActionPadding.padding as EdgeInsets).bottom, equals(AppDimensions.modalActionButtonBottomPadding));

    // 2. ShareSaveModal
    await tester.pumpWidget(_wrapWithApp(const ShareSaveModal(url: 'https://example.com')));
    await tester.pumpAndSettle();

    final shareBtnFinder = find.descendant(
      of: find.byType(NeoButton),
      matching: find.text('Save to "Unsorted"'),
    );
    expect(shareBtnFinder, findsOneWidget);
    final sharePaddings = tester.widgetList<Padding>(
      find.ancestor(of: shareBtnFinder, matching: find.byType(Padding)),
    );
    final shareActionPadding = sharePaddings.firstWhere(
      (p) => p.padding is EdgeInsets && (p.padding as EdgeInsets).bottom == AppDimensions.modalActionButtonBottomPadding,
    );
    expect((shareActionPadding.padding as EdgeInsets).bottom, equals(AppDimensions.modalActionButtonBottomPadding));

    // 3. CollectionEditorModal
    await tester.pumpWidget(_wrapWithApp(const CollectionEditorModal()));
    await tester.pumpAndSettle();

    final scrollView = tester.widget<SingleChildScrollView>(
      find.descendant(of: find.byType(CollectionEditorModal), matching: find.byType(SingleChildScrollView)),
    );
    expect((scrollView.padding as EdgeInsets).bottom, equals(AppDimensions.modalActionButtonBottomPadding));

    // 4. AddLinkModal
    await tester.pumpWidget(_wrapWithApp(const AddLinkModal()));
    await tester.pumpAndSettle();

    final addLinkContainers = tester.widgetList<Container>(
      find.descendant(of: find.byType(AddLinkModal), matching: find.byType(Container)),
    );
    final addLinkModalContainer = addLinkContainers.firstWhere(
      (c) => c.padding is EdgeInsets && (c.padding as EdgeInsets).bottom == AppDimensions.modalActionButtonBottomPadding,
    );
    expect((addLinkModalContainer.padding as EdgeInsets).bottom, equals(AppDimensions.modalActionButtonBottomPadding));
  });
}
