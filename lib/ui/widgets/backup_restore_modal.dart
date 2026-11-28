import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_constants.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/netscape_bookmark_service.dart';
import 'app_modal_sheet.dart';
import 'neo_box.dart';
import 'neo_button.dart';

class BackupRestoreModal extends ConsumerStatefulWidget {
  const BackupRestoreModal({super.key});

  static Future<void> show(BuildContext context) {
    return showAppModalSheet<void>(
      context: context,
      builder: (_) => const BackupRestoreModal(),
    );
  }

  @override
  ConsumerState<BackupRestoreModal> createState() => _BackupRestoreModalState();
}

class _BackupRestoreModalState extends ConsumerState<BackupRestoreModal> {
  bool _isBusy = false;
  String? _statusMessage;

  Future<void> _exportBookmarks() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final haptics = ref.read(appSettingsProvider).hapticFeedback;
    if (haptics) HapticFeedback.lightImpact();

    setState(() {
      _isBusy = true;
      _statusMessage = l10n.exportingBookmarks;
    });

    try {
      final repo = ref.read(repositoryProvider);
      final collections = await repo.getAllCollections();
      final bookmarks = await repo.getBookmarks();

      final html = NetscapeBookmarkService.generateNetscapeHtml(
        collections: collections,
        bookmarks: bookmarks,
      );

      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final file = File('${tempDir.path}/save_later_bookmarks_$stamp.html');
      await file.writeAsString(html);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'Save Later Bookmarks Backup',
      );

      if (!mounted) return;
      dismissAppModalSheet(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupError(e.toString()))),
      );
    }
  }

  Future<void> _importBookmarks() async {
    if (_isBusy) return;
    final l10n = AppLocalizations.of(context)!;
    final haptics = ref.read(appSettingsProvider).hapticFeedback;
    if (haptics) HapticFeedback.lightImpact();

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['html', 'htm'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      setState(() {
        _isBusy = true;
        _statusMessage = l10n.importingBookmarks;
      });

      final file = picked.files.first;
      String htmlContent;
      if (file.bytes != null) {
        htmlContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        htmlContent = await File(file.path!).readAsString();
      } else {
        throw Exception('Empty file');
      }

      final repo = ref.read(repositoryProvider);
      final result = await NetscapeBookmarkService.importNetscapeHtml(
        htmlContent: htmlContent,
        repository: repo,
      );

      ref.invalidate(collectionsProvider);
      ref.invalidate(allCollectionsProvider);
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      ref.invalidate(collectionBookmarksProvider);
      ref.invalidate(subCollectionsProvider);
      ref.invalidate(allTagsProvider);

      if (!mounted) return;
      dismissAppModalSheet(context);
      final message = (result.importedCount == 0 && result.skippedCount == 0)
          ? l10n.importNoBookmarksFound
          : l10n.importSuccess(result.importedCount, result.skippedCount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupError(e.toString()))),
      );
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
                      l10n.backupAndRestore,
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
                      onPressed: _isBusy
                          ? null
                          : () => dismissAppModalSheet(context),
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
              const SizedBox(height: AppDimensions.paddingLg),
              if (_isBusy && _statusMessage != null) ...[
                NeoBox(
                  color: colors.surfaceSubtle,
                  borderWidth: AppDimensions.borderWidthSm,
                  shadowOffset: 0,
                  padding: const EdgeInsets.all(AppDimensions.paddingLg),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingMd),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _BackupActionCard(
                  icon: Icons.upload_file_outlined,
                  iconBgColor: AppTheme.accent,
                  title: l10n.exportBookmarks,
                  subtitle: l10n.exportBookmarksSubtitle,
                  onTap: _exportBookmarks,
                ),
                const SizedBox(height: AppDimensions.paddingMd),
                _BackupActionCard(
                  icon: Icons.download_outlined,
                  iconBgColor: AppTheme.secondary,
                  title: l10n.importBookmarks,
                  subtitle: l10n.importBookmarksSubtitle,
                  onTap: _importBookmarks,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BackupActionCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return NeoButton(
      onPressed: onTap,
      color: colors.card,
      borderWidth: AppDimensions.borderWidthMd,
      borderRadius: AppDimensions.radiusMd,
      padding: const EdgeInsets.all(AppDimensions.paddingMd),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.onAccent,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: colors.onAccent, size: 22),
          ),
          const SizedBox(width: AppDimensions.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSm),
          Icon(Icons.chevron_right, color: colors.textSecondary),
        ],
      ),
    );
  }
}
