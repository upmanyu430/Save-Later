import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../providers/providers.dart';
import '../../utils/url_helper.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/no_url_dialog.dart';
import '../widgets/folder_box.dart';
import '../widgets/collection_grid_item.dart';
import '../widgets/collection_editor_modal.dart';
import '../widgets/share_save_modal.dart';
import '../../theme/app_theme.dart';
import '../../models/bookmark.dart';
import 'package:save_later/config/app_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // For sharing or opening url/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        if (value.first.type == SharedMediaType.text) {
          _handleIncomingSharedText(value.first.path);
        }
        ReceiveSharingIntent.instance.reset();
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening url/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        if (value.first.type == SharedMediaType.text) {
          _handleIncomingSharedText(value.first.path);
        }
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  static const _appControlChannel = MethodChannel('app.savelater/app_control');

  Future<void> _returnToPreviousApp() async {
    try {
      await _appControlChannel.invokeMethod('returnToPreviousApp');
    } catch (_) {
      try {
        await SystemNavigator.pop();
      } catch (_) {}
    }
  }

  void _handleIncomingSharedText(String text) async {
    final extractedUrl = UrlHelper.extractUrl(text) ?? text.trim();
    if (!UrlHelper.isValidUrl(extractedUrl)) {
      showNoUrlDialog(context);
      return;
    }

    _urlFocusNode.unfocus(disposition: UnfocusDisposition.scope);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

    final result = await ShareSaveModal.show(
      context: context,
      url: extractedUrl,
    );

    if (result != null && mounted) {
      await SaveSuccessModal.show(
        context: context,
        targetHeight: result.modalHeight,
      );

      if (mounted) {
        await _returnToPreviousApp();
      }
    } else if (mounted) {
      await _returnToPreviousApp();
    }

  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _quickSave() async {
    final rawText = _urlController.text.trim();
    if (rawText.isEmpty) {
      showNoUrlDialog(context);
      return;
    }
    if (rawText == 'seed' || rawText == 'seed15') {
      _urlController.clear();
      FocusScope.of(context).unfocus();
      final repo = ref.read(repositoryProvider);
      final sampleItems = [
        ('Flutter Official Docs', 'https://docs.flutter.dev', 'docs.flutter.dev', 'https://storage.googleapis.com/cms-storage-bucket/70760bf1e882184bb105.png'),
        ('Dart Language Guide', 'https://dart.dev/guides', 'dart.dev', 'https://dart.dev/assets/shared/dart-logo-for-shares.png'),
        ('GitHub Trending Repos', 'https://github.com/trending', 'github.com', 'https://github.githubassets.com/images/modules/open_graph/github-logo.png'),
        ('Hacker News', 'https://news.ycombinator.com', 'news.ycombinator.com', null),
        ('Smashing Magazine Articles', 'https://www.smashingmagazine.com', 'smashingmagazine.com', 'https://www.smashingmagazine.com/images/smashing-cat/smashing-cat-standard.png'),
        ('CSS Tricks - Layouts', 'https://css-tricks.com', 'css-tricks.com', 'https://css-tricks.com/apple-touch-icon.png'),
        ('Dev.to Community Posts', 'https://dev.to', 'dev.to', 'https://dev-to-uploads.s3.amazonaws.com/uploads/logos/resized_logo_UQww2soKuUsjaOGNB38o.png'),
        ('Medium Technology Feed', 'https://medium.com/topic/technology', 'medium.com', null),
        ('Product Hunt Daily', 'https://www.producthunt.com', 'producthunt.com', 'https://ph-static.imgix.net/ph-logo-orange-circle.png'),
        ('TechCrunch News', 'https://techcrunch.com', 'techcrunch.com', 'https://techcrunch.com/wp-content/uploads/2015/02/cropped-cropped-tc-logo.png'),
        ('The Verge Tech Reviews', 'https://www.theverge.com/tech', 'theverge.com', 'https://cdn.vox-cdn.com/uploads/chorus_asset/file/7395367/the-verge-small.0.png'),
        ('Wired Latest Stories', 'https://www.wired.com', 'wired.com', null),
        ('Ars Technica Science', 'https://arstechnica.com', 'arstechnica.com', null),
        ('Lobsters Tech Discussions', 'https://lobste.rs', 'lobste.rs', null),
        ('Dribbble Design Showcase', 'https://dribbble.com', 'dribbble.com', 'https://cdn.dribbble.com/assets/dribbble-ball-icon-eab99088334a84e8e4e758784d1668e9.png'),
      ];
      final isar = await repo.db;
      await isar.writeTxn(() async {
        for (int i = 0; i < sampleItems.length; i++) {
          final item = sampleItems[i];
          final b = Bookmark()
            ..title = item.$1
            ..url = item.$2
            ..sourceDomain = item.$3
            ..imageUrl = item.$4
            ..description = 'Saved reference item for ${item.$1}'
            ..createdAt = DateTime.now().subtract(Duration(minutes: (sampleItems.length - i) * 15))
            ..isRead = i % 3 == 0;
          await isar.bookmarks.put(b);
        }
      });
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      if (mounted) {
        _pushRoute('/unsorted');
      }
      return;
    }
    final url = UrlHelper.extractUrl(rawText) ?? rawText;
    if (!UrlHelper.isValidUrl(url)) {
      showNoUrlDialog(context);
      return;
    }
    _urlController.clear();
    FocusScope.of(context).unfocus();
    await ref.read(bookmarkNotifierProvider.notifier).quickSave(url);
    if (mounted) {
      _pushRoute('/unsorted');
    }
  }

  void _showAddCollectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CollectionEditorModal(),
    );
  }

  void _pushRoute(String route, {Object? extra}) {
    // Home stays mounted below pushed routes. Clear the URL field focus before
    // leaving so it is not restored (and does not reopen the keyboard) when
    // the route is popped.
    _urlFocusNode.unfocus(disposition: UnfocusDisposition.scope);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    context.push(route, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(bookmarkNotifierProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorSavingLink)),
          );
        }
      }
    });

    final collectionsAsync = ref.watch(collectionsProvider);
    final isSaving = ref.watch(bookmarkNotifierProvider).isLoading;
    final effectiveWidth = MediaQuery.sizeOf(context)
        .width
        .clamp(0.0, AppDimensions.maxContentWidth);
    final titleFontSize = MediaQuery.textScalerOf(context).scale(
      (effectiveWidth * 0.1).clamp(32.0, 44.0),
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: AppDimensions.maxContentWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const maxCrossAxisExtent =
                    AppDimensions.gridMaxCrossAxisExtent;
                const crossAxisSpacing = AppDimensions.gridSpacingMd;
                const desiredCardHeight =
                    AppDimensions.gridFolderCardHeight;
                final gridWidth = constraints.maxWidth -
                    (AppDimensions.paddingLg * 2);
                final columnCount = (gridWidth /
                        (maxCrossAxisExtent + crossAxisSpacing))
                    .ceil()
                    .clamp(1, 10)
                    .toInt();
                final itemWidth = (gridWidth -
                        (columnCount - 1) * crossAxisSpacing) /
                    columnCount;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pinned Top Action Bar
                    Container(
                      color: AppTheme.background,
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.paddingLg,
                        AppDimensions.paddingLg,
                        AppDimensions.paddingLg,
                        AppDimensions.paddingSm,
                      ),
                      child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: NeoButton(
                      onPressed: () => _pushRoute('/settings'),
                      padding: EdgeInsets.zero,
                      color: AppTheme.cardColor,
                      borderRadius: AppDimensions.radiusMd,
                      borderWidth: AppDimensions.borderWidthMd,
                      child: const Icon(Icons.settings_outlined,
                          size: AppDimensions.iconSizeMd),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: NeoButton(
                          onPressed: _showAddCollectionModal,
                          padding: EdgeInsets.zero,
                          color: AppTheme.cardColor,
                          borderRadius: AppDimensions.radiusMd,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.create_new_folder_outlined,
                              size: AppDimensions.iconSizeMd),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSm),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: NeoButton(
                          onPressed: () => _pushRoute('/search'),
                          padding: EdgeInsets.zero,
                          color: AppTheme.cardColor,
                          borderRadius: AppDimensions.radiusMd,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.search,
                              size: AppDimensions.iconSizeMd),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: CustomScrollView(
                clipBehavior: Clip.hardEdge,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppDimensions.paddingXl),

                          // Title
              Text(
                l10n.saveNowFindAnytime,
                textScaler: TextScaler.noScaling,
                style: GoogleFonts.gabarito(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXxl),

              // Quick Save Bar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.4,
                      child: NeoBox(
                        padding: const EdgeInsets.only(
                          left: AppDimensions.paddingMd,
                          right: AppDimensions.paddingXs,
                        ),
                        borderRadius: AppDimensions.radiusMd,
                        child: TextField(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          style: GoogleFonts.gabarito(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.border,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.pasteLinkHint,
                            hintStyle: GoogleFonts.gabarito(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.black38,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              icon: const Icon(Icons.paste_outlined,
                                  color: AppTheme.border),
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                final data = await Clipboard.getData(
                                    Clipboard.kTextPlain);
                                if (data != null &&
                                    data.text != null &&
                                    data.text!.isNotEmpty) {
                                  _urlController.text = data.text!;
                                }
                              },
                            ),
                          ),
                          onSubmitted: (_) => _quickSave(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMd),
                  SizedBox(
                    height: 50.4,
                    width: 50.4,
                    child: NeoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: AppDimensions.radiusMd,
                      color: AppTheme.accent, // Yellow button
                      onPressed: () {
                        _quickSave();
                    
                      },
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: AppTheme.border, strokeWidth: 3))
                          : const Icon(Icons.add,
                              color: AppTheme.border,
                              size: AppDimensions.iconSizeLg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingLg),

              // Collections Header
              Text(
                l10n.myCollections,
                style: GoogleFonts.gabarito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
                        ],
                      ),
                    ),
                  ),

                  // Collections Grid
                  ...collectionsAsync.when(
                    data: (collections) {
                      return [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            AppDimensions.paddingLg,
                            0,
                            AppDimensions.paddingLg,
                            bottomInset + AppDimensions.paddingLg,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxCrossAxisExtent,
                              crossAxisSpacing: crossAxisSpacing,
                              mainAxisSpacing:
                                  AppDimensions.gridSpacingLg,
                              childAspectRatio:
                                  itemWidth / desiredCardHeight,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == 0) {
                                  return Consumer(builder: (context, ref, _) {
                                    final countAsync =
                                        ref.watch(unsortedBookmarksProvider);
                                    final bookmarks =
                                        countAsync.valueOrNull ?? [];
                                    final count = bookmarks.length;
                                    final newCount = bookmarks
                                        .where((b) => !b.isRead)
                                        .length;
                                    final hasNew = newCount > 0;
                                    return FolderBox(
                                      forceBold: true,
                                      title: l10n.unsorted,
                                      itemCountText:
                                          l10n.itemsCount(count),
                                      folderColor: Colors.grey.shade400,
                                      onTap: () {
                                        _pushRoute('/unsorted');
                                      },
                                      hasNewItems: hasNew,
                                      newCount: newCount,
                                    );
                                  });
                                }

                                final col = collections[index - 1];
                                return Consumer(builder: (context, ref, _) {
                                  final countAsync = ref.watch(
                                      collectionBookmarksProvider(col.id));
                                  final bookmarks =
                                      countAsync.valueOrNull ?? [];
                                  final count = bookmarks.length;
                                  final newCount = bookmarks
                                      .where((b) => !b.isRead)
                                      .length;
                                  final hasNew = newCount > 0;
                                  return CollectionGridItem(
                                    collection: col,
                                    itemCount: count,
                                    hasNewItems: hasNew,
                                    newCount: newCount,
                                    onTap: () => _pushRoute(
                                        '/collection/${col.id}',
                                        extra: col),
                                  );
                                });
                              },
                              childCount: collections.length + 1,
                            ),
                          ),
                        ),
                      ];
                    },
                    loading: () => [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                    error: (e, st) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                            child:
                                Text(l10n.errorWithMessage(e.toString()))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
),
),
);
}
}
