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
import '../../utils/url_launcher.dart';
import '../../utils/tag_helper.dart';
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
  bool _isEditingNotes = false;
  bool _notesEdited = false;
  late String _lastSavedNotes;
  bool _isTopBarVisible = true;

  @override
  void initState() {
    super.initState();
    bookmark = widget.bookmark;
    _notesController = TextEditingController(text: bookmark.notes);
    _lastSavedNotes = bookmark.notes;
    _titleController = TextEditingController(text: bookmark.title ?? bookmark.url);
    if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
      bookmark.collection.load().then((_) {
        if (mounted) setState(() {});
      });
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
    if (_notesEdited && _notesController.text != _lastSavedNotes) {
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
    HapticFeedback.selectionClick();
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
                  offset: Offset(3, 3),
                  blurRadius: 0,
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
    final l10n = AppLocalizations.of(context)!;
    final placeholderIconSize =
        (MediaQuery.sizeOf(context).width * 0.16).clamp(48.0, 80.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
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
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: placeholderIconSize,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey.shade900,
                    child: Center(
                      child: Icon(
                        Icons.link,
                        size: placeholderIconSize,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),

          // 2. Main Content Card
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final delta = notification.scrollDelta ?? 0;
                    if (notification.metrics.pixels <= 20) {
                      if (!_isTopBarVisible) {
                        setState(() => _isTopBarVisible = true);
                      }
                    } else if (delta > 2) {
                      // Scrolling down -> hide top buttons
                      if (_isTopBarVisible) {
                        setState(() => _isTopBarVisible = false);
                      }
                    } else if (delta < -2) {
                      // Scrolling up -> show top buttons
                      if (!_isTopBarVisible) {
                        setState(() => _isTopBarVisible = true);
                      }
                    }
                  } else if (notification is UserScrollNotification) {
                    if (notification.direction == ScrollDirection.reverse &&
                        notification.metrics.pixels > 20) {
                      if (_isTopBarVisible) {
                        setState(() => _isTopBarVisible = false);
                      }
                    } else if (notification.direction == ScrollDirection.forward) {
                      if (!_isTopBarVisible) {
                        setState(() => _isTopBarVisible = true);
                      }
                    }
                  }
                  return false;
                },
                child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.28),
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
                              offset: Offset(0, 8),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(32, 32, 32, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // Source Domain
                        Row(
                          children: [
                            const Icon(Icons.web_asset_outlined, size: 24, color: Color(0xFF83D64D)),
                            const SizedBox(width: AppDimensions.paddingSm),
                            Text(
                              bookmark.sourceDomain ?? l10n.unknownSource,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
                                  SizedBox(
                                    width: 104,
                                    child: NeoButton(
                                      onPressed: () {
                                        setState(() {
                                          _isEditingTitle = false;
                                          _titleController.text = bookmark.title ?? bookmark.url;
                                        });
                                      },
                                      color: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      borderRadius: AppDimensions.radiusMd,
                                      borderWidth: 3,
                                      shadowOffset: 2,
                                      child: Text(
                                        l10n.cancel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.paddingMd),
                                  SizedBox(
                                    width: 104,
                                    child: NeoButton(
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
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      borderRadius: AppDimensions.radiusMd,
                                      borderWidth: 3,
                                      shadowOffset: 2,
                                      child: Text(
                                        l10n.save,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
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
                                    fontSize: 28,
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
                              )
                            else
                              NeoBox(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                borderRadius: AppDimensions.radiusSm,
                                borderWidth: 2,
                                color: Colors.white,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E5E5),
                                        border: Border.all(color: AppTheme.border, width: 2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.unsorted,
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
                        const SizedBox(height: AppDimensions.paddingXl),

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
                                vertical: 10.0,
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
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          bookmark.sourceDomain ?? bookmark.url,
                                          style: const TextStyle(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6.0),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.border,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_outward, color: Colors.white, size: 20.0),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingXl),

                        // Actions Row
                        Row(
                          children: [
                            _buildActionItem(
                              Icons.share_outlined,
                              l10n.share,
                              () {
                                Share.share(widget.bookmark.url);
                              },
                              color: const Color(0xFFE8E0FF),
                            ),
                            const SizedBox(width: 8),
                            _buildActionItem(
                              Icons.folder_outlined,
                              l10n.move,
                              _showMoveModal,
                              color: const Color(0xFFFFF2C2),
                            ),
                            const SizedBox(width: 8),
                            _buildActionItem(
                              Icons.refresh,
                              l10n.refresh,
                              _showRefreshDialog,
                              color: const Color(0xFFD3F4E4),
                            ),
                            const SizedBox(width: 8),
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
                              color: const Color(0xFFFFD8DE),
                              isDestructive: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Description
                        Text(l10n.descriptionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Text(
                          bookmark.description ?? l10n.noDescriptionProvided,
                          style: const TextStyle(fontSize: 18, height: 1.5, color: Color(0xFF333333)),
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
                                  onLongPress: () => _confirmRemoveTag(tag),
                                  child: NeoBox(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    borderRadius: AppDimensions.radiusSm,
                                    borderWidth: 2,
                                    child: Text(
                                      tag.isEmpty
                                          ? tag
                                          : '${tag[0].toUpperCase()}${tag.substring(1)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                )),
                            _TagAddButton(
                              label: l10n.add,
                              onPressed: _showAddTagModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingXxl),

                        // Notes
                        Text(l10n.notesLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: _isEditingNotes ? 220 : 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
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
                              if (_isEditingNotes) ...[
                                const SizedBox(height: AppDimensions.paddingMd),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
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
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.cancel,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                      borderRadius: AppDimensions.radiusSm,
                                      borderWidth: 2,
                                      child: Text(
                                        l10n.save,
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingXxxl + bottomInset),
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
                              color: AppTheme.background,
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
      pageBuilder: (ctx, animation, secondaryAnimation) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(ctx),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
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
                      child: NeoButton(
                        onPressed: () => Navigator.pop(ctx),
                        color: AppTheme.background,
                        borderRadius: AppDimensions.radiusLg,
                        borderWidth: AppDimensions.borderWidthMd,
                        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
                        child: Text(
                          AppLocalizations.of(context)!.cancel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMd),
                    Expanded(
                      child: NeoButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _performRefresh();
                        },
                        color: const Color(0xFFFF3366),
                        borderRadius: AppDimensions.radiusLg,
                        borderWidth: AppDimensions.borderWidthMd,
                        shadowOffset: AppDimensions.shadowOffsetSm,
                        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
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
}

  Widget _buildActionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
    bool isDestructive = false,
  }) {
    final fgColor = isDestructive ? const Color(0xFFC0392B) : AppTheme.border;

    return Expanded(
      child: NeoButton(
        onPressed: onTap,
        color: color,
        borderWidth: 2.5,
        borderRadius: 14.0,
        shadowOffset: 2.5,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        );
      },
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
