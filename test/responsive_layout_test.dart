import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';
import 'package:save_later/ui/widgets/moved_success_dialog.dart';
import 'package:save_later/ui/widgets/no_url_dialog.dart';
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

  testWidgets('SettingsScreen content is constrained to maxContentWidth on large screens',
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

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxContentWidth), isTrue);
  });

  testWidgets('IconPickerScreen content is constrained to maxContentWidth on large screens',
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

    final constrainedBoxes = tester.widgetList<ConstrainedBox>(
      find.descendant(
        of: find.byType(IconPickerScreen),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(constrainedBoxes.any((cb) => cb.constraints.maxWidth == AppDimensions.maxContentWidth), isTrue);
  });
}
