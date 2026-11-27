import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../config/app_constants.dart';
import '../../theme/app_theme.dart';
import 'app_modal_sheet.dart';
import 'neo_button.dart';

class CloudSyncModal extends StatelessWidget {
  const CloudSyncModal({super.key});

  static Future<void> show(BuildContext context) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => const CloudSyncModal(),
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
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.onAccent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.cloud_outlined,
                    size: 28,
                    color: colors.onAccent,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              Text(
                l10n.cloudSyncComingSoonTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingSm),
              Text(
                l10n.cloudSyncComingSoonBody,
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
                  borderColor: colors.onAccent,
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
