import re

filepath = 'lib/ui/screens/home_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if missing
if "'../widgets/no_url_dialog.dart'" not in content:
    content = content.replace("import '../widgets/neo_button.dart';", "import '../widgets/neo_button.dart';\nimport '../widgets/no_url_dialog.dart';")

old_block = '''  void _quickSave() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      // Basic validation
      if (!url.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid URL starting with http/https')),
        );
        return;
      }
      ref.read(bookmarkNotifierProvider.notifier).quickSave(url);
      _urlController.clear();
      FocusScope.of(context).unfocus();
    }
  }'''

new_block = '''  void _quickSave() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      showNoUrlDialog(context);
      return;
    }
    
    // Basic validation
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL starting with http/https')),
      );
      return;
    }
    ref.read(bookmarkNotifierProvider.notifier).quickSave(url);
    _urlController.clear();
    FocusScope.of(context).unfocus();
  }'''

if old_block in content:
    content = content.replace(old_block, new_block)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched home_screen.dart successfully via literal string replacement")
else:
    print("Could not find literal block")
