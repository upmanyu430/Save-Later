import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'neo_button.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const DeleteConfirmationDialog({
    super.key,
    this.title = 'Delete link',
    this.message = 'Permanently delete this link?',
    this.confirmText = 'Delete',
    this.cancelText = 'Cancel',
  });

  static Future<bool> show({
    required BuildContext context,
    String title = 'Delete link',
    String message = 'Permanently delete this link?',
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
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
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).pop(false),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: DeleteConfirmationDialog(
                  title: title,
                  message: message,
                  confirmText: confirmText,
                  cancelText: cancelText,
                ),
              ),
            ),
          ),
        );
      },
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.border,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle / Confirmation question
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons: Cancel and Delete
          Row(
            children: [
              // Cancel Button
              Expanded(
                child: NeoButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  color: Colors.white,
                  borderWidth: 2.5,
                  borderRadius: 12.0,
                  shadowOffset: 3.0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    cancelText,
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

              // Delete Button
              Expanded(
                child: NeoButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  color: const Color(0xFFEF476F),
                  borderWidth: 2.5,
                  borderRadius: 12.0,
                  shadowOffset: 3.0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
