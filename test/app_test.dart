import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:save_later/main.dart' as app;

void main() {
  testWidgets('App basic functions widget test', (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pump(const Duration(seconds: 1));

    // 1. Verify Home Screen is present
    expect(find.textContaining('Save now'), findsOneWidget);

    // 2. Test Quick Save UI presence
    final urlField = find.byType(TextField);
    expect(urlField, findsOneWidget);
    await tester.enterText(urlField, 'https://flutter.dev');
    
    final addIcon = find.byIcon(Icons.add);
    expect(addIcon, findsOneWidget);

    // 3. Test Create Collection Modal
    final createColIcon = find.byIcon(Icons.create_new_folder);
    expect(createColIcon, findsOneWidget);
    await tester.tap(createColIcon);
    await tester.pump(const Duration(seconds: 1));

    // Verify modal is open
    expect(find.text('New Collection'), findsOneWidget);

    // Enter collection name
    final nameField = find.byType(TextField).last;
    await tester.enterText(nameField, 'Test Collection');

    // Tap "Create Collection"
    final createColBtn = find.text('Create Collection');
    expect(createColBtn, findsOneWidget);
    await tester.tap(createColBtn);
    await tester.pump(const Duration(seconds: 1));

    // Verify collection was created and is visible
    expect(find.text('Test Collection'), findsOneWidget);
    
    // 4. Test Navigation to Review Mode
    final reviewIcon = find.byIcon(Icons.style);
    expect(reviewIcon, findsOneWidget);
    await tester.tap(reviewIcon);
    await tester.pump(const Duration(seconds: 1));

    // Verify Review mode text
    expect(find.textContaining('Review'), findsWidgets);
  });
}
