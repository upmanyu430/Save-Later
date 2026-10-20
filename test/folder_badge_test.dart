import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  testWidgets('FolderBox displays "2 NEW" badge at upper right when newCount > 0', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Unsorted',
          itemCountText: '8 items',
          folderColor: Colors.grey,
          onTap: () {},
          hasNewItems: true,
          newCount: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 NEW'), findsOneWidget);
    expect(find.text('8 items'), findsOneWidget);

    // Verify positioning: 2 NEW badge is in upper right (top-right aligned)
    final badgeFinder = find.text('2 NEW');
    final itemsFinder = find.text('8 items');

    final badgeOffset = tester.getTopLeft(badgeFinder);
    final itemsOffset = tester.getTopLeft(itemsFinder);

    // Badge X is to the right of items X
    expect(badgeOffset.dx, greaterThan(itemsOffset.dx));
    // Badge is positioned higher or at top relative to items
    expect(badgeOffset.dy, lessThan(itemsOffset.dy));
  });

  testWidgets('FolderBox displays single "NEW" when newCount == 0 but hasNewItems == true', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Unsorted',
          itemCountText: '8 items',
          folderColor: Colors.grey,
          onTap: () {},
          hasNewItems: true,
          newCount: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('8 items'), findsOneWidget);
  });

  testWidgets('FolderBox hides badge when hasNewItems is false and newCount is 0', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        FolderBox(
          title: 'Tech',
          itemCountText: '8 items',
          folderColor: Colors.purple,
          onTap: () {},
          hasNewItems: false,
          newCount: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('NEW'), findsNothing);
    expect(find.text('8 items'), findsOneWidget);
  });
}
