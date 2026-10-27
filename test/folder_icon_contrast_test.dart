import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/theme/app_theme.dart';
import 'package:save_later/ui/widgets/folder_box.dart';
import 'package:save_later/models/collection.dart';

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
  testWidgets('FolderBox uses white icon only for Black (#1C1C1C) and Slate Blue/Purple (#6A5ACD)', (tester) async {
    // 1. Black (0xFF1C1C1C) -> White icon
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Tech',
          itemCountText: '7 items',
          folderColor: const Color(0xFF1C1C1C),
          icon: Icons.code,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final techIcon = tester.widget<Icon>(find.byIcon(Icons.code));
    expect(techIcon.color, Colors.white,
        reason: '#1C1C1C must render white icon');

    // 2. Slate Blue / Purple (0xFF6A5ACD) -> White icon
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Purple',
          itemCountText: '3 items',
          folderColor: const Color(0xFF6A5ACD),
          icon: Icons.star_outline,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final purpleIcon = tester.widget<Icon>(find.byIcon(Icons.star_outline));
    expect(purpleIcon.color, Colors.white,
        reason: '#6A5ACD must render white icon');
  });

  testWidgets('FolderBox uses border color (black) icon for all other colors', (tester) async {
    // 1. Lime green (0xFFA2D149) -> Black/border icon
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Sample',
          itemCountText: '0 items',
          folderColor: const Color(0xFFA2D149),
          icon: Icons.palette,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final limeIcon = tester.widget<Icon>(find.byIcon(Icons.palette));
    expect(limeIcon.color, AppTheme.border,
        reason: 'Lime folder color must render black border-color icons');

    // 2. Blue (0xFF4A90E2) -> Black/border icon (not white, only 1C1C1C and 6A5ACD are white)
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Blue',
          itemCountText: '5 items',
          folderColor: const Color(0xFF4A90E2),
          icon: Icons.favorite_outline,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final blueIcon = tester.widget<Icon>(find.byIcon(Icons.favorite_outline));
    expect(blueIcon.color, AppTheme.border,
        reason: 'Blue folder color must render black border-color icon');
  });

  test('BookmarkCollection.isWhiteIconColor helper works accurately', () {
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFF1C1C1C)), isTrue);
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFF6A5ACD)), isTrue);
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFF4A90E2)), isFalse);
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFFA0522D)), isFalse);
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFFE74C3C)), isFalse);
    expect(BookmarkCollection.isWhiteIconColor(const Color(0xFFFFD166)), isFalse);
  });
}
