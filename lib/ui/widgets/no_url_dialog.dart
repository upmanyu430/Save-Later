import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import 'package:save_later/config/app_constants.dart';


void showNoUrlDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NeoBox(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          borderRadius: AppDimensions.radiusMd,
          borderWidth: 3,
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
                  onPressed: () => Navigator.of(context).pop(),
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
      );
    },
  );
}
