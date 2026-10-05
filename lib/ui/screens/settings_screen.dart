import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../widgets/neo_box.dart';
import '../../providers/providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/app_config.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  bool _newSaveReminders = true;
  bool _isLoading = true;
  String _appVersion = 'Version 1.0.0';

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
      _appVersion = 'Version ${packageInfo.version}';
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
    if (_hapticFeedback) HapticFeedback.selectionClick();
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch \$url: \$e');
    }
  }

  Future<void> _sendFeedback() async {
    if (_hapticFeedback) HapticFeedback.selectionClick();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=${AppConfig.appName} Feedback',
    );
    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  Future<void> _deleteData(BuildContext ctx, WidgetRef ref) async {
    if (_hapticFeedback) HapticFeedback.selectionClick();
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
            'This will permanently erase all saves, collections, and tags on this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
          const SnackBar(content: Text('All data deleted successfully.')),
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
          borderRadius: 8,
          borderWidth: 2.5,
          color: AppTheme.cardColor,
          child: Row(
            children: [
              icon,
              const SizedBox(width: 16),
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
              const SizedBox(width: 8),
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
      child: Icon(icon, color: iconColor, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.background);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        if (_hapticFeedback) HapticFeedback.selectionClick();
                        context.pop();
                      },
                      child: NeoBox(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 8,
                        borderWidth: 2.5,
                        child: const Icon(Icons.arrow_back, size: 28),
                      ),
                    ),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  _buildSectionHeader('PREFERENCES'),
                  _buildSettingTile(
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate for actions and selections',
                    icon: _buildIconContainer(Icons.bolt),
                    trailing: CupertinoSwitch(
                      value: _hapticFeedback,
                      onChanged: _setHaptic,
                      activeColor: const Color(0xFF26D5A8), // Teal from image
                    ),
                  ),
                  _buildSettingTile(
                    title: 'New Save Reminders',
                    subtitle: 'Gentle reminders to review unseen saves',
                    icon: _buildIconContainer(Icons.notifications_none),
                    trailing: CupertinoSwitch(
                      value: _newSaveReminders,
                      onChanged: _setReminders,
                      activeColor: const Color(0xFF26D5A8), // Teal from image
                    ),
                  ),

                  _buildSectionHeader('SUPPORT'),
                  _buildSettingTile(
                    title: 'How To',
                    subtitle: 'Quick guides for getting more from ${AppConfig.appName}',
                    icon: _buildIconContainer(Icons.book_outlined),
                    onTap: () => _openUrl(AppConfig.howToUrl),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  ),
                  _buildSettingTile(
                    title: 'Send Feedback',
                    subtitle: 'Got a bug or idea? We\'d love to hear it!',
                    icon: _buildIconContainer(Icons.chat_bubble_outline),
                    onTap: _sendFeedback,
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: 'Privacy Policy',
                    subtitle: null,
                    icon: _buildIconContainer(Icons.lock_outline),
                    onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: 'Terms of Service',
                    subtitle: null,
                    icon: _buildIconContainer(Icons.description_outlined),
                    onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),

                  _buildSectionHeader('ACCOUNT'),
                  Consumer(
                    builder: (context, ref, _) {
                      return _buildSettingTile(
                        title: 'Delete All Data',
                        subtitle: 'Permanently erase all saves, collections, and tags on this device',
                        titleColor: Colors.pink.shade400,
                        icon: _buildIconContainer(Icons.delete_outline, bgColor: Colors.pink.shade50, iconColor: Colors.pink.shade400),
                        onTap: () => _deleteData(context, ref),
                        trailing: const SizedBox.shrink(),
                      );
                    }
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      _appVersion,
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

