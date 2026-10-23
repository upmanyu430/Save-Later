import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/theme/app_theme.dart';
import 'package:save_later/ui/widgets/folder_box.dart';

Widget createTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(
      body: SizedBox(
        width: 180,
        height: 180,
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('FolderBox uses white icon for dark/black folderColor', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Tech',
          itemCountText: '7 items',
          folderColor: const Color(0xFF1C1C1C), // Pitch-black tech folder
          icon: Icons.code,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconFinder = find.byIcon(Icons.code);
    expect(iconFinder, findsOneWidget);

    final Icon iconWidget = tester.widget(iconFinder);
    expect(iconWidget.color, Colors.white,
        reason: 'Dark folder colors must render white icons for clear contrast');
  });

  testWidgets('FolderBox uses border color (black) icon for light folderColor', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Sample',
          itemCountText: '0 items',
          folderColor: const Color(0xFFA2D149), // Lime green
          icon: Icons.palette,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconFinder = find.byIcon(Icons.palette);
    expect(iconFinder, findsOneWidget);

    final Icon iconWidget = tester.widget(iconFinder);
    expect(iconWidget.color, AppTheme.border,
        reason: 'Light folder colors must render black border-color icons');
  });
}
