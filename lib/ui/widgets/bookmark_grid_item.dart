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
import 'pin_icon.dart';
import 'favicon_image.dart';
import '../../providers/providers.dart';
import '../../utils/url_helper.dart';
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
    return NeoPressable(
      enableFeedback: false,
      onTap: () {
        if (widget.isSelectMode) {
          if (widget.onSelectTapped != null) widget.onSelectTapped!();
        } else {
          ref.read(bookmarkNotifierProvider.notifier).markAsRead(widget.bookmark);
          context.push('/bookmark/${widget.bookmark.id}', extra: widget.bookmark);
        }
      },
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onLongPressCancel: _handleLongPressCancel,
      scaleSquash: 0.025,
      builder: (context, t, shadowOffset) {
        return Opacity(
          opacity: _isMenuOpen ? 0.0 : 1.0,
          child: Container(
            key: _cardKey,
            child: _buildCard(shadowOffset: shadowOffset),
          ),
        );
      },
    ).animate().slideY(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
  
  static const double _cardRadius = AppDimensions.radiusBookmarkCard;
  static const double _innerRadius = _cardRadius - 3.0;

  Widget _buildCard({double shadowOffset = 2.0}) {
    final b = widget.bookmark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NeoBox(
          padding: const EdgeInsets.all(0),
          borderRadius: _cardRadius,
          shadowOffset: shadowOffset,
      child: Column(
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
                    child: b.imageUrl != null
                        ? Image.network(
                            UrlHelper.resolveImageUrl(b.imageUrl, b.url) ??
                                (b.imageUrl!.startsWith('//') ? 'https:${b.imageUrl!}' : b.imageUrl!), 
                            fit: BoxFit.cover, 
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey)
                          )
                        : Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                b.title != null && b.title!.isNotEmpty ? b.title![0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 36, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900, color: AppTheme.border),
                              ),
                            ),
                          ),
                  ),
                  // Overlay Unsorted/Collection pill
                  if (widget.showCollectionPill)
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
                  if (!b.isRead)
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
