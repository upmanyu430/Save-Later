import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:save_later/theme/app_theme.dart';
import 'package:save_later/ui/widgets/empty_collection_view.dart';
import 'package:save_later/ui/widgets/neo_button.dart';

double calculateContrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

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
      body: Center(
        child: child,
      ),
    ),
  );
}

void main() {
  group('Antislop UI Standards Verification', () {
    group('WCAG AA Contrast Ratios (R-01)', () {
      test(
          'AppTheme.textSecondary achieves >= 4.5:1 WCAG AA contrast ratio on AppTheme.background',
          () {
        final contrast = calculateContrastRatio(
            AppTheme.textSecondary, AppTheme.background);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason:
              'textSecondary contrast on background ($contrast:1) must meet WCAG AA threshold of 4.5:1',
        );
      });

      test(
          'AppTheme.textMuted achieves >= 4.5:1 WCAG AA contrast ratio on AppTheme.background',
          () {
        final contrast =
            calculateContrastRatio(AppTheme.textMuted, AppTheme.background);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason:
              'textMuted contrast on background ($contrast:1) must meet WCAG AA threshold of 4.5:1',
        );
      });

      test(
          'AppColors.dark text tokens achieve >= 4.5:1 WCAG AA contrast on dark background and card',
          () {
        for (final bg in [AppColors.dark.background, AppColors.dark.card]) {
          expect(
            calculateContrastRatio(AppColors.dark.textPrimary, bg),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            calculateContrastRatio(AppColors.dark.textSecondary, bg),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            calculateContrastRatio(AppColors.dark.textMuted, bg),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    });

    group('Keyboard Accessibility & Activation (R-32)', () {
      testWidgets(
          'NeoButton can receive keyboard focus and activate via ActivateIntent',
          (tester) async {
        bool activated = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            NeoButton(
              focusNode: focusNode,
              onPressed: () => activated = true,
              child: const Text('Accessible NeoButton'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify NeoButton can receive keyboard focus
        focusNode.requestFocus();
        await tester.pump();
        expect(focusNode.hasFocus, isTrue,
            reason: 'NeoButton should receive keyboard focus');

        // 2. Activate via ActivateIntent (Action invocation)
        final childFinder = find.text('Accessible NeoButton');
        expect(childFinder, findsOneWidget);

        Actions.invoke(tester.element(childFinder), const ActivateIntent());
        await tester.pumpAndSettle();
        expect(activated, isTrue,
            reason: 'NeoButton should activate via ActivateIntent');

        focusNode.dispose();
      });

      testWidgets(
          'NeoButton can activate via ButtonActivateIntent and keyboard Enter/Space keys',
          (tester) async {
        int activations = 0;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            NeoButton(
              focusNode: focusNode,
              onPressed: () => activations++,
              child: const Text('Key Test Button'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        focusNode.requestFocus();
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);

        // Press Enter key
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(activations, 1,
            reason: 'Enter key should trigger button activation');

        // Press Space key
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(activations, 2,
            reason: 'Space key should trigger button activation');

        focusNode.dispose();
      });

      testWidgets(
          'NeoButton respects minimum 44dp hit test interactive boundary',
          (tester) async {
        final buttonFinder = find.byType(NeoButton);

        await tester.pumpWidget(
          createTestApp(
            const NeoButton(
              minTouchTargetSize: 44.0,
              padding: EdgeInsets.zero,
              child: SizedBox(width: 30, height: 30),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonRenderBox =
            tester.renderObject(buttonFinder) as RenderBox;
        expect(buttonRenderBox.size.width, greaterThanOrEqualTo(44.0));
        expect(buttonRenderBox.size.height, greaterThanOrEqualTo(44.0));
      });
    });

    group('Calm Motion & Absence of Endless Loops (R-19)', () {
      testWidgets(
          'EmptyCollectionView does not repeat animation endlessly and settles calmly',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const EmptyCollectionView(),
          ),
        );

        // If animation repeated endlessly via repeat(reverse: true), pumpAndSettle would timeout.
        // With a calm entrance transition, pumpAndSettle finishes and settles to rest.
        await tester.pumpAndSettle();

        // Verify no pending frames are scheduled (resting state is calm and motionless)
        expect(tester.binding.hasScheduledFrame, isFalse,
            reason:
                'EmptyCollectionView must not continuously schedule animation frames at rest');
      });

      testWidgets(
          'EmptyFolderGraphic finishes entrance transition within its duration',
          (tester) async {
        await tester.pumpWidget(
          createTestApp(
            const EmptyFolderGraphic(animate: true),
          ),
        );

        // Pump 700ms (entrance duration is 650ms)
        await tester.pump(const Duration(milliseconds: 700));

        // After completion, verify it has settled
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    });
  });
}
