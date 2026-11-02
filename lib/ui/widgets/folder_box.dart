import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/collection.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';
import 'neo_pressable.dart';

class FolderBox extends StatelessWidget {
  final String title;
  final String itemCountText;
  final Color folderColor;
  final VoidCallback onTap;
  final bool hasNewItems;
  final int newCount;
  final IconData icon;
  final bool forceBold;
  final bool showTab;
  final GlobalKey? bodyKey;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  final GestureLongPressEndCallback? onLongPressEnd;
  final VoidCallback? onLongPressCancel;
  final double shadowOffset;
  final bool isInteractive;
  final bool enableFeedback;

  const FolderBox({
    super.key,
    required this.title,
    required this.itemCountText,
    required this.folderColor,
    required this.onTap,
    this.hasNewItems = false,
    this.newCount = 0,
    this.icon = Icons.folder_outlined,
    this.forceBold = false,
    this.showTab = true,
    this.bodyKey,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onLongPressCancel,
    this.shadowOffset = 2.0,
    this.isInteractive = true,
    this.enableFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeoPressable(
      onTap: isInteractive ? onTap : null,
      onLongPressStart: isInteractive ? onLongPressStart : null,
      onLongPressMoveUpdate: isInteractive ? onLongPressMoveUpdate : null,
      onLongPressEnd: isInteractive ? onLongPressEnd : null,
      onLongPressCancel: isInteractive ? onLongPressCancel : null,
      shadowOffset: shadowOffset,
      scaleSquash: 0.025,
      enableFeedback: enableFeedback,
      builder: (context, t, currentShadow) {
        final showBadge = hasNewItems || newCount > 0;
        final badgeText = newCount > 0
            ? '$newCount ${AppLocalizations.of(context)!.newBadge}'
            : AppLocalizations.of(context)!.newBadge;

        final body = Container(
          key: bodyKey,
          padding: const EdgeInsets.all(AppDimensions.paddingLg),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: AppTheme.border,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.border,
                offset: Offset(currentShadow, currentShadow),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Inner colored square with icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: folderColor,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(
                        color: AppTheme.border,
                        width: 2.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: BookmarkCollection.isWhiteIconColor(folderColor)
                            ? Colors.white
                            : AppTheme.border,
                        size: AppDimensions.iconSizeLg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showBadge) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD166),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppTheme.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: forceBold ? FontWeight.bold : FontWeight.w900,
                                  color: AppTheme.border,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            itemCountText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: forceBold ? FontWeight.bold : FontWeight.bold,
                  color: AppTheme.border,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

        final content = showTab
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  // The Tab
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: MediaQuery.sizeOf(context).width * 0.22,
                      height: MediaQuery.sizeOf(context).width * 0.085,
                      decoration: BoxDecoration(
                        color: folderColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: AppTheme.border,
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.border,
                            offset: Offset(currentShadow, currentShadow),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The Main Body
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: body,
                  ),
                ],
              )
            : body;

        return content;
      },
    );
  }
}
