import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'neo_button.dart';

class MovedSuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onConfirm;

  const MovedSuccessDialog({
    super.key,
    this.title = 'Moved successfully',
    this.message = 'The link has been moved to the selected collection.',
    this.buttonText = 'OK',
    this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    String title = 'Moved successfully',
    String message = 'The link has been moved to the selected collection.',
    String buttonText = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
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
          onTap: () {
            onConfirm?.call();
            Navigator.of(dialogContext).pop();
          },
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Material(
                color: Colors.transparent,
                child: MovedSuccessDialog(
                  title: title,
                  message: message,
                  buttonText: buttonText,
                  onConfirm: onConfirm,
                ),
              ),
            ),
          ),
        );
      },
    );
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
            offset: Offset(4, 4),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green Circle Check Badge
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF22C55E),
                  width: 2.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF22C55E),
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.border,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle / Description
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

          // Action Button
          NeoButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) {
                onConfirm!();
              }
            },
            color: AppTheme.accent,
            borderWidth: 2.5,
            borderRadius: 12.0,
            shadowOffset: 3.0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppTheme.border,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
