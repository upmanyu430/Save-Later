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

process_file('lib/ui/widgets/bookmark_radial_menu.dart', [
    ("void executeSelected() {\n    if (_selectedIndex != -1) {\n      widget.actions[_selectedIndex].onTap();\n    }",
     "void executeSelected() {\n    if (_selectedIndex != -1) {\n      HapticFeedback.lightImpact();\n      widget.actions[_selectedIndex].onTap();\n    }"),
    ("            onTap: widget.onClose,", "            onTap: () { HapticFeedback.lightImpact(); widget.onClose(); },")
])

