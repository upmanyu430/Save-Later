import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'package:save_later/config/app_constants.dart';


class FolderBox extends StatelessWidget {
  final String title;
  final String itemCountText;
  final Color folderColor;
  final VoidCallback onTap;
  final bool hasNewItems;
  final IconData icon;
  final bool forceBold;

  const FolderBox({
    super.key,
    required this.title,
    required this.itemCountText,
    required this.folderColor,
    required this.onTap,
    this.hasNewItems = false,
    this.icon = Icons.folder_outlined,
    this.forceBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Stack(
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
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.border,
                    offset: Offset(6, 6),
                  ),
                ],
              ),
            ),
          ),
          // The Main Body
          Padding(
            padding: const EdgeInsets.only(top: 15.0),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLg),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                border: Border.all(
                  color: AppTheme.border,
                  width: 3.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.border,
                    offset: Offset(6, 6),
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
                          child: Icon(icon, color: AppTheme.border, size: AppDimensions.iconSizeLg),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  itemCountText,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.border,
                                  ),
                                ),
                              ),
                            ),
                            if (hasNewItems) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD166),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.newBadge,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: forceBold ? FontWeight.bold : FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
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
            ),
          ),
        ],
      ),
    );
  }
}


