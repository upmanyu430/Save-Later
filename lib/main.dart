import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/collection.dart';
import 'providers/app_settings_provider.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/collection_detail_screen.dart';
import 'ui/screens/review_mode_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/bookmark_detail_screen.dart';
import 'ui/widgets/theme_transition_overlay.dart';
import 'models/bookmark.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _lightSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

const _darkSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_lightSystemUiOverlayStyle);
  try {
    await dotenv
        .load(fileName: 'assets/env')
        .timeout(const Duration(seconds: 2));
  } catch (error) {
    // Configuration is optional at runtime; AppConfig provides safe defaults.
    debugPrint('Unable to load optional app configuration: $error');
  }
  runApp(const ProviderScope(child: SaveLaterApp()));
}

CustomTransitionPage<T> _buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: const Cubic(0.23, 1.0, 0.32, 1.0)))),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> _buildBookmarkTransitionPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.black38,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.23, 1.0, 0.32, 1.0),
        reverseCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: ScaleTransition(
          scale: curvedAnimation,
          alignment: Alignment.center,
          child: RepaintBoundary(
            child: child,
          ),
        ),
      );
    },
    child: child,
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/collection/:id',
      pageBuilder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final collection = state.extra as BookmarkCollection?;
        return _buildPageWithTransition(
          context: context,
          state: state,
          child: CollectionDetailScreen(collectionId: id, collection: collection),
        );
      },
    ),
    GoRoute(
      path: '/unsorted',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const CollectionDetailScreen(collectionId: null, collection: null),
      ),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: ReviewModeScreen(collection: state.extra as BookmarkCollection?),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        context: context,
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        final tabStr = state.uri.queryParameters['tab'] ??
            (state.extra is Map ? (state.extra as Map)['tab'] as String? : null);
        final initialTab = tabStr == 'tags'
            ? LibraryTab.tags
            : LibraryTab.overview;
        return _buildPageWithTransition(
          context: context,
          state: state,
          child: SearchScreen(initialTab: initialTab),
        );
      },
    ),
    GoRoute(
      path: '/bookmark/:id',
      pageBuilder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final bookmark = state.extra as Bookmark?;
        return _buildBookmarkTransitionPage(
          context: context,
          state: state,
          child: BookmarkDetailScreen(
            bookmark: bookmark,
            bookmarkId: id,
          ),
        );
      },
    ),
  ],
);

class SaveLaterApp extends ConsumerWidget {
  const SaveLaterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (themeMode, locale, darkMode) = ref.watch(
      appSettingsProvider.select((s) => (s.themeMode, s.locale, s.darkMode)),
    );
    final overlayStyle =
        darkMode ? _darkSystemUiOverlayStyle : _lightSystemUiOverlayStyle;

    return MaterialApp.router(
      title: 'Save Later',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      locale: locale,
      routerConfig: _router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: ThemeTransitionScope(
            child: ColoredBox(
              color: context.appColors.background,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
