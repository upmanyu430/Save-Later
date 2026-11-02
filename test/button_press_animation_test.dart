import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/ui/widgets/neo_button.dart';
import 'package:save_later/ui/widgets/neo_pressable.dart';

void main() {
  group('NeoButton touch responsiveness (Emil Kowalski principles)', () {
    testWidgets('animates immediately on touch down and completes on release', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(
                onPressed: () => pressed = true,
                child: const Text('Touch Me'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Touch Me');
      expect(buttonFinder, findsOneWidget);

      // Touch down
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 30));

      // Should be animating down (not yet triggered)
      expect(pressed, isFalse);

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      // Triggered after completion
      expect(pressed, isTrue);
    });

    testWidgets('cancels press animation when dragged beyond scroll threshold', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(
                onPressed: () => pressed = true,
                child: const Text('Scroll Me'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.text('Scroll Me');
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 20));

      // Drag vertically beyond threshold (scrolling)
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });

    testWidgets('tester.tap invokes onPressed', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(
                onPressed: () => pressed = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('NeoPressable touch responsiveness (Emil Kowalski principles)', () {
    testWidgets('animates immediately on touch down and completes on release', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoPressable(
                onTap: () => tapped = true,
                builder: (context, t, shadow) {
                  return Container(
                    width: 100,
                    height: 50,
                    color: Colors.amber,
                    child: const Text('Pressable'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = find.text('Pressable');
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump(const Duration(milliseconds: 30));

      expect(tapped, isFalse);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('cancels press animation when dragged beyond threshold', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoPressable(
                onTap: () => tapped = true,
                builder: (context, t, shadow) {
                  return Container(
                    width: 100,
                    height: 50,
                    color: Colors.amber,
                    child: const Text('Drag Pressable'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = find.text('Drag Pressable');
      final gesture = await tester.startGesture(tester.getCenter(finder));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });
}
