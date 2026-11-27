import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
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
import '../widgets/neo_button.dart';
import '../widgets/neo_pressable.dart';
import '../widgets/move_to_collection_modal.dart';
import '../widgets/app_modal_sheet.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/pin_icon.dart';
import '../widgets/favicon_image.dart';
import '../widgets/bookmark_image.dart';
import '../../utils/url_launcher.dart';
import '../../utils/tag_helper.dart';
import 'package:save_later/config/app_constants.dart';
import 'dart:async';


class BookmarkDetailScreen extends ConsumerStatefulWidget {
  final Bookmark? bookmark;
  final int? bookmarkId;

  const BookmarkDetailScreen({
    super.key,
    this.bookmark,
    this.bookmarkId,
  });

  @override
  ConsumerState<BookmarkDetailScreen> createState() => _BookmarkDetailScreenState();
}

class _BookmarkDetailScreenState extends ConsumerState<BookmarkDetailScreen> {
  Bookmark? _loadedBookmark;
  Bookmark get bookmark => _loadedBookmark!;
  late TextEditingController _notesController;
  late TextEditingController _titleController;
  bool _isEditingTitle = false;
  bool _isEditingNotes = false;
  bool _notesEdited = false;
  String _lastSavedNotes = '';
  bool _isTopBarVisible = true;
  bool _isDescriptionExpanded = false;
  bool _isLoading = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _titleController = TextEditingController();

    if (widget.bookmark != null) {
      _initBookmark(widget.bookmark!);
    } else if (widget.bookmarkId != null && widget.bookmarkId! > 0) {
      _isLoading = true;
      Future.microtask(() => _fetchBookmark(widget.bookmarkId!));
    } else {
      _notFound = true;
    }
  }

  void _initBookmark(Bookmark b) {
    _loadedBookmark = b;
    _notesController.text = b.notes;
    _lastSavedNotes = b.notes;
    _titleController.text = b.title ?? b.url;
    if (b.collection.isAttached && !b.collection.isLoaded) {
      b.collection.load().then((_) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route?.animation != null && route!.animation!.isAnimating) {
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              route.animation!.removeStatusListener(listener);
              if (mounted) setState(() {});
            }
          }
          route.animation!.addStatusListener(listener);
        } else {
          setState(() {});
        }
      });
    }
  }

  Future<void> _fetchBookmark(int id) async {
    try {
      final repo = ref.read(repositoryProvider);
      final b = await repo.getBookmark(id);
      if (!mounted) return;
      if (b != null) {
        setState(() {
          _initBookmark(b);
          _isLoading = false;
        });
      } else {
        setState(() {
          _notFound = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notFound = true;
          _isLoading = false;
        });
      }
    }
  }



  Timer? _saveTimer;

  void _scheduleSaveNotes(String val) {
    // Cancel any existing timer to debounce rapid keystrokes
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      // Save notes after user stops typing for 500ms
      bookmark.notes = val;
      await ref.read(bookmarkNotifierProvider.notifier).updateNotes(bookmark, val);
      _lastSavedNotes = val;
    });
  }

  // Ensure any pending changes are saved when the screen is disposed
  @override
  void dispose() {
    if (_loadedBookmark != null && _notesEdited && _notesController.text != _lastSavedNotes) {
      unawaited(_saveNotes(_notesController.text));
    } else {
      _saveTimer?.cancel();
    }
    _notesController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Immediate save for editing complete (e.g., when user hits Done)
  Future<void> _saveNotes(String val) async {
    // Cancel debounce timer since we're saving immediately
    _saveTimer?.cancel();
    bookmark.notes = val;
    await ref.read(bookmarkNotifierProvider.notifier).updateNotes(bookmark, val);
    _lastSavedNotes = val;
  }

  void _showAddTagModal() {
    showAppModalSheet<void>(
      context: context,
      builder: (ctx) => _AddTagSheet(
        currentTags: bookmark.tags,
        onSubmit: (tag) => _addTag(tag),
      ),
    );
  }

  void _addTag(String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty) return;

    await ref.read(bookmarkNotifierProvider.notifier).addTag(bookmark, cleanTag);
    setState(() {});
  }

  Future<void> _removeTag(String tag) async {
    await ref.read(bookmarkNotifierProvider.notifier).removeTag(bookmark, tag);
    setState(() {});
  }

  void _confirmRemoveTag(String tag) {
    HapticFeedback.lightImpact();
    showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete tag',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.82, end: 1.0).chain(
              CurveTween(curve: const Cubic(0.23, 1.0, 0.32, 1.0)),
            ),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final l10n = AppLocalizations.of(context)!;
        final colors = dialogContext.appColors;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(dialogContext, false),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppDimensions.maxDialogWidth),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    border: Border.all(color: colors.border, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        offset: const Offset(2.8, 2.8),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Delete tag?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: colors.textPrimary),
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Text(
                          'Remove "$tag" from this bookmark?',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: colors.textSecondary),
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                color: colors.card,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                borderRadius: AppDimensions.radiusMd,
                                borderWidth: 2,
                                child: Text(
                                  l10n.cancel,
                                  style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingMd),
                            Expanded(
                              child: NeoButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext, true);
                                  await _removeTag(tag);
                                },
                                color: const Color(0xFFFF6B6B),
                                shadowColor: colors.shadow,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                borderRadius: AppDimensions.radiusMd,
                                borderWidth: 2,
                                child: Text(
                                  l10n.delete,
                                  style: TextStyle(fontWeight: FontWeight.w800, color: colors.onAccent),
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
            ),
          ),
        );
      },
    );
}

  void _showMoveModal() async {
    await MoveToCollectionModal.show(
      context: context,
      bookmark: bookmark,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_notFound || _loadedBookmark == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: colors.textMuted),
                  const SizedBox(height: AppDimensions.paddingMd),
                  Text(
                    'Bookmark not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  NeoButton(
                    onPressed: () => context.pop(),
                    color: colors.card,
                    child: Text('Go back', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final placeholderIconSize =
        (MediaQuery.sizeOf(context).width * 0.16).clamp(48.0, 80.0);
    final topInset = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            // 1. Background Image Box
            Positioned(
              top: topInset,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.34,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookmarkImage(
                    imageUrl: bookmark.imageUrl,
                    url: bookmark.url,
                    fallback: Container(
                      color: colors.surfaceSubtle,
                      child: Center(
                        child: Icon(
                          Icons.link,
                          size: placeholderIconSize,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),

                  // Lower Black Line on the bookmark background image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: AppDimensions.borderWidthLg,
                      color: colors.border,
                    ),
                  ),
                ],
              ),
            ),

          // 2. Main Content Card
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final pixels = notification.metrics.pixels;
                  if (pixels <= 20) {
                    if (!_isTopBarVisible) {
                      setState(() => _isTopBarVisible = true);
                    }
                  } else if (notification is ScrollUpdateNotification) {
                    final delta = notification.scrollDelta ?? 0;
                    if (delta > 2) {
                      // Scrolling down -> hide top buttons
                      if (_isTopBarVisible) {
                        setState(() => _isTopBarVisible = false);
                      }
                    }
                  } else if (notification is UserScrollNotification) {
                    if (notification.direction == ScrollDirection.reverse &&
                        pixels > 20) {
                      if (_isTopBarVisible) {
                        setState(() => _isTopBarVisible = false);
                      }
                    }
                  }
                  return false;
                },
                child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.29),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: const BorderRadius.all(Radius.circular(32)),
                          border: Border.fromBorderSide(
                            BorderSide(color: colors.border, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              offset: const Offset(2.8, 2.8),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Source Domain
                        Row(
                          children: [
                            FaviconImage(
                              domain: bookmark.sourceDomain,
                              url: bookmark.url,
                              size: 24.0,
                            ),
                            const SizedBox(width: AppDimensions.paddingSm),
                            Text(
                              bookmark.sourceDomain ?? l10n.unknownSource,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: colors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),

                        // Title & Edit Button
                        if (_isEditingTitle)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  border: Border.all(color: const Color(0xFFFFD166), width: 3),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: TextField(
                                  controller: _titleController,
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    letterSpacing: -0.5,
                                    color: colors.textPrimary,
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
                                  NeoButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingTitle = false;
                                        _titleController.text = bookmark.title ?? bookmark.url;
                                      });
                                    },
                                    color: colors.card,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      l10n.cancel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.paddingSm),
                                  NeoButton(
                                    onPressed: () async {
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
                                    color: const Color(0xFFFFD166),
                                    shadowColor: colors.shadow,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      l10n.save,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: colors.onAccent,
                                      ),
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
                                  style: TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingLg),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: NeoButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingTitle = true;
                                    });
                                  },
                                  color: colors.card,
                                  padding: EdgeInsets.zero,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: Icon(Icons.edit_outlined, size: AppDimensions.iconSizeMd, color: colors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppDimensions.paddingMd),

                        // Collection & Date
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12.0,
                          runSpacing: 8.0,
                          children: [
                            NeoBox(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              borderRadius: AppDimensions.radiusSm,
                              borderWidth: 2,
                              shadowOffset: 0,
                              color: colors.card,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: bookmark.collection.value?.color ?? const Color(0xFFE5E5E5),
                                      border: Border.all(color: colors.border, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bookmark.collection.value?.name ?? l10n.unsorted,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, h:mm a').format(bookmark.createdAt),
                              style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),

                        // Open Link Button
                        _OpenLinkButton(
                          url: bookmark.url,
                          onPressed: () async {
                            await openUrl(bookmark.url, context: context);
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),

                        // Actions Strip
                        Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: colors.shadow,
                                offset: const Offset(2.8, 2.8),
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(
                              color: colors.border,
                              width: AppDimensions.borderWidthMd,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildActionItem(
                                    Icons.share_outlined,
                                    l10n.share,
                                    () {
                                      Share.share(bookmark.url);
                                    },
                                    color: const Color(0xFF7B61FF),
                                  ),
                                  _buildSegmentDivider(),
                                  _buildActionItem(
                                    Icons.folder_outlined,
                                    l10n.move,
                                    _showMoveModal,
                                    color: const Color(0xFFFDD164),
                                  ),
                                  _buildSegmentDivider(),
                                  _buildActionItem(
                                    Icons.refresh,
                                    l10n.refresh,
                                    () async {
                                      final confirmed = await _showRefreshDialog();
                                      if (confirmed != true) return;

                                      ref.read(bookmarkNotifierProvider.notifier).refreshMetadata(bookmark);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    color: const Color(0xFF26D5A8),
                                  ),
                                  _buildSegmentDivider(),
                                  _buildActionItem(
                                    Icons.delete_outline,
                                    l10n.delete,
                                    () async {
                                      final confirmed = await DeleteConfirmationDialog.show(context: context);
                                      if (!confirmed) return;

                                      await ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(bookmark);
                                      if (context.mounted) {
                                        context.pop();
                                      }
                                    },
                                    color: const Color(0xFFEF476F),
                                    isDestructive: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Description
                        Text(l10n.descriptionLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: colors.textPrimary)),
                        const SizedBox(height: AppDimensions.paddingSm),
                        _buildDescription(l10n),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Tags
                        Text(l10n.tagsLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, color: colors.textPrimary)),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ...bookmark.tags.map((tag) => ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 44),
                                  child: Center(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onLongPress: () => _confirmRemoveTag(tag),
                                      child: NeoBox(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        borderRadius: AppDimensions.radiusSm,
                                        borderWidth: 2,
                                        child: Text(
                                          tag.isEmpty
                                              ? tag
                                              : '${tag[0].toUpperCase()}${tag.substring(1)}',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textPrimary),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                            _TagAddButton(
                              label: l10n.add,
                              onPressed: _showAddTagModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Notes
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 36),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                l10n.notesLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (_isEditingNotes)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NeoButton(
                                      onPressed: () {
                                        _saveTimer?.cancel();
                                        _notesController.text = _lastSavedNotes;
                                        bookmark.notes = _lastSavedNotes;
                                        setState(() {
                                          _notesEdited = false;
                                          _isEditingNotes = false;
                                        });
                                      },
                                      color: colors.card,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.cancel,
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colors.textPrimary),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimensions.paddingSm),
                                    NeoButton(
                                      onPressed: () {
                                        _saveTimer?.cancel();
                                        unawaited(_saveNotes(_notesController.text));
                                        setState(() {
                                          _notesEdited = false;
                                          _isEditingNotes = false;
                                        });
                                      },
                                      color: AppTheme.accent,
                                      shadowColor: colors.shadow,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.save,
                                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colors.onAccent),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        SizedBox(
                          height: 160,
                          child: GestureDetector(
                            onTap: () {
                              if (!_isEditingNotes) {
                                setState(() => _isEditingNotes = true);
                              }
                            },
                            child: NeoBox(
                              color: isDark ? const Color(0xFF2D281D) : const Color(0xFFFFF7E0),
                              borderRadius: AppDimensions.radiusMd,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: TextField(
                                controller: _notesController,
                                readOnly: !_isEditingNotes,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                                onTap: () {
                                  if (!_isEditingNotes) {
                                    setState(() => _isEditingNotes = true);
                                  }
                                },
                                onChanged: (val) {
                                  _notesEdited = true;
                                  _scheduleSaveNotes(val);
                                },
                                onEditingComplete: () {
                                  if (_notesEdited) _saveNotes(_notesController.text);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Tap here to save notes',
                                  hintStyle: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
            ),
          ),

          // 3. Top Floating App Bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              offset: _isTopBarVisible ? Offset.zero : const Offset(0, -1.3),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isTopBarVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isTopBarVisible,
                  child: SafeArea(
                    child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: NeoButton(
                                  onPressed: () => context.pop(),
                                  padding: EdgeInsets.zero,
                                  color: colors.card,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: Icon(Icons.arrow_back, size: AppDimensions.iconSizeMd, color: colors.textPrimary),
                                ),
                              ),
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: NeoButton(
                                  onPressed: () async {
                                    await ref.read(bookmarkNotifierProvider.notifier).togglePin(bookmark);
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  color: bookmark.isPinned ? const Color(0xFFFFD166) : colors.card,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: PinIcon(
                                    isPinned: bookmark.isPinned,
                                    size: AppDimensions.iconSizeMd,
                                    color: bookmark.isPinned ? colors.onAccent : colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ),
                  ),
              ),
            ),
          ),

          // 4. Top Status Bar & Black Divider Line
          if (topInset > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: topInset,
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border(
                      bottom: BorderSide(
                        color: colors.border,
                        width: AppDimensions.borderWidthLg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  Future<bool?> _showRefreshDialog() {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RefreshDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween<double>(begin: 0.85, end: 1.0).chain(
              CurveTween(curve: const Cubic(0.23, 1.0, 0.32, 1.0)),
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, animation, secondaryAnimation) {
        final colors = ctx.appColors;
        return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(ctx, false),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppDimensions.maxDialogWidth),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: colors.border, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow,
                      offset: const Offset(2.8, 2.8),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.refreshLinkMetadata,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.refreshMetadataDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: NeoButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              color: colors.card,
                              borderRadius: 12.0,
                              borderWidth: 2.5,
                              shadowOffset: 3.0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: NeoButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              color: const Color(0xFF26D5A8),
                              shadowColor: colors.shadow,
                              borderRadius: 12.0,
                              borderWidth: 2.5,
                              shadowOffset: 3.0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Text(
                                AppLocalizations.of(context)!.refresh,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: colors.onAccent,
                                  letterSpacing: 0.3,
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
          ),
        ),
      );
      },
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    final colors = context.appColors;
    final description = bookmark.description?.trim();
    final style = TextStyle(fontSize: 16, height: 1.5, color: colors.textSecondary);

    if (description == null || description.isEmpty) {
      return Text(
        l10n.noDescriptionProvided,
        style: style,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: description, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: 5,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: style,
              maxLines: _isDescriptionExpanded ? null : 5,
              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isDescriptionExpanded = !_isDescriptionExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    _isDescriptionExpanded ? l10n.showLess : l10n.showMore,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSegmentDivider() {
    return Container(
      width: AppDimensions.borderWidthMd,
      color: context.appColors.border,
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
    bool isDestructive = false,
  }) {
    return ActionStripButton(
      icon: icon,
      label: label,
      onTap: onTap,
      color: color,
      isDestructive: isDestructive,
    );
  }
}

class ActionStripButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isDestructive;

  const ActionStripButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFFDD164),
    this.isDestructive = false,
  });

  @override
  State<ActionStripButton> createState() => _ActionStripButtonState();
}

class _ActionStripButtonState extends State<ActionStripButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  bool _isPointerPressed = false;
  bool _handledByPointer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _isPointerPressed = true;
    _handledByPointer = true;
    _pointerDownPosition = event.position;
    _pointerDownTime = DateTime.now();
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerPressed) return;
    if (_pointerDownPosition != null) {
      final delta = (event.position - _pointerDownPosition!).distance;
      if (delta > 14.0) {
        _isPointerPressed = false;
        _controller.reverse();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isPointerPressed) return;
    _isPointerPressed = false;

    final elapsed = DateTime.now().difference(_pointerDownTime ?? DateTime.now());
    final remainingHold = const Duration(milliseconds: 70) - elapsed;

    if (remainingHold > Duration.zero) {
      Future.delayed(remainingHold, () {
        if (!mounted) return;
        _controller.reverse().whenComplete(() {
          if (mounted) {
            _handledByPointer = false;
            widget.onTap();
          }
        });
      });
    } else {
      _controller.reverse().whenComplete(() {
        if (mounted) {
          _handledByPointer = false;
          widget.onTap();
        }
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isPointerPressed = false;
    _handledByPointer = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final idleFgColor = widget.isDestructive
        ? (context.isDarkMode ? colors.danger : const Color(0xFFC0392B))
        : colors.textPrimary;
    const activeFgColor = Colors.white;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: true,
        label: widget.label,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_handledByPointer) {
                _controller.forward().whenComplete(() {
                  if (!mounted) return;
                  _controller.reverse().whenComplete(() {
                    if (mounted) {
                      widget.onTap();
                    }
                  });
                });
              }
            },
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final t = _animation.value;
                final backgroundColor = Color.lerp(colors.card, widget.color, t)!;
                final fgColor = Color.lerp(idleFgColor, activeFgColor, t)!;
                final scale = 1.0 - (t * 0.04);
                final offsetX = t * 1.5;
                final offsetY = t * 3.0;
                final topRecess = t * 3.0;
                final leftRecess = t * 2.0;

                return Container(
                  color: backgroundColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Top recess shadow simulating mechanical button depression
                      if (topRecess > 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: topRecess,
                          child: ColoredBox(color: colors.border),
                        ),
                      // Left recess shadow simulating mechanical button depression
                      if (leftRecess > 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          bottom: 0,
                          width: leftRecess,
                          child: ColoredBox(color: colors.border),
                        ),
                      // Button contents (Icon and Label)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
                          child: Transform.translate(
                            offset: Offset(offsetX, offsetY),
                            child: Transform.scale(
                              scale: scale,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(widget.icon, color: fgColor, size: 22),
                                  const SizedBox(height: 5),
                                  Text(
                                    widget.label,
                                    style: GoogleFonts.gabarito(
                                      color: fgColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}




class _OpenLinkButton extends StatefulWidget {
  final String url;
  final VoidCallback onPressed;

  const _OpenLinkButton({
    required this.url,
    required this.onPressed,
  });

  @override
  State<_OpenLinkButton> createState() => _OpenLinkButtonState();
}

class _OpenLinkButtonState extends State<_OpenLinkButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  Offset? _pointerDownPosition;
  DateTime? _pointerDownTime;
  bool _isPointerPressed = false;
  bool _handledByPointer = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 110),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: const Cubic(0.23, 1.0, 0.32, 1.0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _isPointerPressed = true;
    _handledByPointer = true;
    _pointerDownPosition = event.position;
    _pointerDownTime = DateTime.now();
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isPointerPressed) return;
    if (_pointerDownPosition != null) {
      final delta = (event.position - _pointerDownPosition!).distance;
      if (delta > 14.0) {
        _isPointerPressed = false;
        _handledByPointer = false;
        _controller.reverse();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isPointerPressed) return;
    _isPointerPressed = false;

    final elapsed = DateTime.now().difference(_pointerDownTime ?? DateTime.now());
    final remainingHold = const Duration(milliseconds: 70) - elapsed;

    if (remainingHold > Duration.zero) {
      Future.delayed(remainingHold, () {
        if (!mounted) return;
        _controller.reverse().whenComplete(() {
          if (mounted) {
            _handledByPointer = false;
            widget.onPressed();
          }
        });
      });
    } else {
      _controller.reverse().whenComplete(() {
        if (mounted) {
          _handledByPointer = false;
          widget.onPressed();
        }
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _isPointerPressed = false;
    _handledByPointer = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final displayUrl = widget.url.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), '');

    return Semantics(
      button: true,
      enabled: true,
      label: l10n.openLink,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_handledByPointer) {
              _controller.forward().whenComplete(() {
                if (!mounted) return;
                _controller.reverse().whenComplete(() {
                  if (mounted) {
                    widget.onPressed();
                  }
                });
              });
            }
          },
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;
              const shadowOffset = 2.0;
              final currentOffset = t * shadowOffset;
              final currentShadow = (1.0 - t).clamp(0.0, 1.0) * shadowOffset;
              final scale = 1.0 - (t * 0.02);

              return Transform.translate(
                offset: Offset(currentOffset, currentOffset),
                child: Transform.scale(
                  scale: scale,
                  child: NeoBox(
                    color: const Color(0xFFFFD166), // Yellow
                    shadowColor: colors.shadow,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLg,
                      vertical: 6.8,
                    ),
                    borderRadius: AppDimensions.radiusXl,
                    shadowOffset: currentShadow,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.openLink,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onAccent,
                                ),
                              ),
                              Text(
                                displayUrl,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onAccent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: colors.onAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_outward,
                            color: Colors.white,
                            size: 19.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AddTagSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onSubmit;
  final List<String> currentTags;

  const _AddTagSheet({
    required this.onSubmit,
    this.currentTags = const [],
  });

  @override
  ConsumerState<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends ConsumerState<_AddTagSheet>
    with AppModalDeferredFocusMixin {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final FocusNode _tagFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _tagFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scheduleDeferredFocus(_tagFocusNode);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tagFocusNode.dispose();
    super.dispose();
  }

  void _submitTag(String tag) {
    final clean = tag.trim();
    if (clean.isEmpty) return;
    if (TagHelper.isDuplicate(clean, widget.currentTags)) return;

    HapticFeedback.lightImpact();
    widget.onSubmit(clean);
    dismissAppModalSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final allTagsAsync = ref.watch(allTagsProvider);
    final existingTags = allTagsAsync.value ?? [];

    return AppModalKeyboardLift(
      horizontalPadding: 16.0,
      child: Builder(
        builder: (cardContext) {
          final hasKeyboard = MediaQuery.viewInsetsOf(cardContext).bottom > 0;
          final safeBottom = MediaQuery.paddingOf(cardContext).bottom;

          return Padding(
            padding: EdgeInsets.only(
              bottom: hasKeyboard ? 12.0 : (16.0 + safeBottom),
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    offset: const Offset(2.8, 2.8),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Grab Handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.addTag,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: colors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(
                            width: AppDimensions.dialogHeaderButtonSize,
                            height: AppDimensions.dialogHeaderButtonSize,
                            child: NeoButton(
                              onPressed: () => dismissAppModalSheet(context),
                              padding: EdgeInsets.zero,
                              color: colors.card,
                              borderRadius: AppDimensions.radiusSm,
                              borderWidth: 2,
                              child: Icon(Icons.close, size: 18, color: colors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingLg),
                      TextField(
                        controller: _controller,
                        focusNode: _tagFocusNode,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(color: colors.textPrimary),
                        onSubmitted: (val) {
                          final cleanQuery = val.trim();
                          if (cleanQuery.isEmpty) return;
                          if (TagHelper.isDuplicate(
                              cleanQuery, widget.currentTags)) {
                            return;
                          }
                          final canonicalMatch = TagHelper.findCanonicalTag(
                              cleanQuery, existingTags);
                          _submitTag(canonicalMatch ?? cleanQuery);
                        },
                        decoration: InputDecoration(
                          hintText: l10n.tagNameHint,
                          hintStyle: TextStyle(color: colors.textMuted),
                          prefixIcon: Icon(Icons.local_offer_outlined,
                              color: colors.textPrimary),
                          filled: true,
                          fillColor: colors.surfaceSubtle,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: BorderSide(
                                color: colors.border, width: 3),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: BorderSide(
                                color: colors.border, width: 3),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            borderSide: BorderSide(
                                color: colors.border, width: 3),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          final cleanQuery = value.text.trim();
                          final isDuplicateOnBookmark = cleanQuery.isNotEmpty &&
                              TagHelper.isDuplicate(
                                  cleanQuery, widget.currentTags);
                          final canonicalMatch = cleanQuery.isNotEmpty
                              ? TagHelper.findCanonicalTag(
                                  cleanQuery, existingTags)
                              : null;

                          final suggestions = TagHelper.getSuggestions(
                            cleanQuery,
                            existingTags,
                            exclude: widget.currentTags,
                            limit: 6,
                          );

                          final canAdd =
                              cleanQuery.isNotEmpty && !isDuplicateOnBookmark;
                          final tagToSubmit = canonicalMatch ?? cleanQuery;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutCubic,
                                alignment: Alignment.topCenter,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Duplicate on current bookmark warning
                                    if (isDuplicateOnBookmark) ...[
                                      const SizedBox(height: 10),
                                      NeoBox(
                                        color: const Color(0xFFFFD1D1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        borderRadius: AppDimensions.radiusSm,
                                        borderWidth: 2,
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline,
                                                size: 16,
                                                color: Color(0xFFC0392B)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l10n.tagAlreadyAdded,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFC0392B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (canonicalMatch != null &&
                                        canonicalMatch != cleanQuery) ...[
                                      const SizedBox(height: 10),
                                      NeoBox(
                                        color: const Color(0xFFD4EDDA),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        borderRadius: AppDimensions.radiusSm,
                                        borderWidth: 2,
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.check_circle_outline,
                                                size: 16,
                                                color: Color(0xFF155724)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                l10n.matchesExistingTag(
                                                    canonicalMatch),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF155724),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Suggestions dropdown or chips
                                    if (suggestions.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        cleanQuery.isEmpty
                                            ? l10n.existingTags
                                            : 'Suggestions',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (cleanQuery.isEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: suggestions.map((tag) {
                                            return GestureDetector(
                                              onTap: () => _submitTag(tag),
                                              child: NeoBox(
                                                color: colors.card,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                borderRadius:
                                                    AppDimensions.radiusSm,
                                                borderWidth: 2,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.add,
                                                        size: 14,
                                                        color: colors.textPrimary),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      tag,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                          color: colors.textPrimary),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      else
                                        NeoBox(
                                          color: colors.card,
                                          padding: EdgeInsets.zero,
                                          borderRadius: AppDimensions.radiusMd,
                                          borderWidth: 2,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              for (int i = 0;
                                                  i < suggestions.length;
                                                  i++) ...[
                                                if (i > 0)
                                                  Divider(
                                                      height: 1,
                                                      thickness: 1,
                                                      color: colors.divider),
                                                InkWell(
                                                  onTap: () =>
                                                      _submitTag(suggestions[i]),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          AppDimensions
                                                              .radiusMd),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 14,
                                                        vertical: 10),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .local_offer_outlined,
                                                            size: 16,
                                                            color: colors.textPrimary),
                                                        const SizedBox(
                                                            width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            suggestions[i],
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                                color: colors.textPrimary),
                                                          ),
                                                        ),
                                                        Icon(
                                                            Icons.north_west,
                                                            size: 14,
                                                            color:
                                                                colors.textMuted),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppDimensions.paddingLg),
                              SizedBox(
                                height: AppDimensions.modalActionButtonHeight,
                                width: double.infinity,
                                child: NeoButton(
                                  enableFeedback: false,
                                  onPressed: canAdd
                                      ? () => _submitTag(tagToSubmit)
                                      : null,
                                  color: canAdd
                                      ? AppTheme.accent
                                      : colors.surfaceSubtle,
                                  shadowColor: colors.shadow,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: 2,
                                  padding: EdgeInsets.zero,
                                  child: Center(
                                    child: Text(
                                      l10n.addTag,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: canAdd
                                            ? colors.onAccent
                                            : colors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _TagAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TagAddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      child: Center(
        child: NeoPressable(
          onTap: onPressed,
          shadowOffset: 2.0,
          scaleSquash: 0.04,
          builder: (context, t, shadowOffset) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: colors.border, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow,
                    offset: Offset(shadowOffset, shadowOffset),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colors.onAccent),
              ),
            );
          },
        ),
      ),
    );
  }
}
