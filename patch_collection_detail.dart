import 'dart:io';
void main() {
  var file = File('lib/ui/screens/collection_detail_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'final int collectionId;',
    'final int? collectionId;'
  ).replaceAll(
    'final BookmarkCollection collection;',
    'final BookmarkCollection? collection;'
  ).replaceAll(
    'final bookmarksAsync = ref.watch(collectionBookmarksProvider(collectionId));',
    'final bookmarksAsync = collectionId != null ? ref.watch(collectionBookmarksProvider(collectionId!)) : ref.watch(unsortedBookmarksProvider);'
  ).replaceAll(
    'title: Text(collection.name',
    'title: Text(collection?.name ?? "Unsorted"'
  ).replaceAll(
    'IconData(collection.iconCodePoint, fontFamily: collection.iconFontFamily)',
    'collection != null ? IconData(collection!.iconCodePoint, fontFamily: collection!.iconFontFamily) : Icons.inbox'
  ).replaceAll(
    'color: collection.color',
    'color: collection?.color ?? Colors.grey.shade400'
  ).replaceAll(
    'backgroundColor: collection.color',
    'backgroundColor: collection?.color ?? Colors.grey.shade400'
  ).replaceAll(
    'Text(collection.name',
    'Text(collection?.name ?? "Unsorted"'
  ).replaceAll(
    'collection: collection',
    'collection: collection'
  ).replaceAll(
    'ref.read(bookmarkNotifierProvider.notifier).quickSave(url, collection: collection);',
    'ref.read(bookmarkNotifierProvider.notifier).quickSave(url, collection: collection);'
  );
  file.writeAsStringSync(content);
}
