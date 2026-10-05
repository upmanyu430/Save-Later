import 'dart:io';
void main() {
  var file = File('lib/providers/providers.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    'final collectionBookmarksProvider',
    'final unsortedBookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {\n  final repo = ref.watch(repositoryProvider);\n  return repo.getUnsortedBookmarks();\n});\n\nfinal collectionBookmarksProvider'
  );
  file.writeAsStringSync(content);
}
