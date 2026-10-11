import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/bookmark.dart';
import '../../theme/app_theme.dart';
import 'neo_box.dart';
import 'bookmark_radial_menu.dart';
import 'pin_icon.dart';
import '../../providers/providers.dart';
import 'package:save_later/config/app_constants.dart';


class BookmarkGridItem extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback? onSelectTapped;
  final bool forceBold;

  const BookmarkGridItem({
    super.key, 
    required this.bookmark,
    this.isSelectMode = false,
    this.isSelected = false,
    this.onSelectTapped,
    this.forceBold = false,
  });

  @override
  ConsumerState<BookmarkGridItem> createState() => _BookmarkGridItemState();
}

class _BookmarkGridItemState extends ConsumerState<BookmarkGridItem> {
  final GlobalKey _cardKey = GlobalKey();

  void _handleLongPressStart(LongPressStartDetails details) {
    if (widget.isSelectMode) return;

    HapticFeedback.mediumImpact();
    
    final renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final rect = position & size;
      
      BookmarkRadialMenu.show(
        context: context,
        child: _buildCard(), // Replica
        bookmark: widget.bookmark,
        cardRect: rect,
        ref: ref,
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
    BookmarkRadialMenu.executeSelectedAndClose();
  }
  
  void _handleLongPressCancel() {
    if (widget.isSelectMode) return;
    BookmarkRadialMenu.executeSelectedAndClose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
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
      child: Container(
        key: _cardKey,
        child: _buildCard(),
      ),
    ).animate().slideY(curve: Curves.easeOutBack, duration: 400.ms).fadeIn();
  }
  
  Widget _buildCard() {
    final b = widget.bookmark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        NeoBox(
          padding: const EdgeInsets.all(0),
          borderRadius: AppDimensions.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border, width: AppDimensions.borderWidthMd)),
                color: Color(0xFFF0F0F0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(9.5)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9.5)),
                    child: b.imageUrl != null
                        ? Image.network(
                            b.imageUrl!.startsWith('//') ? 'https:${b.imageUrl!}' : b.imageUrl!, 
                            fit: BoxFit.cover, 
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey)
                          )
                        : Center(
                            child: Text(
                              b.title != null && b.title!.isNotEmpty ? b.title![0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 48, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900, color: AppTheme.border),
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
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      b.title ?? b.url,
                      style: TextStyle(fontSize: 14, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.bold, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.border,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            b.sourceDomain != null && b.sourceDomain!.isNotEmpty ? b.sourceDomain![0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 9, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b.sourceDomain ?? AppLocalizations.of(context)!.unknown,
                          style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: widget.forceBold ? FontWeight.bold : FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                ],
              ),
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
          shadowOffset: 2.0,
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
