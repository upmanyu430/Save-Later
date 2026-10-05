import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/bookmark.dart';
import '../models/collection.dart';

class IsarRepository {
  late Future<Isar> db;

  IsarRepository() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [BookmarkSchema, BookmarkCollectionSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  // --- Collection Methods ---
  Future<List<BookmarkCollection>> getCollections() async {
    final isar = await db;
    return await isar.bookmarkCollections.where().findAll();
  }

  Future<void> addCollection(BookmarkCollection collection) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.bookmarkCollections.put(collection);
    });
  }

  // --- Bookmark Methods ---
  Future<List<Bookmark>> getBookmarks() async {
    final isar = await db;
    return await isar.bookmarks.where().sortByCreatedAtDesc().findAll();
  }

  Future<List<Bookmark>> getBookmarksByCollection(Id collectionId) async {
    final isar = await db;
    // Assuming the link has been setup properly
    // This fetches bookmarks linking to the collection
    return await isar.bookmarks
        .filter()
        .collection((q) => q.idEqualTo(collectionId))
        .sortByCreatedAtDesc()
        .findAll();
  }

  Future<void> addBookmark(Bookmark bookmark) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.bookmarks.put(bookmark);
      await bookmark.collection.save();
    });
  }

  Future<void> updateBookmark(Bookmark bookmark) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.bookmarks.put(bookmark);
    });
  }
  
  Future<void> deleteBookmark(Id id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.bookmarks.delete(id);
    });
  }
}
