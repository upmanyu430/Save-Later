import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../widgets/neo_button.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../../providers/providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_config.dart';
import '../../utils/url_launcher.dart';
import 'package:save_later/config/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  bool _newSaveReminders = true;
  bool _isLoading = true;
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
      _newSaveReminders = prefs.getBool('newSaveReminders') ?? true;
      _appVersion = packageInfo.version;
      _isLoading = false;
    });
  }

  Future<void> _setHaptic(bool value) async {
    if (value) HapticFeedback.lightImpact();
    setState(() => _hapticFeedback = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', value);
  }

  Future<void> _setReminders(bool value) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    setState(() => _newSaveReminders = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('newSaveReminders', value);
  }

  Future<void> _openUrl(String url) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    await openUrl(url, context: context);
  }

  Future<void> _sendFeedback() async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
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
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotOpenEmailClient)),
        );
      }
    }
  }

  Future<void> _deleteData(BuildContext ctx, WidgetRef ref) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(ctx)!;
    final confirm = await DeleteConfirmationDialog.show(
      context: ctx,
      title: l10n.deleteAllDataTitle,
      message: l10n.deleteAllDataConfirmation,
      confirmText: l10n.delete,
      cancelText: l10n.cancel,
    );

    if (confirm == true) {
      // Clear data logic
      final repo = ref.read(repositoryProvider);
      final isar = await repo.db;
      await isar.writeTxn(() async {
        await isar.clear();
      });
      ref.invalidate(collectionsProvider);
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(l10n.allDataDeleted)),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required Widget icon,
    required Widget trailing,
    VoidCallback? onTap,
    Color titleColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NeoBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: AppDimensions.radiusSm,
          borderWidth: AppDimensions.borderWidthMd,
          color: AppTheme.cardColor,
          child: Row(
            children: [
              icon,
              const SizedBox(width: AppDimensions.paddingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingSm),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, {Color bgColor = const Color(0xFFF0F0F0), Color iconColor = Colors.black87}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: AppDimensions.iconSizeMd),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.background);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.maxContentWidth,
            ),
            child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXl, vertical: AppDimensions.paddingLg),
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
                          if (_hapticFeedback) HapticFeedback.lightImpact();
                          context.pop();
                        },
                        padding: EdgeInsets.zero,
                        color: AppTheme.cardColor,
                        borderRadius: AppDimensions.radiusSm,
                        borderWidth: AppDimensions.borderWidthMd,
                        child: const Icon(Icons.arrow_back, size: AppDimensions.iconSizeLg),
                      ),
                    ),
                  ),
                  Text(
                    l10n.settings,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.paddingXl,
                  AppDimensions.paddingSm,
                  AppDimensions.paddingXl,
                  AppDimensions.paddingSm + bottomInset,
                ),
                children: [
                  _buildSectionHeader(l10n.preferences),
                  _buildSettingTile(
                    title: l10n.hapticFeedback,
                    subtitle: l10n.hapticFeedbackSubtitle,
                    icon: _buildIconContainer(Icons.bolt),
                    trailing: CupertinoSwitch(
                      value: _hapticFeedback,
                      onChanged: _setHaptic,
                      activeTrackColor: const Color(0xFF26D5A8), // Teal from image
                    ),
                  ),
                  _buildSettingTile(
                    title: l10n.newSaveReminders,
                    subtitle: l10n.newSaveRemindersSubtitle,
                    icon: _buildIconContainer(Icons.notifications_none),
                    trailing: CupertinoSwitch(
                      value: _newSaveReminders,
                      onChanged: _setReminders,
                      activeTrackColor: const Color(0xFF26D5A8), // Teal from image
                    ),
                  ),

                  _buildSectionHeader(l10n.support),
                  _buildSettingTile(
                    title: l10n.howTo,
                    subtitle: l10n.howToSubtitle(AppConfig.appName),
                    icon: _buildIconContainer(Icons.book_outlined),
                    onTap: () => _openUrl(AppConfig.howToUrl),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  ),
                  _buildSettingTile(
                    title: l10n.sendFeedback,
                    subtitle: l10n.sendFeedbackSubtitle,
                    icon: _buildIconContainer(Icons.chat_bubble_outline),
                    onTap: _sendFeedback,
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: l10n.privacyPolicy,
                    subtitle: null,
                    icon: _buildIconContainer(Icons.lock_outline),
                    onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: l10n.termsOfService,
                    subtitle: null,
                    icon: _buildIconContainer(Icons.description_outlined),
                    onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),

                  _buildSectionHeader(l10n.account),
                  Consumer(
                    builder: (context, ref, _) {
                      return _buildSettingTile(
                        title: l10n.deleteAllData,
                        subtitle: l10n.deleteAllDataSubtitle,
                        titleColor: Colors.pink.shade400,
                        icon: _buildIconContainer(Icons.delete_outline, bgColor: Colors.pink.shade50, iconColor: Colors.pink.shade400),
                        onTap: () => _deleteData(context, ref),
                        trailing: const SizedBox.shrink(),
                      );
                    }
                  ),

                  const SizedBox(height: AppDimensions.paddingXl),
                  Center(
                    child: Text(
                      l10n.versionLabel(_appVersion),
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}

