import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/bookmark.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../../utils/url_launcher.dart';
import 'package:save_later/config/app_constants.dart';
import 'dart:async';


class BookmarkDetailScreen extends ConsumerStatefulWidget {
  final Bookmark bookmark;

  const BookmarkDetailScreen({super.key, required this.bookmark});

  @override
  ConsumerState<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  late Bookmark bookmark;
  late TextEditingController _notesController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false;

  @override
  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _notesController = TextEditingController(text: bookmark.description ?? '');
    _titleController = TextEditingController(text: bookmark.title ?? bookmark.url);
  }



  Timer? _saveTimer;

  void _scheduleSaveNotes(String val) {
    // Cancel any existing timer to debounce rapid keystrokes
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      // Save notes after user stops typing for 500ms
      bookmark.description = val;
      await ref.read(bookmarkNotifierProvider.notifier).updateNotes(bookmark, val);
    });
  }

  // Ensure any pending changes are saved when the screen is disposed
  @override
  void dispose() {
    _saveTimer?.cancel();
    // Save latest notes if needed
    _saveNotes(_notesController.text);
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Immediate save for editing complete (e.g., when user hits Done)
  void _saveNotes(String val) async {
    // Cancel debounce timer since we're saving immediately
    _saveTimer?.cancel();
    bookmark.description = val;
    await ref.read(bookmarkNotifierProvider.notifier).updateNotes(bookmark, val);
  }

  void _showAddTagModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.border, width: 3)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.addTag,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.paddingLg),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.tagNameHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    _addTag(val);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTag(String tag) async {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isEmpty) return;

    await ref.read(bookmarkNotifierProvider.notifier).addTag(bookmark, cleanTag);
    setState(() {});
  }

  void _removeTag(String tag) async {
    await ref.read(bookmarkNotifierProvider.notifier).removeTag(bookmark, tag);
    setState(() {});
  }

  void _showMoveModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, child) {
          final collectionsAsync = ref.watch(collectionsProvider);
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: AppTheme.border, width: 3)),
            ),
            padding: EdgeInsets.all(24),
            child: collectionsAsync.when(
              data: (collections) {
                if (collections.isEmpty) return Text(AppLocalizations.of(context)!.noCollectionsCreated);
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (ctx, index) {
                    final col = collections[index];
                    return ListTile(
                      leading: Icon(IconData(col.iconCodePoint, fontFamily: col.iconFontFamily), color: col.color),
                      title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () async {
                                    HapticFeedback.lightImpact();
                        bookmark.collection.value = col;
                        await ref.read(repositoryProvider).updateBookmark(bookmark);
                        bookmark.collection.save();
                        ref.invalidate(bookmarksProvider);
                        ref.invalidate(collectionBookmarksProvider(col.id));
                        if (!mounted || !ctx.mounted) return;
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.movedToCollection(col.name))));
                      },
                    );
                  }
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
            )
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black, // Matches image overflow areas
      body: Stack(
        children: [
          // 1. Background Image
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: bookmark.imageUrl != null
                ? Image.network(
                    bookmark.imageUrl!.startsWith('//') ? 'https:${bookmark.imageUrl!}' : bookmark.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(
                      color: Colors.grey.shade900,
                      child: const Center(child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey)),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: const Center(child: Icon(Icons.link, size: 64, color: Colors.grey)),
                  ),
          ),

          // 2. Main Content Card
          Positioned.fill(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border(
                        top: BorderSide(color: AppTheme.border, width: 3),
                        left: BorderSide(color: AppTheme.border, width: 3),
                        right: BorderSide(color: AppTheme.border, width: 3),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Source Domain
                        Row(
                          children: [
                            const Icon(Icons.public, size: 18),
                            const SizedBox(width: AppDimensions.paddingSm),
                            Text(
                              bookmark.sourceDomain ?? l10n.unknownSource,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Title & Edit Button
                        if (_isEditingTitle)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  border: Border.all(color: const Color(0xFFFFD166), width: 3),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                    color: Colors.black,
                                  ),
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                    HapticFeedback.lightImpact();
                                      setState(() {
                                        _isEditingTitle = false;
                                        _titleController.text = bookmark.title ?? bookmark.url;
                                      });
                                    },
                                    child: NeoBox(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      borderRadius: AppDimensions.radiusMd,
                                      borderWidth: 3,
                                      color: Colors.white,
                                      child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.paddingMd),
                                  GestureDetector(
                                    onTap: () async {
                                    HapticFeedback.lightImpact();
                                      final newTitle = _titleController.text.trim();
                                      if (newTitle.isNotEmpty) {
                                        bookmark.title = newTitle;
                                        await ref.read(repositoryProvider).updateBookmark(bookmark);
                                        ref.invalidate(bookmarksProvider);
                                        if (bookmark.collection.value != null) {
                                            ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
                                        }
                                        ref.invalidate(unsortedBookmarksProvider);
                                        setState(() {
                                          _isEditingTitle = false;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEEEE),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                        border: Border.all(color: Colors.grey.shade600, width: 3),
                                      ),
                                      child: Text(l10n.save, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey.shade600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  bookmark.title ?? bookmark.url,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingLg),
                              GestureDetector(
                                onTap: () {
                                    HapticFeedback.lightImpact();
                                  setState(() {
                                    _isEditingTitle = true;
                                  });
                                },
                                child: NeoBox(
                                  padding: EdgeInsets.all(AppDimensions.paddingSm),
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: const Icon(Icons.edit_outlined, size: AppDimensions.iconSizeMd),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Collection & Date
                        Row(
                          children: [
                            if (bookmark.collection.value != null)
                              Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: NeoBox(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  borderRadius: AppDimensions.radiusSm,
                                  borderWidth: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        IconData(bookmark.collection.value!.iconCodePoint, fontFamily: bookmark.collection.value!.iconFontFamily),
                                        size: 16,
                                        color: bookmark.collection.value!.color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        bookmark.collection.value!.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Text(
                              DateFormat('dd MMM yyyy, h:mm a').format(bookmark.createdAt),
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),

                        // Open Link Button
                        GestureDetector(
                          onTap: () { HapticFeedback.lightImpact(); openUrl(bookmark.url); },
                          child: NeoBox(
                            color: const Color(0xFFFFD166), // Yellow
                            padding: EdgeInsets.all(AppDimensions.paddingLg),
                            borderRadius: AppDimensions.radiusXl,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.openLink,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        bookmark.sourceDomain ?? bookmark.url,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(AppDimensions.paddingSm),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.border,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_outward, color: Colors.white, size: AppDimensions.iconSizeMd),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),

                        // Actions Row
                        NeoBox(
                          padding: EdgeInsets.all(0),
                          borderRadius: AppDimensions.radiusXl,
                          child: Row(
                            children: [
                              _buildActionItem(Icons.share_outlined, l10n.share, () {
                                Share.share(widget.bookmark.url);
                              }),
                              _buildDivider(),
                              _buildActionItem(Icons.folder_outlined, l10n.move, _showMoveModal),
                              _buildDivider(),
                              _buildActionItem(Icons.refresh, l10n.refresh, _showRefreshDialog),
                              _buildDivider(),
                              _buildActionItem(Icons.delete_outline, l10n.delete, () async {
                                await ref.read(repositoryProvider).deleteBookmark(bookmark.id);
                                ref.invalidate(bookmarksProvider);
                                if (bookmark.collection.value != null) ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
                                if (context.mounted) {
                                  context.pop();
                                }
                              }, isDestructive: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Description
                        Text(l10n.descriptionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Text(
                          bookmark.description ?? l10n.noDescriptionProvided,
                          style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Tags
                        Text(l10n.tagsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ...bookmark.tags.map((tag) => GestureDetector(
                              onTap: () { HapticFeedback.lightImpact(); _removeTag(tag); }, // Or edit
                              child: NeoBox(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: AppDimensions.radiusSm,
                                borderWidth: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔖', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            )),
                            GestureDetector(
                              onTap: () { HapticFeedback.lightImpact(); _showAddTagModal(); },
                              child: NeoBox(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                borderRadius: AppDimensions.radiusSm,
                                borderWidth: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('👑', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(l10n.add, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Notes
                        Text(l10n.notesLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        NeoBox(
                          color: const Color(0xFFFFF7E0), // Pale yellow
                          borderRadius: AppDimensions.radiusMd,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: TextField(
                            controller: _notesController,
                            maxLines: null,
                            onChanged: (val) => _scheduleSaveNotes(val),
                            onEditingComplete: () {
                              _saveNotes(_notesController.text);
                              if (mounted) setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: l10n.tapToAddNotesHint,
                              hintStyle: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingXxxl), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Top Floating App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); context.pop(); },
                      child: NeoBox(
                        padding: EdgeInsets.all(AppDimensions.paddingSm),
                        color: AppTheme.background,
                        borderRadius: AppDimensions.radiusMd,
                        borderWidth: AppDimensions.borderWidthMd,
                        child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeMd),
                      ),
                    ),
                    NeoBox(
                      padding: EdgeInsets.all(AppDimensions.paddingSm),
                      color: AppTheme.background,
                      borderRadius: AppDimensions.radiusMd,
                      borderWidth: AppDimensions.borderWidthMd,
                      child: const Icon(Icons.auto_fix_off_outlined, size: AppDimensions.iconSizeMd),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performRefresh() {
    // Show loading overlay
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'RefreshOverlay',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack))),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (ctx, animation, secondaryAnimation) => _RefreshOverlay(
        onRefresh: () async {
          await ref.read(bookmarkNotifierProvider.notifier).refreshMetadata(bookmark);
          setState(() {});
        },
      ),
    );
  }

  void _showRefreshDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RefreshDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(Tween<double>(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack))),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (ctx, animation, secondaryAnimation) => Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            border: Border.all(color: AppTheme.border, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppTheme.border,
                offset: Offset(AppDimensions.shadowOffsetMd, AppDimensions.shadowOffsetMd),
                blurRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.refreshLinkMetadata,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingLg),
                Text(
                  AppLocalizations.of(context)!.refreshMetadataDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); Navigator.pop(ctx); },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(color: AppTheme.border, width: AppDimensions.borderWidthMd),
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMd),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                                    HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          _performRefresh();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3366),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(color: AppTheme.border, width: AppDimensions.borderWidthMd),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.border,
                                offset: Offset(AppDimensions.shadowOffsetSm, AppDimensions.shadowOffsetSm),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.refresh,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? const Color(0xFFC0392B) : AppTheme.border;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          color: Colors.transparent,
          child: Column(
            children: [
              Icon(icon, color: color, size: AppDimensions.iconSizeMd),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 2,
      color: AppTheme.border,
    );
  }
}




class _RefreshOverlay extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const _RefreshOverlay({required this.onRefresh});

  @override
  State<_RefreshOverlay> createState() => _RefreshOverlayState();
}

class _RefreshOverlayState extends State<_RefreshOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  bool _done = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: AppDurations.animationSlow,
    )..repeat();
    _doRefresh();
  }

  Future<void> _doRefresh() async {
    try {
      await widget.onRefresh();
      if (!mounted) return;
      setState(() => _done = true);
      _spinController.stop();
      await Future.delayed(AppDurations.delayLong);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _done = true;
      });
      _spinController.stop();
      await Future.delayed(AppDurations.messageDuration);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 48),
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          border: Border.all(color: AppTheme.border, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.border,
              offset: Offset(AppDimensions.shadowOffsetMd, AppDimensions.shadowOffsetMd),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.animationNormal,
                child: _done
                    ? Container(
                        key: const ValueKey('done'),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _error
                              ? const Color(0xFFFF3366)
                              : const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border, width: AppDimensions.borderWidthMd),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.border,
                              offset: Offset(AppDimensions.shadowOffsetSm, AppDimensions.shadowOffsetSm),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _error ? Icons.close : Icons.check,
                          color: Colors.white,
                          size: AppDimensions.iconSizeXl,
                        ),
                      )
                    : RotationTransition(
                        key: const ValueKey('loading'),
                        turns: _spinController,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border, width: AppDimensions.borderWidthMd),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.border,
                                offset: Offset(AppDimensions.shadowOffsetSm, AppDimensions.shadowOffsetSm),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.refresh, size: AppDimensions.iconSizeXl, color: AppTheme.border),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                _done
                    ? (_error ? AppLocalizations.of(context)!.somethingWentWrong : AppLocalizations.of(context)!.allDone)
                    : AppLocalizations.of(context)!.refreshing,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                _done
                    ? (_error
                        ? AppLocalizations.of(context)!.couldNotFetchMetadata
                        : AppLocalizations.of(context)!.metadataUpdatedSuccessfully)
                    : AppLocalizations.of(context)!.fetchingLatestMetadata,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
