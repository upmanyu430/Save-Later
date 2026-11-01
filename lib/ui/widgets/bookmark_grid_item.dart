import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/bookmark.dart';
import '../../theme/app_theme.dart';
import 'neo_box.dart';
import 'neo_pressable.dart';
import 'bookmark_radial_menu.dart';
import 'bookmark_image.dart';
import 'pin_icon.dart';
import 'favicon_image.dart';
import '../../providers/providers.dart';
import 'package:save_later/config/app_constants.dart';


class BookmarkGridItem extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onSelectTapped;
  final bool forceBold;
  final bool showCollectionPill;

  const BookmarkGridItem({
    super.key, 
    required this.bookmark,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onSelectTapped,
    this.forceBold = false,
    this.showCollectionPill = false,
  });

  @override
  ConsumerState<BookmarkGridItem> createState() => _BookmarkGridItemState();
}

class _BookmarkGridItemState extends ConsumerState<BookmarkGridItem> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isMenuOpen = false;

  void _handleLongPressStart(LongPressStartDetails details) {
    if (widget.isSelectMode) return;

    HapticFeedback.mediumImpact();
    
    final renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final rect = position & size;

      setState(() => _isMenuOpen = true);
      BookmarkRadialMenu.show(
        context: context,
        child: _buildCard(), // Replica
        bookmark: widget.bookmark,
        cardRect: rect,
        ref: ref,
        onDismissed: () {
          if (mounted) setState(() => _isMenuOpen = false);
        },
      );
      BookmarkRadialMenu.updatePosition(details.globalPosition);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (widget.isSelectMode) return;
    BookmarkRadialMenu.updatePosition(details.globalPosition);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (widget.isSelectMode) return;
    BookmarkRadialMenu.handleLongPressEnd();
  }
  
  void _handleLongPressCancel() {
    if (widget.isSelectMode) return;
    BookmarkRadialMenu.handleLongPressCancel();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(savingBookmarkIdsProvider).contains(widget.bookmark.id);
    final isRefreshing = ref.watch(refreshingBookmarkIdsProvider).contains(widget.bookmark.id);
    final isBusy = isSaving || isRefreshing;

    return NeoPressable(
      enableFeedback: true,
      onTap: () {
        if (isBusy) return;
        if (widget.isSelectMode) {
          if (widget.onSelectTapped != null) widget.onSelectTapped!();
        } else {
          // Defer markAsRead so it does not trigger Riverpod provider invalidation during the animation
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) {
              ref.read(bookmarkNotifierProvider.notifier).markAsRead(widget.bookmark);
            }
          });
          context.push('/bookmark/${widget.bookmark.id}', extra: widget.bookmark);
        }
      },
      onLongPressStart: isBusy ? null : _handleLongPressStart,
      onLongPressMoveUpdate: isBusy ? null : _handleLongPressMoveUpdate,
      onLongPressEnd: isBusy ? null : _handleLongPressEnd,
      onLongPressCancel: isBusy ? null : _handleLongPressCancel,
      scaleSquash: isBusy ? 0.0 : 0.025,
      builder: (context, t, shadowOffset) {
        return Opacity(
          opacity: _isMenuOpen ? 0.0 : 1.0,
          child: Container(
            key: _cardKey,
            child: _buildCard(
              shadowOffset: shadowOffset,
              isSaving: isSaving,
              isRefreshing: isRefreshing,
            ),
          ),
        );
      },
    ).animate().slideY(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
  
  static const double _cardRadius = AppDimensions.radiusBookmarkCard;
  static const double _innerRadius = _cardRadius - 3.0;

  String _getInitialLetter(Bookmark b) {
    if (b.sourceDomain != null && b.sourceDomain!.isNotEmpty) {
      final clean = b.sourceDomain!.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
      if (clean.isNotEmpty) {
        return clean[0].toUpperCase();
      }
    }
    if (b.title != null && b.title!.isNotEmpty) {
      final t = b.title!.trim();
      if (t.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))) {
        final uri = Uri.tryParse(t);
        if (uri != null && uri.host.isNotEmpty) {
          final host = uri.host.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
          if (host.isNotEmpty) return host[0].toUpperCase();
        }
      }
      return t[0].toUpperCase();
    }
    return '?';
  }

  Widget _buildCard({
    double shadowOffset = 2.0,
    bool isSaving = false,
    bool isRefreshing = false,
  }) {
    final isBusy = isSaving || isRefreshing;
    final b = widget.bookmark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NeoBox(
          padding: const EdgeInsets.all(0),
          borderRadius: _cardRadius,
          shadowOffset: shadowOffset,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_innerRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border, width: 3.0)),
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(_innerRadius)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(_innerRadius)),
                    child: BookmarkImage(
                      imageUrl: b.imageUrl,
                      url: b.url,
                      fallback: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getInitialLetter(b),
                            style: TextStyle(fontSize: 36, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900, color: AppTheme.border),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Overlay Unsorted/Collection pill
                  if (widget.showCollectionPill && !isBusy)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          b.collection.value?.name ?? AppLocalizations.of(context)!.unsorted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (!b.isRead && !isBusy)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Transform.rotate(
                        angle: -0.1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.border, width: 1.5),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.newBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900,
                              color: AppTheme.border,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Select Mode Checkbox
                  if (widget.isSelectMode)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: widget.isSelected ? const Color(0xFFFFD166) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border, width: 2),
                        ),
                        child: AnimatedScale(
                          scale: widget.isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: const Icon(
                            Icons.check, 
                            size: 16, 
                            color: AppTheme.border,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(_innerRadius)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 27,
                  child: Text(
                    b.title ?? b.url,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w800,
                      color: AppTheme.border,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    FaviconImage(
                      domain: b.sourceDomain,
                      url: b.url,
                      size: 14.0,
                      borderRadius: 2.0,
                      fallback: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            b.sourceDomain != null && b.sourceDomain!.isNotEmpty ? b.sourceDomain![0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 8, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        b.sourceDomain ?? AppLocalizations.of(context)!.unknown,
                        style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
                if (isBusy)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isRefreshing ? 12 : 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border, width: 2.0),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.border,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.border),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRefreshing ? 'REFRESHING...' : 'SAVING...',
                              style: TextStyle(
                                color: AppTheme.border,
                                fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900,
                                fontSize: 11.5,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    if (b.isPinned && (!widget.isSelectMode))
      Positioned(
        top: -8,
        right: 8,
        child: NeoBox(
          color: const Color(0xFFFFD166),
          borderRadius: 8.0,
          borderWidth: 2.0,
          shadowOffset: shadowOffset,
          padding: const EdgeInsets.all(4.0),
          child: const PinIcon(
            isPinned: true,
            size: 16,
            color: AppTheme.border,
            strokeWidth: 2.2,
          ),
        ),
      ),
  ],
);
  }
}
