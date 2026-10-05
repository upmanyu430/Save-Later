import re

with open('lib/ui/screens/collection_detail_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update onTap call to pass ref
content = content.replace('onTap: () => _showMenuModal(context),', 'onTap: () => _showMenuModal(context, ref),')

# Replace the entire _showMenuModal function
old_modal_pattern = r'void _showMenuModal\(BuildContext context\)\s*\{[\s\S]*?(?=\s+@override\s+Widget build)'

new_modal = '''void _showMenuModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 3),
            left: BorderSide(color: AppTheme.border, width: 3),
            right: BorderSide(color: AppTheme.border, width: 3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            
            // Add Link
            _buildMenuItem(
              icon: Icons.add,
              title: 'Add Link',
              onTap: () {
                Navigator.pop(ctx);
                _showAddLinkModal(context, ref);
              },
            ),
            _buildDivider(),
            
            // Select Links
            _buildMenuItem(
              icon: Icons.check_box_outlined,
              title: 'Select Links',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select mode coming soon!')),
                );
              },
            ),
            _buildDivider(),

            // Create Sub-collection
            _buildMenuItem(
              icon: Icons.create_new_folder_outlined,
              title: 'Create Sub-collection',
              trailing: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFFFD166), size: 28),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sub-collections are a premium feature!')),
                );
              },
            ),
            _buildDivider(),

            // Share Collection
            _buildMenuItem(
              icon: Icons.share_outlined,
              title: 'Share Collection',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing collection...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppTheme.border),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.border,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        height: 2,
        color: AppTheme.border,
      ),
    );
  }
'''

content = re.sub(old_modal_pattern, new_modal, content)

with open('lib/ui/screens/collection_detail_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
