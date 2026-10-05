import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../models/bookmark.dart';
import '../models/collection.dart';
import '../repositories/isar_repository.dart';

final repositoryProvider = Provider<IsarRepository>((ref) {
  return IsarRepository();
});

final collectionsProvider =
    FutureProvider<List<BookmarkCollection>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getCollections();
});

final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getBookmarks();
});

final unsortedBookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getUnsortedBookmarks();
});

final collectionBookmarksProvider =
    FutureProvider.family<List<Bookmark>, int>((ref, collectionId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getBookmarksByCollection(collectionId);
});

// A notifier to handle adding a bookmark and fetching metadata
class BookmarkNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  BookmarkNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> quickSave(String url, {BookmarkCollection? collection}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);

      // Attempt to fetch metadata
      String? title;
      String? description;
      String? imageUrl;
      String? sourceDomain;

      try {
        if (!url.startsWith('http://') && !url.startsWith('https://')) { url = 'https://' + url; }
          final uri = Uri.parse(url);
        sourceDomain = uri.host;
        var data = await MetadataFetch.extract(url);
        if (data != null) {
          title = data.title;
          description = data.description;
          imageUrl = data.image;
        }
      } catch (e) {
        // Fallback or ignore
        print('Error fetching metadata: $e');
      }

      final bookmark = Bookmark()
        ..url = url
        ..title = title ?? url
        ..description = description
        ..imageUrl = imageUrl
        ..sourceDomain = sourceDomain
        ..createdAt = DateTime.now()
        ..isRead = false;

      if (collection != null) { bookmark.collection.value = collection; } await repo.addBookmark(bookmark); if (collection != null) { ref.invalidate(collectionBookmarksProvider(collection.id)); }

      // Invalidate the provider to refresh the UI
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTag(Bookmark bookmark, String tag) async {
    final repo = ref.read(repositoryProvider);
    if (!bookmark.tags.contains(tag)) {
      bookmark.tags = List.from(bookmark.tags)..add(tag);
      await repo.updateBookmark(bookmark);
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      if (bookmark.collection.value != null)
        ref.invalidate(
            collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> refreshMetadata(Bookmark bookmark) async {
      try {
        String url = bookmark.url;
        if (!url.startsWith('http://') && !url.startsWith('https://')) { url = 'https://' + url; }
        bookmark.url = url; // Update url
        bookmark.sourceDomain = Uri.parse(url).host;
        var data = await MetadataFetch.extract(url);
        if (data != null) {
          bookmark.title = data.title ?? bookmark.title;
          bookmark.description = data.description ?? bookmark.description;
          bookmark.imageUrl = data.image ?? bookmark.imageUrl;
        }
        await ref.read(repositoryProvider).updateBookmark(bookmark);
        ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
        if (bookmark.collection.value != null) {
          ref.invalidate(collectionBookmarksProvider(bookmark.collection.value!.id));
        }
      } catch (e) {
        print('Error refreshing metadata: $e');
      }
    }

    Future<void> removeTag(Bookmark bookmark, String tag) async {
    final repo = ref.read(repositoryProvider);
    bookmark.tags = List.from(bookmark.tags)..remove(tag);
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null)
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
  }

  Future<void> markAsRead(Bookmark bookmark) async {
    final repo = ref.read(repositoryProvider);
    bookmark.isRead = true;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> moveToCollection(Bookmark bookmark, BookmarkCollection collection) async {
    final repo = ref.read(repositoryProvider);
    final oldCollectionId = bookmark.collection.value?.id;
    bookmark.collection.value = collection;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    ref.invalidate(collectionBookmarksProvider(collection.id));
    if (oldCollectionId != null) {
      ref.invalidate(collectionBookmarksProvider(oldCollectionId));
    }
  }

  Future<void> deleteBookmark(Bookmark bookmark) async {
    final repo = ref.read(repositoryProvider);
    await repo.deleteBookmark(bookmark.id);
    ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }
}

final bookmarkNotifierProvider =
    StateNotifierProvider<BookmarkNotifier, AsyncValue<void>>((ref) {
  return BookmarkNotifier(ref);
});

// A notifier to handle adding collections
class CollectionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  CollectionNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> addCollection(String name, String colorHex, int iconCode) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);
      final collection = BookmarkCollection()
        ..name = name
        ..colorHex = colorHex
        ..iconCodePoint = iconCode
        ..iconFontFamily = 'MaterialIcons'
        ..createdAt = DateTime.now();

      await repo.addCollection(collection);
      ref.invalidate(collectionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCollection(BookmarkCollection collection, String name, String colorHex, int iconCode) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);
      collection.name = name;
      collection.colorHex = colorHex;
      collection.iconCodePoint = iconCode;
      await repo.addCollection(collection); 
      ref.invalidate(collectionsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final collectionNotifierProvider =
    StateNotifierProvider<CollectionNotifier, AsyncValue<void>>((ref) {
  return CollectionNotifier(ref);
});





