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

  testWidgets('All dialog header buttons share identical dialogHeaderButtonSize (39.6)', (tester) async {
    // 1. MoveToCollectionModal
    await tester.pumpWidget(_wrapWithApp(const MoveToCollectionModal()));
    await tester.pumpAndSettle();

    final moveFolderBtnFinder = find.descendant(
      of: find.byType(MoveToCollectionModal),
      matching: find.byIcon(Icons.create_new_folder_outlined),
    );
    expect(moveFolderBtnFinder, findsOneWidget);
    final moveSizedBox = tester.widget<SizedBox>(
      find.ancestor(of: moveFolderBtnFinder, matching: find.byType(SizedBox)).first,
    );
    expect(moveSizedBox.width, equals(AppDimensions.dialogHeaderButtonSize));
    expect(moveSizedBox.height, equals(AppDimensions.dialogHeaderButtonSize));

    // 2. CollectionEditorModal
    await tester.pumpWidget(_wrapWithApp(const CollectionEditorModal()));
    await tester.pumpAndSettle();

    final editCloseBtnFinder = find.descendant(
      of: find.byType(CollectionEditorModal),
      matching: find.byIcon(Icons.close),
    );
    expect(editCloseBtnFinder, findsOneWidget);
    final editSizedBox = tester.widget<SizedBox>(
      find.ancestor(of: editCloseBtnFinder, matching: find.byType(SizedBox)).first,
    );
    expect(editSizedBox.width, equals(AppDimensions.dialogHeaderButtonSize));
    expect(editSizedBox.height, equals(AppDimensions.dialogHeaderButtonSize));

    // 3. ShareSaveModal
    await tester.pumpWidget(_wrapWithApp(const ShareSaveModal(url: 'https://example.com')));
    await tester.pumpAndSettle();

    final shareFolderBtnFinder = find.descendant(
      of: find.byType(ShareSaveModal),
      matching: find.byIcon(Icons.create_new_folder_outlined),
    );
    expect(shareFolderBtnFinder, findsOneWidget);
    final shareSizedBox = tester.widget<SizedBox>(
      find.ancestor(of: shareFolderBtnFinder, matching: find.byType(SizedBox)).first,
    );
    expect(shareSizedBox.width, equals(AppDimensions.dialogHeaderButtonSize));
    expect(shareSizedBox.height, equals(AppDimensions.dialogHeaderButtonSize));

    // 4. AddLinkModal
    await tester.pumpWidget(_wrapWithApp(const AddLinkModal()));
    await tester.pumpAndSettle();

    final addLinkCloseBtnFinder = find.descendant(
      of: find.byType(AddLinkModal),
      matching: find.byIcon(Icons.close),
    );
    expect(addLinkCloseBtnFinder, findsOneWidget);
    final addLinkSizedBox = tester.widget<SizedBox>(
      find.ancestor(of: addLinkCloseBtnFinder, matching: find.byType(SizedBox)).first,
    );
    expect(addLinkSizedBox.width, equals(AppDimensions.dialogHeaderButtonSize));
    expect(addLinkSizedBox.height, equals(AppDimensions.dialogHeaderButtonSize));
  });
}
