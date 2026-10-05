import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FolderBox extends StatelessWidget {
  final String title;
  final String itemCountText;
  final Color folderColor;
  final VoidCallback onTap;

  const FolderBox({
    Key? key,
    required this.title,
    required this.itemCountText,
    required this.folderColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The Tab
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 90,
              height: 35,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Inner colored square with icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: folderColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.border,
                            width: 2.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.folder_outlined, color: AppTheme.border, size: 28),
                        ),
                      ),
                      Text(
                        itemCountText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.border,
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
