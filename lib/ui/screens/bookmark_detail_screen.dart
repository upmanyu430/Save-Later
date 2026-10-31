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
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/pin_icon.dart';
import '../widgets/favicon_image.dart';
import '../../utils/url_launcher.dart';
import '../../utils/tag_helper.dart';
import '../../utils/url_helper.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTagSheet(
        currentTags: bookmark.tags,
        onSubmit: (tag) => _addTag(tag),
      ),
    );
  }

  void _addTag(String tag) async {
    HapticFeedback.lightImpact();
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
              CurveTween(curve: Curves.easeOutBack),
            ),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final l10n = AppLocalizations.of(context)!;
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
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    border: Border.all(color: AppTheme.border, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.border,
                        offset: Offset(2.8, 2.8),
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
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Text(
                          'Remove "$tag" from this bookmark?',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, color: Colors.black54),
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),
                        Row(
                          children: [
                            Expanded(
                              child: NeoButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                borderRadius: AppDimensions.radiusMd,
                                borderWidth: 2,
                                child: Text(
                                  l10n.cancel,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                borderRadius: AppDimensions.radiusMd,
                                borderWidth: 2,
                                child: Text(
                                  l10n.delete,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_notFound || _loadedBookmark == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border, size: 64, color: Colors.black26),
                  const SizedBox(height: AppDimensions.paddingMd),
                  const Text(
                    'Bookmark not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.paddingLg),
                  NeoButton(
                    onPressed: () => context.pop(),
                    color: Colors.white,
                    child: const Text('Go back', style: TextStyle(fontWeight: FontWeight.bold)),
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
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
                  if (bookmark.imageUrl != null)
                    Image.network(
                      UrlHelper.resolveImageUrl(bookmark.imageUrl, bookmark.url) ??
                          (bookmark.imageUrl!.startsWith('//')
                              ? 'https:${bookmark.imageUrl!}'
                              : bookmark.imageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: placeholderIconSize,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFFEFECE6),
                      child: Center(
                        child: Icon(
                          Icons.link,
                          size: placeholderIconSize,
                          color: AppTheme.border.withValues(alpha: 0.35),
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
                      color: AppTheme.border,
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                          border: Border.fromBorderSide(
                            BorderSide(color: AppTheme.border, width: 3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.border,
                              offset: Offset(2.8, 2.8),
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
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  border: Border.all(color: const Color(0xFFFFD166), width: 3),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(
                                    fontSize: 23,
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
                                  NeoButton(
                                    onPressed: () {
                                      setState(() {
                                        _isEditingTitle = false;
                                        _titleController.text = bookmark.title ?? bookmark.url;
                                      });
                                    },
                                    color: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      l10n.cancel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Colors.black,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      l10n.save,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: Colors.black,
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
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.5,
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
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: const Icon(Icons.edit_outlined, size: AppDimensions.iconSizeMd),
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
                              color: Colors.white,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: bookmark.collection.value?.color ?? const Color(0xFFE5E5E5),
                                      border: Border.all(color: AppTheme.border, width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    bookmark.collection.value?.name ?? l10n.unsorted,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, h:mm a').format(bookmark.createdAt),
                              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),

                        // Open Link Button
                        NeoPressable(
                          onTap: () async {
                            await openUrl(bookmark.url, context: context);
                          },
                          shadowOffset: 2.0,
                          scaleSquash: 0.02,
                          builder: (context, t, shadowOffset) {
                            return NeoBox(
                              color: const Color(0xFFFFD166), // Yellow
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingLg,
                                vertical: 6.8,
                              ),
                              borderRadius: AppDimensions.radiusXl,
                              shadowOffset: shadowOffset,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.openLink,
                                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800),
                                        ),
                                        Text(
                                          bookmark.url.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), ''),
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(5.0),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.border,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_outward, color: Colors.white, size: 19.0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingMd),

                        // Actions Strip
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            boxShadow: const [
                              BoxShadow(
                                color: AppTheme.border,
                                offset: Offset(2.8, 2.8),
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(
                              color: AppTheme.border,
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

                                      await ref.read(bookmarkNotifierProvider.notifier).refreshMetadata(bookmark);
                                      if (!mounted) return;
                                      final refreshed = await ref.read(repositoryProvider).getBookmark(bookmark.id);
                                      if (refreshed != null && mounted) {
                                        setState(() {
                                          _initBookmark(refreshed);
                                        });
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
                        Text(l10n.descriptionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: AppDimensions.paddingSm),
                        _buildDescription(l10n),
                        const SizedBox(height: AppDimensions.paddingLg),

                        // Tags
                        Text(l10n.tagsLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: AppDimensions.paddingSm),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ...bookmark.tags.map((tag) => GestureDetector(
                                  onLongPress: () => _confirmRemoveTag(tag),
                                  child: NeoBox(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      tag.isEmpty
                                          ? tag
                                          : '${tag[0].toUpperCase()}${tag.substring(1)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
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
                                      color: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.cancel,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.save,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                              color: const Color(0xFFFFF7E0), // Pale yellow
                              borderRadius: AppDimensions.radiusMd,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: TextField(
                                controller: _notesController,
                                readOnly: !_isEditingNotes,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
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
                                decoration: const InputDecoration(
                                  hintText: 'Tap here to save notes',
                                  hintStyle: TextStyle(
                                    color: Colors.black38,
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
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
                                  color: Colors.white,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeMd),
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
                                  color: bookmark.isPinned ? const Color(0xFFFFD166) : Colors.white,
                                  borderRadius: AppDimensions.radiusMd,
                                  borderWidth: AppDimensions.borderWidthMd,
                                  child: PinIcon(
                                    isPinned: bookmark.isPinned,
                                    size: AppDimensions.iconSizeMd,
                                    color: AppTheme.border,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.border,
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
              CurveTween(curve: Curves.easeOutBack),
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, animation, secondaryAnimation) => GestureDetector(
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppTheme.border, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.border,
                      offset: Offset(2.8, 2.8),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.border,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.refreshMetadataDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF555555),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: NeoButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              color: Colors.white,
                              borderRadius: 12.0,
                              borderWidth: 2.5,
                              shadowOffset: 3.0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Text(
                                AppLocalizations.of(context)!.cancel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.border,
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
                              borderRadius: 12.0,
                              borderWidth: 2.5,
                              shadowOffset: 3.0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Text(
                                AppLocalizations.of(context)!.refresh,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.border,
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
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    final description = bookmark.description?.trim();
    const style = TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF333333));

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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      color: AppTheme.border,
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
      color: AppTheme.border,
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
      reverseCurve: Curves.easeOutBack,
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
    final idleFgColor = widget.isDestructive ? const Color(0xFFC0392B) : AppTheme.border;
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
                final backgroundColor = Color.lerp(Colors.white, widget.color, t)!;
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
                          child: const ColoredBox(color: AppTheme.border),
                        ),
                      // Left recess shadow simulating mechanical button depression
                      if (leftRecess > 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          bottom: 0,
                          width: leftRecess,
                          child: const ColoredBox(color: AppTheme.border),
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

class _AddTagSheetState extends ConsumerState<_AddTagSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitTag(String tag) {
    final clean = tag.trim();
    if (clean.isEmpty) return;
    if (TagHelper.isDuplicate(clean, widget.currentTags)) return;

    HapticFeedback.lightImpact();
    widget.onSubmit(clean);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTagsAsync = ref.watch(allTagsProvider);
    final existingTags = allTagsAsync.value ?? [];

    final rawText = _controller.text;
    final cleanQuery = rawText.trim();
    final isDuplicateOnBookmark = cleanQuery.isNotEmpty &&
        TagHelper.isDuplicate(cleanQuery, widget.currentTags);
    final canonicalMatch = cleanQuery.isNotEmpty
        ? TagHelper.findCanonicalTag(cleanQuery, existingTags)
        : null;

    final suggestions = TagHelper.getSuggestions(
      cleanQuery,
      existingTags,
      exclude: widget.currentTags,
      limit: 6,
    );

    final canAdd = cleanQuery.isNotEmpty && !isDuplicateOnBookmark;
    final tagToSubmit = canonicalMatch ?? cleanQuery;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.border, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.border,
                        offset: Offset(2.8, 2.8),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 18.0),
                child: SingleChildScrollView(
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
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.addTag,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.border,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: NeoButton(
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              color: AppTheme.cardColor,
                              borderRadius: AppDimensions.radiusSm,
                              borderWidth: 2,
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.paddingLg),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (canAdd) _submitTag(tagToSubmit);
                },
                decoration: InputDecoration(
                  hintText: l10n.tagNameHint,
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(Icons.local_offer_outlined, color: AppTheme.border),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.border, width: 3),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.border, width: 3),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    borderSide: const BorderSide(color: AppTheme.border, width: 3),
                  ),
                ),
              ),

              // Duplicate on current bookmark warning
              if (isDuplicateOnBookmark) ...[
                const SizedBox(height: 10),
                NeoBox(
                  color: const Color(0xFFFFD1D1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: AppDimensions.radiusSm,
                  borderWidth: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFC0392B)),
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
              ] else if (canonicalMatch != null && canonicalMatch != cleanQuery) ...[
                const SizedBox(height: 10),
                NeoBox(
                  color: const Color(0xFFD4EDDA),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: AppDimensions.radiusSm,
                  borderWidth: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF155724)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.matchesExistingTag(canonicalMatch),
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
                  cleanQuery.isEmpty ? l10n.existingTags : 'Suggestions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.black54,
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
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          borderRadius: AppDimensions.radiusSm,
                          borderWidth: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 14, color: AppTheme.border),
                              const SizedBox(width: 4),
                              Text(
                                tag,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  NeoBox(
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    borderRadius: AppDimensions.radiusMd,
                    borderWidth: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < suggestions.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, thickness: 1, color: AppTheme.border),
                          InkWell(
                            onTap: () => _submitTag(suggestions[i]),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_offer_outlined, size: 16, color: AppTheme.border),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      suggestions[i],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  const Icon(Icons.north_west, size: 14, color: Colors.black38),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],

              const SizedBox(height: AppDimensions.paddingLg),
              NeoButton(
                onPressed: canAdd ? () => _submitTag(tagToSubmit) : null,
                color: canAdd ? AppTheme.accent : const Color(0xFFDDDDDD),
                borderRadius: AppDimensions.radiusMd,
                borderWidth: 2,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l10n.addTag,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: canAdd ? AppTheme.border : Colors.black38,
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
    ),
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
    return NeoPressable(
      onTap: onPressed,
      shadowOffset: 2.0,
      scaleSquash: 0.04,
      builder: (context, t, shadowOffset) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppTheme.border, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.border,
                offset: Offset(shadowOffset, shadowOffset),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      },
    );
  }
}
