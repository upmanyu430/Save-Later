import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../providers/providers.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/no_url_dialog.dart';
import '../widgets/folder_box.dart';
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
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    
    // For sharing or opening url/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
         final text = value.first.path;
         _urlController.text = text;
         _quickSave();
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening url/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.type == SharedMediaType.text) {
         final text = value.first.path;
         _urlController.text = text;
         _quickSave();
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _quickSave() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      showNoUrlDialog(context);
      return;
    }
    ref.read(bookmarkNotifierProvider.notifier).quickSave(url);
    _urlController.clear();
    FocusScope.of(context).unfocus();
  }

  void _showAddCollectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CollectionEditorModal(),
    );
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.linkSavedMessage)),
          );
        }
      }
    });

    final collectionsAsync = ref.watch(collectionsProvider);
    final isSaving = ref.watch(bookmarkNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl, vertical: AppDimensions.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: NeoBox(
                      padding: const EdgeInsets.all(AppDimensions.paddingSm),
                      borderRadius: AppDimensions.radiusSm,
                      borderWidth: AppDimensions.borderWidthMd,
                      child: const Icon(Icons.settings_outlined, size: AppDimensions.iconSizeLg),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showAddCollectionModal,
                        child: NeoBox(
                          padding: const EdgeInsets.all(AppDimensions.paddingSm),
                          borderRadius: AppDimensions.radiusSm,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.create_new_folder_outlined, size: AppDimensions.iconSizeLg),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingSm),
                      GestureDetector(
                        onTap: () => context.push('/search'),
                        child: NeoBox(
                          padding: const EdgeInsets.all(AppDimensions.paddingSm),
                          borderRadius: AppDimensions.radiusSm,
                          borderWidth: AppDimensions.borderWidthMd,
                          child: const Icon(Icons.search, size: AppDimensions.iconSizeLg),
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
                style: const TextStyle(
                  fontFamily: 'Quilon',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXxl),

              // Quick Save Bar
              Row(
                children: [
                  Expanded(
                    child: NeoBox(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLg, vertical: 4.0),
                      borderRadius: AppDimensions.radiusMd,
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: l10n.pasteLinkHint,
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_outlined, color: AppTheme.border),
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data != null && data.text != null && data.text!.isNotEmpty) {
                                _urlController.text = data.text!;
                              }
                            },
                          ),
                        ),
                        onSubmitted: (_) => _quickSave(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMd),
                  NeoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                    borderRadius: AppDimensions.radiusMd,
                    color: AppTheme.accent, // Yellow button
                    onPressed: _quickSave,
                    child: isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.border, strokeWidth: 3))
                      : const Icon(Icons.add, color: AppTheme.border, size: AppDimensions.iconSizeLg),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXxxl),

              // Collections Header
              Text(
                l10n.myCollections,
                style: const TextStyle(
                  fontFamily: 'Quilon',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXl),

              // Collections Grid
              Expanded(
                child: collectionsAsync.when(
                  data: (collections) {
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: AppDimensions.gridCrossAxisCount,
                        crossAxisSpacing: AppDimensions.gridSpacingMd,
                        mainAxisSpacing: AppDimensions.gridSpacingLg, // Extra space for the folder tabs
                        childAspectRatio: AppDimensions.gridAspectRatioFolder,
                      ),
                      itemCount: collections.length + 1, // +1 for Unsorted
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          
                          // Unsorted Folder
                          return Consumer(
                            builder: (context, ref, _) {
                              final countAsync = ref.watch(unsortedBookmarksProvider);
                              final bookmarks = countAsync.valueOrNull ?? [];
                              final count = bookmarks.length;
                              final hasNew = bookmarks.any((b) => !b.isRead);
                              return FolderBox(
                                title: l10n.unsorted,
                                itemCountText: l10n.itemsCount(count),
                                folderColor: Colors.grey.shade400,
                                onTap: () => context.push('/unsorted'),
                                hasNewItems: hasNew,
                              );
                            }
                          );
                        }
                        
                        final col = collections[index - 1];
                        return Consumer(
                          builder: (context, ref, _) {
                            final countAsync = ref.watch(collectionBookmarksProvider(col.id));
                            final bookmarks = countAsync.valueOrNull ?? [];
                            final count = bookmarks.length;
                            final hasNew = bookmarks.any((b) => !b.isRead);
                            return FolderBox(
                              title: col.name,
                              itemCountText: l10n.itemsCount(count),
                              folderColor: col.color,
                              icon: IconData(col.iconCodePoint, fontFamily: col.iconFontFamily),
                              onTap: () => context.push('/collection/${col.id}', extra: col),
                              hasNewItems: hasNew,
                            );
                          }
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(l10n.errorWithMessage(e.toString()))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}









