import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/pin_icon.dart';

void main() {
  testWidgets('PinIcon renders pinned state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinIcon(isPinned: true),
          ),
        ),
      ),
    );

    expect(find.byType(PinIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('PinIcon renders unpinned state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinIcon(isPinned: false),
          ),
        ),
      ),
    );

    expect(find.byType(PinIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
