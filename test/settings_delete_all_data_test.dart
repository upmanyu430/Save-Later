import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:save_later/repositories/isar_repository.dart';
import 'package:save_later/providers/providers.dart';
import 'package:save_later/ui/screens/settings_screen.dart';

class FakeIsar extends Fake implements Isar {
  bool cleared = false;

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    return await callback();
  }

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

class FakeSettingsIsarRepository extends Fake implements IsarRepository {
  final fakeIsar = FakeIsar();

  @override
  Future<Isar> get db async => fakeIsar;
}

Widget buildTestApp({required Widget home}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: home,
  );
}

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP_NAME=Save Later\nSUPPORT_EMAIL=support@example.com\n');
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Save Later',
      packageName: 'app.savelater.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('SettingsScreen Delete All Data clears DB and invalidates all collection, bookmark, and tag providers', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = FakeSettingsIsarRepository();

    var allCollectionsInvalidated = false;
    var collectionsInvalidated = false;
    var bookmarksInvalidated = false;
    var unsortedInvalidated = false;
    var singleCollectionInvalidated = false;
    var subCollectionsInvalidated = false;
    var collectionBookmarksInvalidated = false;
    var allTagsInvalidated = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(fakeRepo),
          allCollectionsProvider.overrideWith((ref) => Future.value([])),
          collectionsProvider.overrideWith((ref) => Future.value([])),
          bookmarksProvider.overrideWith((ref) => Future.value([])),
          unsortedBookmarksProvider.overrideWith((ref) => Future.value([])),
          singleCollectionProvider(1).overrideWith((ref) => Future.value(null)),
          subCollectionsProvider(1).overrideWith((ref) => Future.value([])),
          collectionBookmarksProvider(1).overrideWith((ref) => Future.value([])),
          allTagsProvider.overrideWith((ref) => Future.value([])),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            // Listen to all providers to verify invalidation triggers
            ref.listen(allCollectionsProvider, (_, __) => allCollectionsInvalidated = true);
            ref.listen(collectionsProvider, (_, __) => collectionsInvalidated = true);
            ref.listen(bookmarksProvider, (_, __) => bookmarksInvalidated = true);
            ref.listen(unsortedBookmarksProvider, (_, __) => unsortedInvalidated = true);
            ref.listen(singleCollectionProvider(1), (_, __) => singleCollectionInvalidated = true);
            ref.listen(subCollectionsProvider(1), (_, __) => subCollectionsInvalidated = true);
            ref.listen(collectionBookmarksProvider(1), (_, __) => collectionBookmarksInvalidated = true);
            ref.listen(allTagsProvider, (_, __) => allTagsInvalidated = true);

            return buildTestApp(
              home: const SettingsScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find "Delete All Data" tile
    final deleteAllTile = find.text('Delete All Data');
    expect(deleteAllTile, findsOneWidget);
    await tester.tap(deleteAllTile);
    await tester.pumpAndSettle();

    // Dialog appears with confirmation button "Delete"
    final confirmDeleteButton = find.text('Delete');
    expect(confirmDeleteButton, findsOneWidget);
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    // Verify DB clear was called
    expect(fakeRepo.fakeIsar.cleared, isTrue);

    // Verify all caches and providers were invalidated
    expect(allCollectionsInvalidated, isTrue);
    expect(collectionsInvalidated, isTrue);
    expect(bookmarksInvalidated, isTrue);
    expect(unsortedInvalidated, isTrue);
    expect(singleCollectionInvalidated, isTrue);
    expect(subCollectionsInvalidated, isTrue);
    expect(collectionBookmarksInvalidated, isTrue);
    expect(allTagsInvalidated, isTrue);

    // Verify snackbar is shown
    expect(find.text('All data deleted successfully.'), findsOneWidget);
  });
}
