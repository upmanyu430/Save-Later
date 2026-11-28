import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:save_later/ui/widgets/app_launch_overlay.dart';

class _MountProbe extends StatefulWidget {
  final VoidCallback onInit;
  final VoidCallback onDispose;

  const _MountProbe({
    required this.onInit,
    required this.onDispose,
  });

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Live Home Child')),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDown(() {
    LaunchTransitionCoordinator.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'AppLaunchOverlay keeps child mounted in fixed slot, removes splash on Frame 1, and unmounts cleanly',
    (tester) async {
      int initCount = 0;
      int disposeCount = 0;
      int firstFrameCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLaunchOverlay(
            hapticFeedback: false,
            onFirstFrame: () => firstFrameCalls++,
            child: _MountProbe(
              onInit: () => initCount++,
              onDispose: () => disposeCount++,
            ),
          ),
        ),
      );

      // Frame 1 post-frame callback has fired.
      expect(firstFrameCalls, 1);
      expect(initCount, 1);
      expect(disposeCount, 0);
      expect(find.text('Live Home Child'), findsOneWidget);
      expect(find.text('SAVE LATER'), findsOneWidget);

      // Underlying child starts scaled at 0.96 (never 0.0) on X/Y axes.
      final childTransformStart = tester.widget<Transform>(
        find.descendant(
          of: find.byType(AppLaunchOverlay),
          matching: find.byType(Transform),
        ).first,
      );
      expect(childTransformStart.transform.storage[0], closeTo(0.96, 0.001));
      expect(childTransformStart.transform.storage[5], closeTo(0.96, 0.001));

      // First tick anchors the animation clock, then advance into Stage 2/3.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(initCount, 1);
      expect(disposeCount, 0);
      expect(
        LaunchTransitionCoordinator.remainingCardSlamDelay(),
        greaterThan(Duration.zero),
      );

      // Complete full 720ms choreography and settle.
      await tester.pumpAndSettle();

      expect(initCount, 1);
      expect(disposeCount, 0);
      expect(find.text('Live Home Child'), findsOneWidget);
      // Overlay completely unmounted after completion.
      expect(find.text('SAVE LATER'), findsNothing);
      expect(LaunchTransitionCoordinator.remainingCardSlamDelay(), Duration.zero);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('AppLaunchOverlay fires a single light haptic on Stage 2 pop when enabled', (tester) async {
    final haptics = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments.toString());
      }
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppLaunchOverlay(
          hapticFeedback: true,
          onFirstFrame: () {},
          child: const Scaffold(body: Text('Child')),
        ),
      ),
    );

    // First ticker frame starts animation at t = 0ms.
    await tester.pump();

    // Stage 1 (0-130ms): no haptic yet.
    await tester.pump(const Duration(milliseconds: 80));
    expect(haptics, isEmpty);

    // Cross into Stage 2 (>= 130ms): fires exactly one lightImpact.
    await tester.pump(const Duration(milliseconds: 100));
    expect(haptics, ['HapticFeedbackType.lightImpact']);

    // Finish entire animation: still only one haptic.
    await tester.pumpAndSettle();
    expect(haptics.length, 1);
  });

  testWidgets('AppLaunchOverlay skips haptic when hapticFeedback is false', (tester) async {
    final haptics = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments.toString());
      }
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AppLaunchOverlay(
          hapticFeedback: false,
          onFirstFrame: () {},
          child: const Scaffold(body: Text('Child')),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
  });

  testWidgets('AppLaunchOverlay skips immediately when Reduce Motion is enabled', (tester) async {
    int firstFrameCalls = 0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: AppLaunchOverlay(
            hapticFeedback: true,
            onFirstFrame: () => firstFrameCalls++,
            child: const Scaffold(body: Text('Child')),
          ),
        ),
      ),
    );

    expect(firstFrameCalls, 1);
    expect(find.text('SAVE LATER'), findsNothing);
    expect(find.text('Child'), findsOneWidget);
    expect(LaunchTransitionCoordinator.remainingCardSlamDelay(), Duration.zero);

    final settledFrames = await tester.pumpAndSettle();
    expect(settledFrames, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('AppLaunchOverlay skips immediately when opened via Share Intent', (tester) async {
    int firstFrameCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppLaunchOverlay(
          hapticFeedback: true,
          skipAnimation: true,
          onFirstFrame: () => firstFrameCalls++,
          child: const Scaffold(body: Text('Share Target Child')),
        ),
      ),
    );

    expect(firstFrameCalls, 1);
    expect(find.text('SAVE LATER'), findsNothing);
    expect(find.text('Share Target Child'), findsOneWidget);
    expect(LaunchTransitionCoordinator.remainingCardSlamDelay(), Duration.zero);

    final settledFrames = await tester.pumpAndSettle();
    expect(settledFrames, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
