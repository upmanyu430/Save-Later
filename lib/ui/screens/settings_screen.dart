import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:save_later/config/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/url_launcher.dart';
import '../widgets/backup_restore_modal.dart';
import '../widgets/coming_soon_modal.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/home_headline_modal.dart';
import '../widgets/language_picker_modal.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    ref.read(appSettingsProvider.notifier).ensureLoaded();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion =
          packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';
      _buildNumber =
          packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : '1';
    });
  }

  void _triggerHapticIfEnabled() {
    if (ref.read(appSettingsProvider).hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _toggleDarkMode(bool enabled) {
    _triggerHapticIfEnabled();
    ref.read(appSettingsProvider.notifier).setDarkMode(enabled);
  }

  Future<void> _openUrl(String url) async {
    _triggerHapticIfEnabled();
    await openUrl(url, context: context);
  }

  Future<void> _sendFeedback() async {
    _triggerHapticIfEnabled();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${AppConfig.appName} Feedback',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.couldNotOpenEmailClient),
          ),
        );
      }
    }
  }

  Future<void> _copyUserId(String userId) async {
    _triggerHapticIfEnabled();
    if (userId.isEmpty) {
      await ref.read(appSettingsProvider.notifier).ensureLoaded();
    }
    final resolvedId = ref.read(appSettingsProvider).userId;
    await Clipboard.setData(ClipboardData(text: resolvedId));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.userIdCopied)),
    );
  }

  Future<void> _deleteData(BuildContext ctx) async {
    _triggerHapticIfEnabled();
    final l10n = AppLocalizations.of(ctx)!;
    final confirm = await DeleteConfirmationDialog.show(
      context: ctx,
      title: l10n.deleteAllDataTitle,
      message: l10n.deleteAllDataConfirmation,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
    );

    if (confirm == true) {
      final repo = ref.read(repositoryProvider);
      final isar = await repo.db;
      await isar.writeTxn(() async {
        await isar.clear();
      });

      ref.invalidate(collectionsProvider);
      ref.invalidate(allCollectionsProvider);
      ref.invalidate(singleCollectionProvider);
      ref.invalidate(subCollectionsProvider);
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      ref.invalidate(collectionBookmarksProvider);
      ref.invalidate(allTagsProvider);
      ref.invalidate(savingBookmarkIdsProvider);
      ref.invalidate(refreshingBookmarkIdsProvider);

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.allDataDeleted)),
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupedSection(BuildContext context, List<Widget> rows) {
    final colors = context.appColors;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            thickness: 1,
            color: colors.divider,
          ),
        );
      }
    }

    return NeoBox(
      padding: EdgeInsets.zero,
      borderRadius: AppDimensions.radiusXxl,
      borderWidth: AppDimensions.borderWidthMd,
      color: colors.card,
      borderColor: colors.border,
      shadowColor: colors.shadow,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusXxl - AppDimensions.borderWidthMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget icon,
    required Widget trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    final colors = context.appColors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppDimensions.paddingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingSm),
            trailing,
          ],
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: content,
      ),
    );
  }

  Widget _buildIconContainer(
    BuildContext context,
    IconData icon, {
    Color? bgColor,
    Color? iconColor,
  }) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor ?? colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.animationMedium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: Icon(
          icon,
          key: ValueKey<IconData>(icon),
          color: iconColor ?? colors.textPrimary,
          size: AppDimensions.iconSizeMd,
        ),
      ),
    );
  }

  Widget _buildRateBadgeIcon(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.onAccent,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.star_rounded,
        color: colors.onAccent,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final currentHeadline = settings.customHomeHeadline ?? l10n.saveNowFindAnytime;
    final headlinePreview = currentHeadline.replaceAll(RegExp(r'\s*\n\s*'), ' ');

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLg,
                vertical: AppDimensions.paddingLg,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: NeoButton(
                        onPressed: () {
                          context.pop();
                        },
                        padding: EdgeInsets.zero,
                        color: colors.card,
                        borderRadius: AppDimensions.radiusMd,
                        borderWidth: AppDimensions.borderWidthMd,
                        child: Icon(
                          Icons.arrow_back,
                          size: AppDimensions.iconSizeMd,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    l10n.settings,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.paddingLg,
                  AppDimensions.paddingSm,
                  AppDimensions.paddingLg,
                  AppDimensions.paddingSm + bottomInset,
                ),
                children: [
                  _buildSectionHeader(context, l10n.preferences),
                  _buildGroupedSection(
                    context,
                    [
                      _buildSettingRow(
                        context: context,
                        title: l10n.hapticFeedback,
                        subtitle: l10n.hapticFeedbackSubtitle,
                        icon: _buildIconContainer(context, Icons.bolt),
                        trailing: CupertinoSwitch(
                          value: settings.hapticFeedback,
                          onChanged: settingsNotifier.setHapticFeedback,
                          activeTrackColor: const Color(0xFF26D5A8),
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.darkMode,
                        subtitle: l10n.darkModeSubtitle,
                        icon: _buildIconContainer(
                          context,
                          settings.darkMode
                              ? Icons.nightlight_outlined
                              : Icons.wb_sunny_outlined,
                        ),
                        onTap: () => _toggleDarkMode(!settings.darkMode),
                        trailing: CupertinoSwitch(
                          value: settings.darkMode,
                          onChanged: _toggleDarkMode,
                          activeTrackColor: const Color(0xFF26D5A8),
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.language,
                        subtitle: languageDisplayName(settings.languageCode),
                        icon: _buildIconContainer(context, Icons.language),
                        onTap: () {
                          _triggerHapticIfEnabled();
                          LanguagePickerModal.show(context);
                        },
                        trailing: Icon(
                          Icons.open_in_new,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.homeHeadline,
                        subtitle: headlinePreview,
                        icon: _buildIconContainer(context, Icons.home_outlined),
                        onTap: () {
                          _triggerHapticIfEnabled();
                          HomeHeadlineModal.show(
                            context,
                            currentHeadline: currentHeadline,
                          );
                        },
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.newSaveReminders,
                        subtitle: l10n.newSaveRemindersSubtitle,
                        icon: _buildIconContainer(
                          context,
                          Icons.notifications_none,
                        ),
                        trailing: CupertinoSwitch(
                          value: settings.newSaveReminders,
                          onChanged: settingsNotifier.setNewSaveReminders,
                          activeTrackColor: const Color(0xFF26D5A8),
                        ),
                      ),
                    ],
                  ),

                  _buildSectionHeader(context, l10n.dataAndStorage),
                  _buildGroupedSection(
                    context,
                    [
                      _buildSettingRow(
                        context: context,
                        title: l10n.cloudSync,
                        subtitle: l10n.cloudSyncSubtitle,
                        icon: _buildIconContainer(context, Icons.cloud_outlined),
                        onTap: () {
                          _triggerHapticIfEnabled();
                          ComingSoonModal.show(
                            context,
                            icon: Icons.cloud_outlined,
                            iconBackgroundColor: AppTheme.secondary,
                            title: l10n.cloudSyncComingSoonTitle,
                            body: l10n.cloudSyncComingSoonBody,
                          );
                        },
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.backupAndRestore,
                        subtitle: l10n.backupAndRestoreSubtitle,
                        icon: _buildIconContainer(
                          context,
                          Icons.inventory_2_outlined,
                        ),
                        onTap: () {
                          _triggerHapticIfEnabled();
                          BackupRestoreModal.show(context);
                        },
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  _buildSectionHeader(context, l10n.support),
                  _buildGroupedSection(
                    context,
                    [
                      _buildSettingRow(
                        context: context,
                        title: l10n.howTo,
                        subtitle: l10n.howToSubtitle(AppConfig.appName),
                        icon: _buildIconContainer(context, Icons.book_outlined),
                        onTap: () => _openUrl(AppConfig.howToUrl),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.sendFeedback,
                        subtitle: l10n.sendFeedbackSubtitle(AppConfig.appName),
                        icon: _buildIconContainer(
                          context,
                          Icons.chat_bubble_outline,
                        ),
                        onTap: _sendFeedback,
                        trailing: Icon(
                          Icons.open_in_new,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.privacyPolicy,
                        subtitle: null,
                        icon: _buildIconContainer(context, Icons.lock_outline),
                        onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                        trailing: Icon(
                          Icons.open_in_new,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.termsOfService,
                        subtitle: null,
                        icon: _buildIconContainer(
                          context,
                          Icons.description_outlined,
                        ),
                        onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                        trailing: Icon(
                          Icons.open_in_new,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  _buildSectionHeader(context, l10n.account),
                  _buildGroupedSection(
                    context,
                    [
                      _buildSettingRow(
                        context: context,
                        title: l10n.rateAppTitle(AppConfig.appName),
                        subtitle: l10n.rateAppSubtitle(AppConfig.appName),
                        icon: _buildRateBadgeIcon(context),
                        onTap: () {
                          _triggerHapticIfEnabled();
                          ComingSoonModal.show(
                            context,
                            icon: Icons.star_rounded,
                            iconBackgroundColor: AppTheme.accent,
                            title: l10n.rateAppComingSoonTitle,
                            body: l10n.rateAppComingSoonBody(AppConfig.appName),
                          );
                        },
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.textSecondary,
                        ),
                      ),
                      _buildSettingRow(
                        context: context,
                        title: l10n.deleteAllData,
                        subtitle: l10n.deleteAllDataSubtitle,
                        titleColor: colors.danger,
                        icon: _buildIconContainer(
                          context,
                          Icons.delete_outline,
                          bgColor: colors.dangerSurface,
                          iconColor: colors.danger,
                        ),
                        onTap: () => _deleteData(context),
                        trailing: const SizedBox.shrink(),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.paddingXl),
                  Center(
                    child: Text(
                      l10n.versionWithBuildLabel(_appVersion, _buildNumber),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => _copyUserId(settings.userId),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMd,
                          vertical: AppDimensions.paddingSm,
                        ),
                      ),
                      child: Text(
                        l10n.copyUserId,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
