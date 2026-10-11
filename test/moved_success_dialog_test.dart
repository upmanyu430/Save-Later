import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/moved_success_dialog.dart';

void main() {
  testWidgets('MovedSuccessDialog renders correct elements and dismisses on OK tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => MovedSuccessDialog.show(context: context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Moved successfully'), findsOneWidget);
    expect(find.text('The link has been moved to the selected collection.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Moved successfully'), findsNothing);
  });
}
