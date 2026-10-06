import os

def process_file(path, replacements):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content
    for old, new in replacements:
        content = content.replace(old, new)
    if content != original:
        if 'HapticFeedback' in content and 'flutter/services.dart' not in content:
            content = "import 'package:flutter/services.dart';\n" + content
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {path}")

# bookmark_detail_screen.dart
process_file('lib/ui/screens/bookmark_detail_screen.dart', [
    ("onTap: () {", "onTap: () {\n                                    HapticFeedback.lightImpact();"),
    ("onTap: () async {", "onTap: () async {\n                                    HapticFeedback.lightImpact();"),
    ("onTap: () => openUrl(bookmark.url),", "onTap: () { HapticFeedback.lightImpact(); openUrl(bookmark.url); },"),
    ("onTap: () => _removeTag(tag),", "onTap: () { HapticFeedback.lightImpact(); _removeTag(tag); },"),
    ("onTap: _showAddTagModal,", "onTap: () { HapticFeedback.lightImpact(); _showAddTagModal(); },"),
    ("onTap: () => context.pop(),", "onTap: () { HapticFeedback.lightImpact(); context.pop(); },"),
    ("onTap: () => Navigator.pop(ctx),", "onTap: () { HapticFeedback.lightImpact(); Navigator.pop(ctx); },"),
    ("onTap: onTap,", "onTap: () { HapticFeedback.lightImpact(); onTap(); },")
])

# review_mode_screen.dart
process_file('lib/ui/screens/review_mode_screen.dart', [
    ("onTap: () {", "onTap: () {\n                                    HapticFeedback.lightImpact();"),
    ("onPressed: () {", "onPressed: () {\n                                    HapticFeedback.lightImpact();"),
    ("onTap: () => context.pop(),", "onTap: () { HapticFeedback.lightImpact(); context.pop(); },"),
    ("onPressed: () => context.go('/'),", "onPressed: () { HapticFeedback.lightImpact(); context.go('/'); },")
])

# search_screen.dart
process_file('lib/ui/screens/search_screen.dart', [
    ("onTap: () {", "onTap: () {\n                                    HapticFeedback.lightImpact();"),
    ("onTap: () => context.pop(),", "onTap: () { HapticFeedback.lightImpact(); context.pop(); },"),
    ("onTap: () => context.push('/bookmark/\', extra: bookmark),", "onTap: () { HapticFeedback.lightImpact(); context.push('/bookmark/\', extra: bookmark); },")
])

# settings_screen.dart
process_file('lib/ui/screens/settings_screen.dart', [
    ("onTap: () {", "onTap: () {\n                                    HapticFeedback.lightImpact();"),
    ("onTap: () => Navigator.pop(context),", "onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },"),
    ("onPressed: () => Navigator.pop(c, false),", "onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(c, false); },"),
    ("onPressed: () => Navigator.pop(c, true),", "onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(c, true); },"),
    ("onTap: _launchGithub,", "onTap: () { HapticFeedback.lightImpact(); _launchGithub(); },"),
    ("onTap: () => launchUrl(Uri.parse('mailto:support@savelater.com')),", "onTap: () { HapticFeedback.lightImpact(); launchUrl(Uri.parse('mailto:support@savelater.com')); },")
])

# collection_editor_modal.dart
process_file('lib/ui/widgets/collection_editor_modal.dart', [
    ("onTap: () {", "onTap: () {\n                                    HapticFeedback.lightImpact();"),
    ("onPressed: _nameController.text.isNotEmpty ? _save : () {},", "onPressed: _nameController.text.isNotEmpty ? () { HapticFeedback.lightImpact(); _save(); } : () {},"),
    ("onTap: () => Navigator.of(context).pop(),", "onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },")
])

# no_url_dialog.dart
process_file('lib/ui/widgets/no_url_dialog.dart', [
    ("onPressed: () => Navigator.of(context).pop(),", "onPressed: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },")
])

