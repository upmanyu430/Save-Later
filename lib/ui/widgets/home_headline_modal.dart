import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../providers/app_settings_provider.dart';
import '../../theme/app_theme.dart';
import 'app_modal_sheet.dart';
import 'neo_button.dart';

class HomeHeadlineModal extends ConsumerStatefulWidget {
  final String initialHeadline;

  const HomeHeadlineModal({
    super.key,
    required this.initialHeadline,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentHeadline,
  }) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => HomeHeadlineModal(initialHeadline: currentHeadline),
    );
  }

  @override
  ConsumerState<HomeHeadlineModal> createState() => _HomeHeadlineModalState();
}

class _HomeHeadlineModalState extends ConsumerState<HomeHeadlineModal>
    with AppModalDeferredFocusMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialHeadline);
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scheduleDeferredFocus(_focusNode);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(appSettingsProvider.notifier)
        .setHomeHeadline(_controller.text);
    if (mounted) {
      dismissAppModalSheet(context);
    }
  }

  Future<void> _resetToDefault() async {
    await ref.read(appSettingsProvider.notifier).setHomeHeadline(null);
    if (mounted) {
      dismissAppModalSheet(context);
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingLg,
                AppDimensions.paddingLg,
                AppDimensions.paddingLg,
                AppDimensions.paddingMd,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.editHomeHeadline,
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
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: colors.border,
                        width: AppDimensions.borderWidthSm,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMd,
                      vertical: AppDimensions.paddingSm,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 3,
                      minLines: 2,
                      maxLength: 80,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.homeHeadlineHint,
                        hintStyle: TextStyle(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        counterStyle: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.divider),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.paddingLg,
                AppDimensions.paddingMd,
                AppDimensions.paddingLg,
                AppDimensions.modalActionButtonBottomPadding + bottomInset,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppDimensions.modalActionButtonHeight,
                      child: NeoButton(
                        onPressed: _resetToDefault,
                        color: colors.card,
                        borderRadius: AppDimensions.radiusMd,
                        borderWidth: AppDimensions.borderWidthMd,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l10n.resetToDefault,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMd),
                  Expanded(
                    child: SizedBox(
                      height: AppDimensions.modalActionButtonHeight,
                      child: NeoButton(
                        onPressed: _save,
                        color: AppTheme.accent,
                        borderColor: colors.onAccent,
                        shadowColor: colors.shadow,
                        borderRadius: AppDimensions.radiusMd,
                        borderWidth: AppDimensions.borderWidthMd,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.save,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colors.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
