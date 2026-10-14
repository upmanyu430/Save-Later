import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import 'package:save_later/config/app_constants.dart';


void showNoUrlDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: NeoBox(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              borderRadius: AppDimensions.radiusMd,
              borderWidth: 3,
              shadowOffset: 2.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFF9A826), size: 48), // Accent/Orange color
                  const SizedBox(height: 20),
                  Text(
                    l10n.noUrl,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.border),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.pleaseEnterLinkToSave,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingXxl),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      color: AppTheme.accent,
                      borderWidth: AppDimensions.borderWidthMd,
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingLg),
                      onPressed: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                      child: Text(
                        l10n.ok,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.border),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: animation.drive(Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack))),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
