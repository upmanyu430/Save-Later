import 'dart:io';

void main() {
  final file = File('lib/ui/screens/settings_screen.dart');
  final content = file.readAsStringSync();
  final index = content.indexOf('Widget _buildSettingTile({');
  if (index == -1) return;
  final newContent = content.substring(0, index) + '''Widget _buildSettingTile({
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
                    trailing: Switch(
                      value: _hapticFeedback,
                      onChanged: _setHaptic,
                      activeColor: Colors.tealAccent.shade400,
                      activeTrackColor: Colors.teal,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),
                  _buildSettingTile(
                    title: 'New Save Reminders',
                    subtitle: 'Gentle reminders to review unseen saves',
                    icon: _buildIconContainer(Icons.notifications_none),
                    trailing: Switch(
                      value: _newSaveReminders,
                      onChanged: _setReminders,
                      activeColor: Colors.tealAccent.shade400,
                      activeTrackColor: Colors.teal,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),

                  _buildSectionHeader('YOUR TUCKII DATA'),
                  _buildSettingTile(
                    title: 'Export Backup',
                    subtitle: 'Export a backup file you can save anywhere',
                    icon: _buildIconContainer(Icons.share_outlined),
                    onTap: _exportBackup,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.workspace_premium, color: Color(0xFFFFD166), size: 20),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.black54),
                      ],
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Restore from Backup',
                    subtitle: 'Restore from a Tuckii backup (.zip or .json)',
                    icon: _buildIconContainer(Icons.cloud_download_outlined),
                    onTap: _restoreBackup,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.workspace_premium, color: Color(0xFFFFD166), size: 20),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.black54),
                      ],
                    ),
                  ),

                  _buildSectionHeader('IMPORT FROM OTHER APPS'),
                  _buildSettingTile(
                    title: 'Import Bookmarks',
                    subtitle: 'From CSV, HTML, or JSON exports',
                    icon: _buildIconContainer(Icons.inbox_outlined),
                    onTap: _importBookmarks,
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  ),

                  _buildSectionHeader('SUPPORT'),
                  _buildSettingTile(
                    title: 'How To',
                    subtitle: 'Quick guides for getting more from Tuckii',
                    icon: _buildIconContainer(Icons.book_outlined),
                    onTap: () => _openUrl('https://example.com/howto'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  ),
                  _buildSettingTile(
                    title: 'Send Feedback',
                    subtitle: 'Got a bug or idea? We\\'d love to hear it!',
                    icon: _buildIconContainer(Icons.chat_bubble_outline),
                    onTap: _sendFeedback,
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: 'Privacy Policy',
                    subtitle: null,
                    icon: _buildIconContainer(Icons.lock_outline),
                    onTap: () => _openUrl('https://example.com/privacy'),
                    trailing: const Icon(Icons.open_in_new, color: Colors.black54, size: 20),
                  ),
                  _buildSettingTile(
                    title: 'Terms of Service',
                    subtitle: null,
                    icon: _buildIconContainer(Icons.description_outlined),
                    onTap: () => _openUrl('https://example.com/terms'),
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
                  const Center(
                    child: Text(
                      'Version 1.4.0',
                      style: TextStyle(
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
''';
  file.writeAsStringSync(newContent);
}
