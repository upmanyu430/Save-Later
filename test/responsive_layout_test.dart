import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:save_later/models/collection.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/home_screen.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';
import 'package:save_later/ui/widgets/moved_success_dialog.dart';
import 'package:save_later/ui/widgets/no_url_dialog.dart';
import 'package:save_later/ui/widgets/collection_editor_modal.dart';
import 'package:save_later/ui/screens/settings_screen.dart';
import 'package:save_later/ui/screens/icon_picker_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUp(() async {
    dotenv.loadFromString(envString: 'APP_NAME=Save Later\nSUPPORT_EMAIL=support@example.com\n');
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Save Later',
      packageName: 'com.example.save_later',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('DeleteConfirmationDialog width is constrained to maxDialogWidth on large screens',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: DeleteConfirmationDialog(),
          ),
        ),
      ),
    );

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(DeleteConfirmationDialog),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxDialogWidth), isTrue);

    final finder = find.byType(DeleteConfirmationDialog);
    final size = tester.getSize(finder);
    expect(size.width, lessThanOrEqualTo(AppDimensions.maxDialogWidth));
  });

  testWidgets('MovedSuccessDialog width is constrained to maxDialogWidth on large screens',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: MovedSuccessDialog(),
          ),
        ),
      ),
    );

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(MovedSuccessDialog),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxDialogWidth), isTrue);

    final finder = find.byType(MovedSuccessDialog);
    final size = tester.getSize(finder);
    expect(size.width, lessThanOrEqualTo(AppDimensions.maxDialogWidth));
  });

  testWidgets('showNoUrlDialog NeoBox width is constrained to maxDialogWidth on large screens',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showNoUrlDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.byType(ConstrainedBox),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxDialogWidth), isTrue);
  });

  testWidgets('SettingsScreen content fills full width on large screens and is not clamped to maxContentWidth',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final settingsFinder = find.byType(SettingsScreen);
    final size = tester.getSize(settingsFinder);
    expect(size.width, equals(1200.0));

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: settingsFinder,
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxContentWidth), isFalse);
  });

  testWidgets('IconPickerScreen content fills full width on large screens with responsive columns',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: IconPickerScreen(
          selectedColorHex: 'FFD166',
          currentIconCode: Icons.folder.codePoint,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconPickerFinder = find.byType(IconPickerScreen);
    final size = tester.getSize(iconPickerFinder);
    expect(size.width, equals(1200.0));

    final gridFinder = find.byType(GridView);
    expect(gridFinder, findsOneWidget);
    final gridView = tester.widget<GridView>(gridFinder);
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    // On 1200 width, columnCount is calculated from constraints and exceeds previous 8 clamp
    expect(delegate.crossAxisCount, greaterThan(8));

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: iconPickerFinder,
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxContentWidth), isFalse);
  });

  testWidgets('HomeScreen fills full width on tablet (900x1200) without maxContentWidth constraint',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collectionsProvider.overrideWith((ref) => Future.value(<BookmarkCollection>[])),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final homeFinder = find.byType(HomeScreen);
    final size = tester.getSize(homeFinder);
    expect(size.width, equals(900.0));

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: homeFinder,
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxContentWidth), isFalse);
  });

  testWidgets('CollectionEditorModal close button has unified dialogHeaderButtonSize dimensions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: CollectionEditorModal(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final closeButtonFinder = find.descendant(
      of: find.byType(CollectionEditorModal),
      matching: find.byIcon(Icons.close),
    );
    expect(closeButtonFinder, findsOneWidget);

    final sizedBoxFinder = find.ancestor(
      of: closeButtonFinder,
      matching: find.byType(SizedBox),
    );
    final sizedBox = tester.widget<SizedBox>(sizedBoxFinder.first);
    expect(sizedBox.width, equals(AppDimensions.dialogHeaderButtonSize));
    expect(sizedBox.height, equals(AppDimensions.dialogHeaderButtonSize));
  });
}
