import 'dart:io';
void main() {
  var file = File('lib/ui/screens/home_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    'return FolderBox(\n                            title: \\'Unsorted\\',\n                            itemCountText: \\'View items\\',\n                            folderColor: Colors.grey.shade400,\n                            onTap: () => context.push(\\'/review\\'),\n                          );',
    'return Consumer(\n                            builder: (context, ref, _) {\n                              final countAsync = ref.watch(unsortedBookmarksProvider);\n                              final count = countAsync.valueOrNull?.length ?? 0;\n                              return FolderBox(\n                                title: \\'Unsorted\\',\n                                itemCountText: \\'\ items\\',\n                                folderColor: Colors.grey.shade400,\n                                onTap: () => context.push(\\'/unsorted\\'),\n                              );\n                            }\n                          );'
  );
  file.writeAsStringSync(content);
}
