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
import '../../theme/app_theme.dart';
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
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _handleIncomingSharedText(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening url/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
        _handleIncomingSharedText(value.first.path);
      }
    });
  }

  void _handleIncomingSharedText(String text) {
    final extractedUrl = UrlHelper.extractUrl(text) ?? text.trim();
    _urlController.text = extractedUrl;
    _quickSave();
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXl,
                  vertical: AppDimensions.paddingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: NeoButton(
                      onPressed: () => _pushRoute('/settings'),
                      padding: EdgeInsets.zero,
                      color: AppTheme.cardColor,
                      borderRadius: AppDimensions.radiusSm,
                      borderWidth: AppDimensions.borderWidthMd,
                      child: const Icon(Icons.settings_outlined,
                          size: AppDimensions.iconSizeLg),
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
                          borderRadius: AppDimensions.radiusSm,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.create_new_folder_outlined,
                              size: AppDimensions.iconSizeLg),
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
                          borderRadius: AppDimensions.radiusSm,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.search,
                              size: AppDimensions.iconSizeLg),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXxl),

              // Title
              Text(
                l10n.saveNowFindAnytime,
                textScaler: TextScaler.noScaling,
                style: GoogleFonts.bricolageGrotesque(
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
                      height: 56.0,
                      child: NeoBox(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMd, vertical: 0.0),
                        borderRadius: AppDimensions.radiusMd,
                        child: TextField(
                          controller: _urlController,
                          focusNode: _urlFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: l10n.pasteLinkHint,
                            hintStyle: GoogleFonts.bricolageGrotesque(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black38,
                            ),
                            border: InputBorder.none,
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
                    height: 56.0,
                    width: 56.0,
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
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),

              // Collections Grid
              Expanded(
                child: collectionsAsync.when(
                  data: (collections) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const maxCrossAxisExtent =
                            AppDimensions.gridMaxCrossAxisExtent;
                        const crossAxisSpacing = AppDimensions.gridSpacingMd;
                        const desiredCardHeight =
                            AppDimensions.gridFolderCardHeight;
                        final columnCount = (constraints.maxWidth /
                                (maxCrossAxisExtent + crossAxisSpacing))
                            .ceil()
                            .clamp(1, 10)
                            .toInt();
                        final itemWidth = (constraints.maxWidth -
                                (columnCount - 1) * crossAxisSpacing) /
                            columnCount;

                        return GridView.builder(
                          padding: EdgeInsets.only(bottom: bottomInset),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxCrossAxisExtent,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: AppDimensions
                                .gridSpacingLg, // Extra space for the folder tabs
                            childAspectRatio: itemWidth / desiredCardHeight,
                          ),
                          itemCount: collections.length + 1, // +1 for Unsorted
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // Unsorted Folder
                              return Consumer(builder: (context, ref, _) {
                                final countAsync =
                                    ref.watch(unsortedBookmarksProvider);
                                final bookmarks = countAsync.valueOrNull ?? [];
                                final count = bookmarks.length;
                                final newCount = bookmarks.where((b) => !b.isRead).length;
                                final hasNew = newCount > 0;
                                return FolderBox(
                                  forceBold: true,
                                  title: l10n.unsorted,
                                  itemCountText: l10n.itemsCount(count),
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
                              final countAsync = ref
                                  .watch(collectionBookmarksProvider(col.id));
                              final bookmarks = countAsync.valueOrNull ?? [];
                              final count = bookmarks.length;
                              final newCount = bookmarks.where((b) => !b.isRead).length;
                              final hasNew = newCount > 0;
                              return CollectionGridItem(
                                collection: col,
                                itemCount: count,
                                hasNewItems: hasNew,
                                newCount: newCount,
                                onTap: () => _pushRoute('/collection/${col.id}',
                                    extra: col),
                              );
                            });
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) =>
                      Center(child: Text(l10n.errorWithMessage(e.toString()))),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
