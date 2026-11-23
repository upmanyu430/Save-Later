import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/ui/widgets/move_to_collection_modal.dart';
import 'package:save_later/ui/widgets/share_save_modal.dart';

class _BreakUiRepo implements IsarRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final List<BookmarkCollection> collectionsList = [];

  @override
  Future<List<BookmarkCollection>> getAllCollections() async => collectionsList;

  @override
  Future<List<BookmarkCollection>> getCollections({int? parentId}) async => collectionsList;

  @override
  Future<List<BookmarkCollection>> getSubCollections(int parentId) async =>
      collectionsList.where((c) => c.parentId == parentId).toList();

  @override
  Future<BookmarkCollection?> getCollection(int id) async =>
      collectionsList.where((c) => c.id == id).firstOrNull;
}

Widget _buildHarness({
  required Widget child,
  required _BreakUiRepo repo,
  double width = 390.0,
  double height = 844.0,
  double textScale = 1.0,
  Locale locale = const Locale('en', ''),
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      allCollectionsProvider.overrideWith((ref) => Future.value(repo.collectionsList)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Collection name boundary and sanitization tests', () {
    test('enforces max length 40 and trims whitespace', () {
      expect(BookmarkCollection.maxNameLength, equals(40));

      final trimmed = BookmarkCollection.sanitizeName('   Design Systems   ');
      expect(trimmed, equals('Design Systems'));

      final tooLong = 'A' * 60;
      final sanitized = BookmarkCollection.sanitizeName(tooLong);
      expect(sanitized.length, equals(40));
      expect(sanitized, equals('A' * 40));
    });

    test('formatTargetLabel helper respects <=22 boundary and middle-truncates long labels', () {
      // <= 22 chars: exact full string
      expect(
        MoveToCollectionModal.formatTargetLabel('Move to', 'Tech'),
        equals('Move to "Tech"'),
      );
      expect(
        MoveToCollectionModal.formatTargetLabel('Move to', '1234567890123456789012'),
        equals('Move to "1234567890123456789012"'),
      );

      // > 22 chars: preserves opening and closing quotes with middle ellipsis
      const longName = 'Senior Product Design Engineer Platform';
      final formatted = MoveToCollectionModal.formatTargetLabel('Move to', longName);
      expect(formatted, equals('Move to "Senior Pro...Platform"'));
      expect(formatted.startsWith('Move to "'), isTrue);
      expect(formatted.endsWith('"'), isTrue);
    });
  });

  testWidgets('Break UI Test: Feed worst-case realistic data into MoveToCollectionModal', (tester) async {
    final repo = _BreakUiRepo();

    // 1. Parent collection with long name
    final parent = BookmarkCollection()
      ..id = 1
      ..name = 'Christopher Alexander Montgomery III'
      ..colorHex = 'FF2196F3'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(parent);

    // 2. Child collection under long parent with long title
    final child1 = BookmarkCollection()
      ..id = 2
      ..name = 'Senior Product Design Engineer Platform'
      ..parentId = 1
      ..colorHex = 'FF4CAF50'
      ..iconCodePoint = Icons.design_services.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(child1);

    // 3. German compound word (no spaces)
    final colGerman = BookmarkCollection()
      ..id = 3
      ..name = 'Benachrichtigungseinstellungen'
      ..colorHex = 'FFE91E63'
      ..iconCodePoint = Icons.settings.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(colGerman);

    // 4. One-letter name
    final colShort = BookmarkCollection()
      ..id = 4
      ..name = 'J'
      ..colorHex = 'FFFF9800'
      ..iconCodePoint = Icons.star.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(colShort);

    // 5. RTL name
    final colRtl = BookmarkCollection()
      ..id = 5
      ..name = 'نور الهدى عبد الرحمن'
      ..colorHex = 'FF9C27B0'
      ..iconCodePoint = Icons.menu_book.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(colRtl);

    // 6. ZWJ emoji prefix
    final colEmoji = BookmarkCollection()
      ..id = 6
      ..name = '👩🏽‍💻 Core Engineering'
      ..colorHex = 'FF00BCD4'
      ..iconCodePoint = Icons.code.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(colEmoji);

    // 7. Script injection text
    final colScript = BookmarkCollection()
      ..id = 7
      ..name = '<script>alert(1)</script>'
      ..colorHex = 'FF607D8B'
      ..iconCodePoint = Icons.security.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(colScript);

    // Pump MoveToCollectionModal at 360 width
    await tester.pumpWidget(
      _buildHarness(
        child: const MoveToCollectionModal(),
        repo: repo,
        width: 360,
      ),
    );
    await tester.pumpAndSettle();

    // Verify no render overflows at 360px width
    expect(tester.takeException(), isNull);

    // Verify Tooltip widgets are rendered for accessibility and inspection
    expect(find.byType(Tooltip), findsWidgets);
    expect(find.widgetWithText(Tooltip, 'Unsorted'), findsOneWidget);

    // Verify sub-collection label displays 'in Christopher Alexander Montgomery III' without overflowing
    expect(find.text('in Christopher Alexander Montgomery III'), findsOneWidget);

    // Tap on the child collection under long parent to select it
    await tester.tap(find.text('Senior Product Design Engineer Platform'));
    await tester.pumpAndSettle();

    // Verify button label updates with middle-truncation and intact closing quote
    expect(find.text('Move to "Senior Pro...Platform"'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap on Unsorted
    await tester.tap(find.text('Unsorted'));
    await tester.pumpAndSettle();
    expect(find.text('Move to "Unsorted"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Break UI Test: Feed worst-case realistic data into ShareSaveModal', (tester) async {
    final repo = _BreakUiRepo();

    final parent = BookmarkCollection()
      ..id = 1
      ..name = 'Christopher Alexander Montgomery III'
      ..colorHex = 'FF2196F3'
      ..iconCodePoint = Icons.folder.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(parent);

    final child = BookmarkCollection()
      ..id = 2
      ..name = 'Senior Product Design Engineer Platform'
      ..parentId = 1
      ..colorHex = 'FF4CAF50'
      ..iconCodePoint = Icons.design_services.codePoint
      ..iconFontFamily = kStoredIconFontFamily;
    repo.collectionsList.add(child);

    // Test with unbreakable long URL with many query params
    const worstCaseUrl = 'https://example.com/workspaces/acme/projects/q3-launch/docs/9f8e7d6c5b4a?tab=comments&filter=unresolved&session=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';

    await tester.pumpWidget(
      _buildHarness(
        child: ShareSaveModal(
          url: worstCaseUrl,
          onSave: (col, isPinned) async {},
        ),
        repo: repo,
        width: 320,
        textScale: 1.5,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Verify Tooltips exist
    expect(find.byType(Tooltip), findsWidgets);
    expect(find.widgetWithText(Tooltip, 'Unsorted'), findsOneWidget);

    // Tap on child collection
    await tester.tap(find.text('Senior Product Design Engineer Platform'));
    await tester.pumpAndSettle();

    // Verify button label updates with middle-truncation and intact quotes
    expect(find.text('Save to "Senior Pro...Platform"'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
