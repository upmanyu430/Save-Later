import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../providers/app_settings_provider.dart';
import '../../theme/app_theme.dart';
import 'app_modal_sheet.dart';
import 'neo_button.dart';

class LanguageOption {
  final String code;
  final String nativeName;
  final String englishName;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });
}

const List<LanguageOption> kLanguageOptions = [
  LanguageOption(code: 'en', nativeName: 'English', englishName: 'English'),
  LanguageOption(code: 'es', nativeName: 'Español', englishName: 'Spanish'),
  LanguageOption(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
  LanguageOption(code: 'fr', nativeName: 'Français', englishName: 'French'),
  LanguageOption(code: 'de', nativeName: 'Deutsch', englishName: 'German'),
  LanguageOption(code: 'ja', nativeName: '日本語', englishName: 'Japanese'),
];

String languageDisplayName(String code) {
  for (final option in kLanguageOptions) {
    if (option.code == code) return option.nativeName;
  }
  return 'English';
}

class LanguagePickerModal extends ConsumerWidget {
  const LanguagePickerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => const LanguagePickerModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final currentCode = ref.watch(appSettingsProvider).languageCode;
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
            AppDimensions.paddingLg + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.chooseLanguage,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppDimensions.dialogHeaderButtonSize,
                    height: AppDimensions.dialogHeaderButtonSize,
                    child: NeoButton(
                      onPressed: () => dismissAppModalSheet(context),
                      padding: EdgeInsets.zero,
                      color: colors.card,
                      borderRadius: AppDimensions.radiusSm,
                      borderWidth: AppDimensions.borderWidthSm,
                      child: Icon(
                        Icons.close,
                        size: AppDimensions.dialogHeaderIconSize,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMd),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kLanguageOptions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.paddingSm),
                  itemBuilder: (context, index) {
                    final option = kLanguageOptions[index];
                    final isSelected = option.code == currentCode;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        onTap: () async {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .setLanguageCode(option.code);
                          if (context.mounted) {
                            dismissAppModalSheet(context);
                          }
                        },
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMd,
                            vertical: AppDimensions.paddingSm,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.selectedSurface
                                : colors.surfaceSubtle,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusMd),
                            border: Border.all(
                              color: isSelected
                                  ? colors.selectedBorder
                                  : colors.divider,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.nativeName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    if (option.englishName !=
                                        option.nativeName) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        option.englishName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: colors.textPrimary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
