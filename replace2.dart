import 'dart:io';
void main() {
  var file = File('lib/providers/providers.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'ref.invalidate(bookmarksProvider);',
    'ref.invalidate(bookmarksProvider);\n      ref.invalidate(unsortedBookmarksProvider);'
  );
  file.writeAsStringSync(content);
}
