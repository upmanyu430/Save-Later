import os

def process_file(path, replacements):
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

# home_screen.dart
process_file('lib/ui/screens/home_screen.dart', [
    ("onTap: () => context.push('/settings'),", "onTap: () { HapticFeedback.lightImpact(); context.push('/settings'); },"),
    ("onTap: _showAddCollectionModal,", "onTap: () { HapticFeedback.lightImpact(); _showAddCollectionModal(); },"),
    ("onTap: () => context.push('/search'),", "onTap: () { HapticFeedback.lightImpact(); context.push('/search'); },"),
    ("onPressed: () async {", "onPressed: () async { HapticFeedback.lightImpact();"),
    ("onPressed: _quickSave,", "onPressed: () { HapticFeedback.lightImpact(); _quickSave(); },"),
    ("onTap: () => context.push('/unsorted'),", "onTap: () { HapticFeedback.lightImpact(); context.push('/unsorted'); },"),
    ("onTap: () => context.push('/collection/\', extra: col),", "onTap: () { HapticFeedback.lightImpact(); context.push('/collection/\', extra: col); },")
])

# bookmark_grid_item.dart
process_file('lib/ui/widgets/bookmark_grid_item.dart', [
    ("      onTap: () {", "      onTap: () {\n        HapticFeedback.lightImpact();")
])

# folder_box.dart
process_file('lib/ui/widgets/folder_box.dart', [
    ("      onTap: onTap,", "      onTap: () { HapticFeedback.lightImpact(); onTap(); },")
])

# collection_detail_screen.dart
process_file('lib/ui/screens/collection_detail_screen.dart', [
    ("    return InkWell(\n      onTap: onTap,", "    return InkWell(\n      onTap: () { HapticFeedback.lightImpact(); onTap(); },"),
    ("    return GestureDetector(\n      onTap: onTap,", "    return GestureDetector(\n      onTap: onTap == null ? null : () { HapticFeedback.lightImpact(); onTap(); },"),
    ("onTap: () => context.pop(),", "onTap: () { HapticFeedback.lightImpact(); context.pop(); },"),
    ("onTap: () => context.push('/review', extra: widget.collection),", "onTap: () { HapticFeedback.lightImpact(); context.push('/review', extra: widget.collection); },"),
    ("onTap: () => _showMenuModal(context),", "onTap: () { HapticFeedback.lightImpact(); _showMenuModal(context); },")
])

