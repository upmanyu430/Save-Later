import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/collection.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/screens/collection_detail_screen.dart';
import 'ui/screens/review_mode_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/bookmark_detail_screen.dart';
import 'ui/widgets/app_launch_overlay.dart';
import 'models/bookmark.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _systemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);
  try {
    await dotenv
        .load(fileName: 'assets/env')
        .timeout(const Duration(seconds: 2));
  } catch (error) {
    // Configuration is optional at runtime; AppConfig provides safe defaults.
    debugPrint('Unable to load optional app configuration: $error');
  }

  bool hasSeenWelcome = false;
  bool hapticFeedback = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
    hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
  } catch (error) {
    debugPrint('Unable to load SharedPreferences at startup: $error');
  }

  bool openedViaShareIntent = false;
  try {
    final initialMedia = await ReceiveSharingIntent.instance
        .getInitialMedia()
        .timeout(const Duration(milliseconds: 500));
    openedViaShareIntent = initialMedia.isNotEmpty;
  } catch (error) {
    debugPrint('Unable to check initial share intent: $error');
  }

  runApp(
    ProviderScope(
      child: SaveLaterApp(
        hasSeenWelcome: hasSeenWelcome,
        hapticFeedback: hapticFeedback,
        skipLaunchAnimation: openedViaShareIntent,
      ),
    ),
  );
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

GoRouter _createRouter({
  required String initialLocation,
  required bool hapticFeedback,
}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/welcome',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context: context,
            state: state,
            child: WelcomeScreen(hapticFeedback: hapticFeedback),
          ),
        ),
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

class SaveLaterApp extends StatefulWidget {
  final bool hasSeenWelcome;
  final bool hapticFeedback;
  final bool skipLaunchAnimation;

  const SaveLaterApp({
    super.key,
    this.hasSeenWelcome = true,
    this.hapticFeedback = true,
    this.skipLaunchAnimation = false,
  });

  @override
  State<SaveLaterApp> createState() => _SaveLaterAppState();
}

class _SaveLaterAppState extends State<SaveLaterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final initialLocation =
        (!widget.hasSeenWelcome && !widget.skipLaunchAnimation)
            ? '/welcome'
            : '/';
    _router = _createRouter(
      initialLocation: initialLocation,
      hapticFeedback: widget.hapticFeedback,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Save Later',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyle,
          child: ColoredBox(
            color: AppTheme.background,
            child: AppLaunchOverlay(
              hapticFeedback: widget.hapticFeedback,
              skipAnimation: widget.skipLaunchAnimation,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), 
      ],
    );
  }
}
