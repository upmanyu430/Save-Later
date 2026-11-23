import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/animated_checkmark.dart';

void main() {
  testWidgets('AnimatedCheckmark does not render icon when isSelected is false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedCheckmark(isSelected: false),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('AnimatedCheckmark renders icon with animation when isSelected becomes true', (tester) async {
    bool selected = false;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: InkWell(
                  onTap: () => setState(() => selected = !selected),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedCheckmark(
                        isSelected: selected,
                        color: const Color(0xFFFDD164),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsNothing);

    // Tap to select
    await tester.tap(find.byType(InkWell));
    // Pump first frame to trigger animation
    await tester.pump();

    // Icon should now be in the widget tree transitioning
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

    // Pump halfway through animation (110ms)
    await tester.pump(const Duration(milliseconds: 110));
    final checkmarkFinder = find.byType(AnimatedCheckmark);
    final scaleFinder = find.descendant(
      of: checkmarkFinder,
      matching: find.byType(ScaleTransition),
    );
    expect(scaleFinder, findsWidgets);

    // Settle animation
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle_outline));
    expect(icon.color, const Color(0xFFFDD164));
    expect(icon.size, 20);

    // Tap to unselect
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });
}
