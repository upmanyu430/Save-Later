import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/review_cards_icon.dart';
import 'package:save_later/ui/widgets/neo_box.dart';

void main() {
  testWidgets('ReviewCardsIcon renders CustomPaint with specified parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NeoBox(
              color: Color(0xFFFFD166),
              child: ReviewCardsIcon(size: 28),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ReviewCardsIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
