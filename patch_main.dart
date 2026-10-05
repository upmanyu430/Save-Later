import 'dart:io';
void main() {
  var file = File('lib/main.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    'GoRoute(\n      path: \\'/review\\',',
    'GoRoute(\n      path: \\'/unsorted\\',\n      builder: (context, state) => const CollectionDetailScreen(collectionId: null, collection: null),\n    ),\n    GoRoute(\n      path: \\'/review\\','
  );
  file.writeAsStringSync(content);
}
