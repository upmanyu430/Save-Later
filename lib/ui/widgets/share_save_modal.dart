import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/collection.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';
import 'animated_checkmark.dart';
import 'app_modal_sheet.dart';
import 'collection_editor_modal.dart';
import 'neo_button.dart';
import 'pin_icon.dart';
import 'stored_icon.dart';

class ShareSaveResult {
  final BookmarkCollection? collection;
  final bool isUnsorted;
  final bool isPinned;
  final double? modalHeight;

  const ShareSaveResult({
    this.collection,
    required this.isUnsorted,
    required this.isPinned,
    this.modalHeight,
  });
}

class ShareSaveModal extends ConsumerStatefulWidget {
  final String url;
  final Future<void> Function(BookmarkCollection? collection, bool isPinned)? onSave;

  const ShareSaveModal({
    super.key,
    required this.url,
    this.onSave,
  });

  static Future<ShareSaveResult?> show({
    required BuildContext context,
    required String url,
    Future<void> Function(BookmarkCollection? collection, bool isPinned)? onSave,
  }) async {
    return showAppModalSheet<ShareSaveResult?>(
      context: context,
      builder: (ctx) => ShareSaveModal(
        url: url,
        onSave: onSave,
      ),
    );
  }

  static String formatTargetLabel(String prefix, String name) {
    if (name.length <= 22) {
      return '$prefix "$name"';
    }
    final truncated = '${name.substring(0, 10)}...${name.substring(name.length - 8)}';
    return '$prefix "$truncated"';
  }

  @override
  ConsumerState<ShareSaveModal> createState() => _ShareSaveModalState();
}

class _ShareSaveModalState extends ConsumerState<ShareSaveModal> {
  final GlobalKey _cardKey = GlobalKey();
  late final ScrollController _scrollController;
  BookmarkCollection? _selectedCollection;
  bool _isUnsortedSelected = true;
  bool _isPinned = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openCreateCollection() async {
    await showAppModalSheet<void>(
      context: context,
      unfocusBeforeOpen: false,
      builder: (ctx) => const CollectionEditorModal(),
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final targetCollection = _isUnsortedSelected ? null : _selectedCollection;
    final measuredHeight = _cardKey.currentContext?.size?.height;

    try {
      if (widget.onSave != null) {
        await widget.onSave!(targetCollection, _isPinned);
      } else {
        await ref.read(bookmarkNotifierProvider.notifier).quickSave(
          widget.url,
          collection: targetCollection,
          isPinned: _isPinned,
        );
      }

      if (!mounted) return;
      final result = ShareSaveResult(
        collection: targetCollection,
        isUnsorted: _isUnsortedSelected,
        isPinned: _isPinned,
        modalHeight: measuredHeight,
      );
      if (Navigator.canPop(context)) {
        dismissAppModalSheet(context, result);
      } else {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildUnsortedTile(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSelected = _isUnsortedSelected;

    return GestureDetector(
      key: const ValueKey('share_modal_unsorted'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isUnsortedSelected = true;
          _selectedCollection = null;
        });
      },
      child: Tooltip(
        message: l10n?.unsorted ?? 'Unsorted',
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.modalFolderOptionHorizontalMargin),
          padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: AppDimensions.modalFolderOptionVerticalPadding),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF4D0) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFDD164)
                  : Colors.black.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 2.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.modalFolderOptionIconBoxSize,
                height: AppDimensions.modalFolderOptionIconBoxSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1.8,
                  ),
                ),
                child: const Icon(
                  Icons.folder_outlined,
                  color: AppTheme.border,
                  size: AppDimensions.modalFolderOptionIconSize,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.unsorted ?? 'Unsorted',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.border,
                  ),
                ),
              ),
              AnimatedCheckmark(
                isSelected: isSelected,
                color: const Color(0xFFFDD164),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(allCollectionsProvider);
    final l10n = AppLocalizations.of(context);
    // Exact height matching the Add New Collection modal (CollectionEditorModal):
    final targetModalHeight =
        CollectionEditorModal.getCollapsedModalHeight(context);

    return AppModalKeyboardLift(
      maxHeight: targetModalHeight,
      freezeWhenCovered: true,
      child: SizedBox(
        key: const ValueKey('share_save_modal_sheet'),
        child: Container(
          key: _cardKey,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(55),
            border: Border.all(color: AppTheme.border, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pinned Drag Handle ONLY
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 6),
                              // Header Row: Title & Create Collection Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Save to Save Later',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.border,
                                        letterSpacing: -0.3,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: AppDimensions.paddingSm),
                                  SizedBox(
                                    width: AppDimensions.dialogHeaderButtonSize,
                                    height: AppDimensions.dialogHeaderButtonSize,
                                    child: NeoButton(
                                      onPressed: _openCreateCollection,
                                      padding: EdgeInsets.zero,
                                      color: Colors.white,
                                      borderRadius: AppDimensions.radiusMd,
                                      borderWidth: AppDimensions.borderWidthMd,
                                      child: const Icon(
                                        Icons.create_new_folder_outlined,
                                        size: AppDimensions.dialogHeaderIconSize,
                                        color: AppTheme.border,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 6),

                        // Shared URL Text
                        Text(
                          widget.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pin this link tile
                        GestureDetector(
                          key: const ValueKey('share_modal_pin_row'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isPinned = !_isPinned;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.modalFolderOptionHorizontalMargin),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: AppDimensions.modalFolderOptionVerticalPadding),
                            decoration: BoxDecoration(
                              color: _isPinned
                                  ? const Color(0xFFFFF4D0)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isPinned
                                    ? const Color(0xFFFDD164)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: _isPinned ? 1.5 : 2.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                PinIcon(
                                  isPinned: _isPinned,
                                  size: 20,
                                  color: _isPinned
                                      ? const Color(0xFFFDD164)
                                      : AppTheme.border,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Pin this link',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.border,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Collections List
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: collectionsAsync.when(
                          data: (collections) {
                            final selected = _selectedCollection;

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: collections.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, index) {
                                  if (index == 0) {
                                    return _buildUnsortedTile(context);
                                  }

                                  final col = collections[index - 1];
                                  final isSelected =
                                      !_isUnsortedSelected && selected?.id == col.id;

                                  final iconColor =
                                      BookmarkCollection.isWhiteIconColor(col.color)
                                          ? Colors.white
                                          : AppTheme.border;

                                  return GestureDetector(
                                    key: ValueKey('share_modal_collection_${col.id}'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() {
                                        _selectedCollection = col;
                                        _isUnsortedSelected = false;
                                      });
                                    },
                                    child: Tooltip(
                                      message: col.name,
                                      child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: AppDimensions.modalFolderOptionHorizontalMargin),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: AppDimensions.modalFolderOptionVerticalPadding),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFF4D0)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFFDD164)
                                              : Colors.black.withValues(alpha: 0.08),
                                          width: isSelected ? 1.5 : 2.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: AppDimensions.modalFolderOptionIconBoxSize,
                                            height: AppDimensions.modalFolderOptionIconBoxSize,
                                            decoration: BoxDecoration(
                                              color: col.color,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: AppTheme.border,
                                                width: 1.8,
                                              ),
                                            ),
                                            child: Icon(
                                              storedIcon(
                                                col.iconCodePoint,
                                                col.iconFontFamily,
                                              ),
                                              color: iconColor,
                                              size: AppDimensions.modalFolderOptionIconSize,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  col.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme.border,
                                                  ),
                                                ),
                                                if (col.parentId != null) ...[
                                                  Builder(
                                                    builder: (context) {
                                                      final parent = collections
                                                          .where((c) =>
                                                              c.id == col.parentId)
                                                          .firstOrNull;
                                                      if (parent == null) {
                                                        return const SizedBox.shrink();
                                                      }
                                                      return Text(
                                                        'in ${parent.name}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black
                                                              .withValues(alpha: 0.5),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          AnimatedCheckmark(
                                            isSelected: isSelected,
                                            color: const Color(0xFFFDD164),
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                e.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),

                  // Pinned Bottom Section: Divider & Save Button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      18.0,
                      0.0,
                      18.0,
                      AppDimensions.modalActionButtonBottomPadding +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 1,
                          color: Colors.black.withValues(alpha: 0.08),
                          margin: const EdgeInsets.only(top: 6, bottom: 12),
                        ),
                        Builder(
                          builder: (context) {
                            final String buttonLabel;
                            if (_isUnsortedSelected) {
                              buttonLabel = ShareSaveModal.formatTargetLabel(
                                  'Save to', l10n?.unsorted ?? 'Unsorted');
                            } else if (_selectedCollection != null) {
                              buttonLabel = ShareSaveModal.formatTargetLabel(
                                  'Save to', _selectedCollection!.name);
                            } else {
                              buttonLabel = 'Save';
                            }

                            return SizedBox(
                              height: 48.0,
                              width: double.infinity,
                              child: NeoButton(
                                onPressed: _isSaving ? null : _handleSave,
                                color: const Color(0xFFFFD166),
                                padding: EdgeInsets.zero,
                                borderRadius: AppDimensions.radiusMd,
                                shadowOffset: 2.0,
                                child: Center(
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: AppTheme.border,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          buttonLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.border,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class SaveSuccessModal extends StatefulWidget {
  final Duration autoDismissDuration;
  final double? targetHeight;

  const SaveSuccessModal({
    super.key,
    this.autoDismissDuration = const Duration(milliseconds: 1500),
    this.targetHeight,
  });

  static Future<void> show({
    required BuildContext context,
    Duration autoDismissDuration = const Duration(milliseconds: 1500),
    double? targetHeight,
  }) async {
    return showAppModalSheet<void>(
      context: context,
      builder: (ctx) => SaveSuccessModal(
        autoDismissDuration: autoDismissDuration,
        targetHeight: targetHeight,
      ),
    );
  }

  @override
  State<SaveSuccessModal> createState() => _SaveSuccessModalState();
}

class _SaveSuccessModalState extends State<SaveSuccessModal> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) {
        dismissAppModalSheet(context);
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final view = View.maybeOf(context);
    final windowPaddingTop = view != null
        ? MediaQueryData.fromView(view).padding.top
        : 0.0;
    final mediaPaddingTop = MediaQuery.paddingOf(context).top;
    final statusBarHeight =
        windowPaddingTop > 0 ? windowPaddingTop : mediaPaddingTop;
    final topClearance = statusBarHeight + 16.0;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxAllowedHeight = math.max(0.0, screenHeight - topClearance);
    final desiredHeight = math.max(
      270.0 + bottomPadding,
      widget.targetHeight ?? (screenHeight * 0.55),
    );
    final effectiveHeight = math.min(desiredHeight, maxAllowedHeight);

    return AppModalKeyboardLift(
      maxHeight: effectiveHeight,
      onOutsideTap: () {
        _dismissTimer?.cancel();
        dismissAppModalSheet(context);
      },
      child: Container(
        height: effectiveHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(55),
          border: Border.all(color: AppTheme.border, width: 2.5),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.0,
            14.0,
            24.0,
            24.0 + bottomPadding,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Drag Handle
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
                const SizedBox(height: 16),

                // Green Circle Check Badge
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D287),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.border,
                      width: 2.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppTheme.border,
                        offset: Offset(3.0, 3.0),
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Saved!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.border,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Link saved',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
