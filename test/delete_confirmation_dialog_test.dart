import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/delete_confirmation_dialog.dart';

void main() {
  testWidgets('DeleteConfirmationDialog renders title, subtitle, Cancel and Delete buttons and returns true on Delete, false on Cancel', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await DeleteConfirmationDialog.show(context: context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Test Cancel button
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Delete link'), findsOneWidget);
    expect(find.text('Permanently delete this link?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Delete link'), findsNothing);

    // Test Delete button
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Delete link'), findsNothing);
  });
}
