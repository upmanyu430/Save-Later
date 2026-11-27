import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:save_later/providers/app_settings_provider.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/theme/app_theme.dart';
import 'package:save_later/ui/screens/home_screen.dart';
import 'package:save_later/ui/screens/settings_screen.dart';
import 'package:save_later/ui/widgets/neo_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required Widget home,
  required AppSettingsState settings,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: settings.themeMode,
    locale: settings.locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString:
          'APP_NAME=Save Later\nSUPPORT_EMAIL=support@example.com\nPLAY_STORE_URL=https://play.google.com/store/apps/details?id=app.savelater.app\n',
    );
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Save Later',
      packageName: 'app.savelater.app',
      version: '1.7.2',
      buildNumber: '21',
      buildSignature: '',
    );
  });

  testWidgets('SettingsScreen displays all new options, version+build, and grouped cards', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('Haptic Feedback'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Home Headline'), findsOneWidget);
    expect(find.text('New Save Reminders'), findsOneWidget);

    expect(find.text('DATA & STORAGE'), findsOneWidget);
    expect(find.text('Cloud Sync'), findsOneWidget);
    expect(find.text('Backup & Restore'), findsOneWidget);

    expect(find.text('SUPPORT'), findsOneWidget);
    expect(find.text('How To'), findsOneWidget);
    expect(find.text('Send Feedback'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);

    expect(find.text('ACCOUNT'), findsOneWidget);
    expect(find.text('Rate Save Later on Google Play'), findsOneWidget);
    expect(find.text('Delete All Data'), findsOneWidget);

    expect(find.text('Version 1.7.2 (build 21)'), findsOneWidget);
    expect(find.text('Copy user ID'), findsOneWidget);

    final groupedCards = tester.widgetList<NeoBox>(find.byType(NeoBox)).toList();
    expect(groupedCards, hasLength(4));
    for (final card in groupedCards) {
      expect(card.borderRadius, AppDimensions.radiusXxl);
      final clip = card.child as ClipRRect;
      expect(
        clip.borderRadius,
        BorderRadius.circular(
          AppDimensions.radiusXxl - AppDimensions.borderWidthMd,
        ),
      );
    }
  });

  testWidgets('Dark Mode toggle switches ThemeMode and persists to SharedPreferences', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the Dark Mode CupertinoSwitch (2nd switch: Haptic=0, DarkMode=1, Reminders=2)
    final switches = find.byType(CupertinoSwitch);
    expect(switches, findsNWidgets(3));

    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.dark.background);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('darkMode'), isTrue);
  });

  testWidgets('Language picker changes active locale to Spanish', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Language'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Modo oscuro'), findsOneWidget);
  });

  testWidgets('Home Headline modal updates headline on HomeScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer(
      overrides: [
        collectionsProvider.overrideWith((ref) => Future.value([])),
        unsortedBookmarksProvider.overrideWith((ref) => Future.value([])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home Headline'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Home Headline'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'My Custom\nLibrary');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('My Custom Library'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Custom\nLibrary'), findsOneWidget);
  });

  testWidgets('Cloud Sync opens Coming Soon sheet and Copy user ID copies persistent UUID to clipboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? copiedClipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          copiedClipboardText =
              (methodCall.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(appSettingsProvider);
            return _buildTestApp(
              settings: settings,
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Cloud Sync -> opens Coming Soon modal
    await tester.tap(find.text('Cloud Sync'));
    await tester.pumpAndSettle();
    expect(find.text('Cloud Sync Coming Soon'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    // Tap Copy user ID -> copies UUIDv4 to clipboard
    final copyButton = find.text('Copy user ID');
    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    expect(copiedClipboardText, isNotNull);
    expect(copiedClipboardText!.length, 36);
    expect(find.text('User ID copied to clipboard'), findsOneWidget);
  });
}
