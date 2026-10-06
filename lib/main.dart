import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/collection.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/collection_detail_screen.dart';
import 'ui/screens/review_mode_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/bookmark_detail_screen.dart';
import 'models/bookmark.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env");
  runApp(const ProviderScope(child: SaveLaterApp()));
}


final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/collection/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        final collection = state.extra as BookmarkCollection;
        return CollectionDetailScreen(collectionId: id, collection: collection);
      },
    ),
    GoRoute(
      path: '/unsorted',
      builder: (context, state) => const CollectionDetailScreen(collectionId: null, collection: null),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: ReviewModeScreen(collection: state.extra as BookmarkCollection?),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic))),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/bookmark/:id',
      builder: (context, state) {
        final bookmark = state.extra as Bookmark;
        return BookmarkDetailScreen(bookmark: bookmark);
      },
    ),
  ],
);

class SaveLaterApp extends StatelessWidget {
  const SaveLaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Save Later',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
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



