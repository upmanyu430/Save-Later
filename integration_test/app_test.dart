import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:save_later/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App basic functions test', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 1. Verify Home Screen is present
    expect(find.textContaining('Save now'), findsOneWidget);

    // 2. Test Quick Save
    // Find the url text field
    final urlField = find.byType(TextField);
    expect(urlField, findsOneWidget);
    await tester.enterText(urlField, 'https://flutter.dev');
    
    // Tap the submit button
    // It's the NeoButton inside the row.
    final addIcon = find.byIcon(Icons.add);
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Wait for the metadata fetch to complete
    // Since it's a real HTTP call, we'll give it some time
    await tester.pump(const Duration(seconds: 3));

    // 3. Test Create Collection Modal
    final createColIcon = find.byIcon(Icons.create_new_folder_outlined);
    expect(createColIcon, findsOneWidget);
    await tester.tap(createColIcon);
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.text('Add new collection'), findsOneWidget);

    // Enter collection name
    final nameField = find.byType(TextField).last;
    await tester.enterText(nameField, 'Test Collection');

    // Tap "Create Collection"
    final createColBtn = find.text('Create collection');
    expect(createColBtn, findsOneWidget);
    await tester.tap(createColBtn);
    await tester.pumpAndSettle();

    // Verify collection was created and is visible
    expect(find.text('Test Collection'), findsOneWidget);
    
    // Test completed: Quick Save + Create Collection exercised on Home.
  });
}
