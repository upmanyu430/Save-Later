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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      builder: (context, state) => ReviewModeScreen(collection: state.extra as BookmarkCollection?),
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
  const SaveLaterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Save Later',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}



