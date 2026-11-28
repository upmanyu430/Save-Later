import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_constants.dart';
import '../../theme/app_theme.dart';
import 'app_modal_sheet.dart';
import 'neo_button.dart';

/// Shared neo-brutalist bottom sheet for upcoming Settings features.
class ComingSoonModal extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final String body;

  const ComingSoonModal({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.body,
  });

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required String body,
  }) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => ComingSoonModal(
        icon: icon,
        iconBackgroundColor: iconBackgroundColor,
        title: title,
        body: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppModalKeyboardLift(
      maxWidth: AppDimensions.maxModalWidth,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(
            color: colors.border,
            width: AppDimensions.borderWidthMd,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              offset: const Offset(
                AppDimensions.shadowOffsetXl,
                AppDimensions.shadowOffsetXl,
              ),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.paddingLg,
            AppDimensions.paddingLg,
            AppDimensions.paddingLg,
            AppDimensions.modalActionButtonBottomPadding + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.onAccent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: colors.onAccent,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingLg),
              SizedBox(
                height: AppDimensions.modalActionButtonHeight,
                child: NeoButton(
                  onPressed: () => dismissAppModalSheet(context),
                  color: AppTheme.accent,
                  shadowColor: colors.shadow,
                  borderRadius: AppDimensions.radiusMd,
                  borderWidth: AppDimensions.borderWidthMd,
                  child: Text(
                    l10n.gotIt,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: colors.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
