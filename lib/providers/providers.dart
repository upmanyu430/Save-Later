import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import '../models/collection.dart';
import '../repositories/isar_repository.dart';
import '../utils/tag_helper.dart';
import '../utils/url_helper.dart';

final repositoryProvider = Provider<IsarRepository>((ref) {
  return IsarRepository();
});

final collectionsProvider =
    FutureProvider<List<BookmarkCollection>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getCollections();
});

final allCollectionsProvider =
    FutureProvider<List<BookmarkCollection>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getAllCollections();
});

final singleCollectionProvider =
    FutureProvider.family<BookmarkCollection?, int>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getCollection(id);
});

final subCollectionsProvider =
    FutureProvider.family<List<BookmarkCollection>, int>((ref, parentId) async {
  final repo = ref.watch(repositoryProvider);
  return repo.getSubCollections(parentId);
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

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final bookmarks = await ref.watch(bookmarksProvider.future);
  final tagSet = <String>{};
  for (final b in bookmarks) {
    for (final t in b.tags) {
      final clean = t.trim();
      if (clean.isNotEmpty) {
        tagSet.add(clean);
      }
    }
  }
  final sorted = tagSet.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sorted;
});

final savingBookmarkIdsProvider = StateProvider<Set<int>>((ref) => {});
final refreshingBookmarkIdsProvider = StateProvider<Set<int>>((ref) => {});

// A notifier to handle adding a bookmark and fetching metadata
class BookmarkNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  BookmarkNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> quickSave(String url, {BookmarkCollection? collection}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);

      String cleanUrl = UrlHelper.extractUrl(url) ?? url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final initialUri = Uri.tryParse(cleanUrl);
      final initialDomain = initialUri?.host.isNotEmpty == true ? initialUri!.host : cleanUrl;

      // Create initial bookmark immediately so it shows instantly in the grid
      final bookmark = Bookmark()
        ..url = cleanUrl
        ..title = cleanUrl
        ..sourceDomain = initialDomain
        ..createdAt = DateTime.now()
        ..isRead = false;

      if (collection != null) {
        bookmark.collection.value = collection;
      }

      await repo.addBookmark(bookmark);

      // Track as actively saving
      ref.read(savingBookmarkIdsProvider.notifier).update((set) => {...set, bookmark.id});

      // Invalidate providers so the placeholder appears in the grid immediately
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      if (collection != null) {
        ref.invalidate(collectionBookmarksProvider(collection.id));
      }

      state = const AsyncValue.data(null);

      // Trigger background metadata fetching and resolution
      _fetchMetadataAndUpdate(bookmark, cleanUrl, collection);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _fetchMetadataAndUpdate(
    Bookmark bookmark,
    String cleanUrl,
    BookmarkCollection? collection,
  ) async {
    try {
      final repo = ref.read(repositoryProvider);

      // Resolve redirect chains (e.g. share.google, bit.ly, t.co) to canonical target
      final resolvedUrl = await UrlHelper.resolveFinalUrl(cleanUrl);
      final cleanUri = Uri.tryParse(cleanUrl);
      final resolvedUri = Uri.tryParse(resolvedUrl);

      final isWrapperOrCrossHost = (cleanUri != null &&
          resolvedUri != null &&
          (cleanUri.host.toLowerCase() != resolvedUri.host.toLowerCase() ||
              UrlHelper.isRedirectWrapper(cleanUrl)));

      final finalUrl = isWrapperOrCrossHost ? resolvedUrl : cleanUrl;
      final targetUri = resolvedUri ?? cleanUri ?? Uri.parse(finalUrl);

      // Attempt to fetch metadata
      String? title;
      String? description;
      String? imageUrl;
      String? sourceDomain = targetUri.host;

      try {
        var data = await UrlHelper.fetchMetadata(resolvedUrl);
        if (data != null) {
          if (data.title != null && data.title!.isNotEmpty) {
            title = data.title;
          }
          if (data.description != null && data.description!.isNotEmpty) {
            description = data.description;
          }
          imageUrl = UrlHelper.resolveImageUrl(data.image, resolvedUrl);
        }
      } catch (e) {
        debugPrint('Error fetching metadata: $e');
      }

      bookmark.url = finalUrl;
      bookmark.title = title ?? cleanUrl;
      bookmark.description = description;
      // Pages behind bot challenges (AWS WAF, Cloudflare...) send 202/403 and
      // cannot be scraped by any HTTP client, so no og:image exists. Keep a
      // usable preview alive with an automatic page screenshot instead of
      // leaving the background image permanently empty.
      bookmark.imageUrl = imageUrl ?? UrlHelper.fallbackPreviewUrl(finalUrl);
      bookmark.sourceDomain = sourceDomain;

      await repo.updateBookmark(bookmark);
    } catch (e) {
      debugPrint('Error updating bookmark metadata: $e');
    } finally {
      ref.read(savingBookmarkIdsProvider.notifier).update(
            (set) => set.where((id) => id != bookmark.id).toSet(),
          );
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      if (collection != null) {
        ref.invalidate(collectionBookmarksProvider(collection.id));
      }
    }
  }


  Future<void> addTag(Bookmark bookmark, String tag) async {
    final clean = tag.trim();
    if (clean.isEmpty) return;

    // Guard against duplicate variations on the same bookmark
    if (TagHelper.isDuplicate(clean, bookmark.tags)) {
      return;
    }

    // Resolve tag to existing canonical version if available across all bookmarks
    final allBookmarks = await ref.read(bookmarksProvider.future);
    final allExistingTags = <String>{};
    for (final b in allBookmarks) {
      allExistingTags.addAll(b.tags);
    }
    final resolvedTag = TagHelper.resolveTag(clean, allExistingTags);

    final repo = ref.read(repositoryProvider);
    bookmark.tags = List.from(bookmark.tags)..add(resolvedTag);
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    ref.invalidate(allTagsProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> refreshMetadata(Bookmark bookmark) async {
    ref.read(refreshingBookmarkIdsProvider.notifier).update((set) => {...set, bookmark.id});
    try {
      if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
        try {
          await bookmark.collection.load();
        } catch (_) {}
      }
      String url = UrlHelper.extractUrl(bookmark.url) ?? bookmark.url.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      final resolvedUrl = await UrlHelper.resolveFinalUrl(url);
      final originalUri = Uri.tryParse(url);
      final resolvedUri = Uri.tryParse(resolvedUrl);

      final isWrapperOrCrossHost = (originalUri != null &&
          resolvedUri != null &&
          (originalUri.host.toLowerCase() != resolvedUri.host.toLowerCase() ||
              UrlHelper.isRedirectWrapper(url)));

      if (isWrapperOrCrossHost) {
        bookmark.url = resolvedUrl;
        bookmark.sourceDomain = resolvedUri.host;
      } else {
        bookmark.sourceDomain = (resolvedUri ?? originalUri)?.host ?? bookmark.sourceDomain;
      }

      var data = await UrlHelper.fetchMetadata(resolvedUrl);
      if (data != null) {
        if (data.title != null && data.title!.isNotEmpty) {
          bookmark.title = data.title!;
        }
        if (data.description != null && data.description!.isNotEmpty) {
          bookmark.description = data.description!;
        }
        final resolvedImg = UrlHelper.resolveImageUrl(data.image, resolvedUrl);
        if (resolvedImg != null && resolvedImg.isNotEmpty) {
          bookmark.imageUrl = resolvedImg;
        } else if (bookmark.imageUrl == null || bookmark.imageUrl!.trim().isEmpty) {
          // Page has no og:image and nothing stored — keep a preview alive
          // with an automatic page screenshot instead of leaving it empty.
          bookmark.imageUrl = UrlHelper.fallbackPreviewUrl(resolvedUrl);
        }
      } else if (bookmark.imageUrl == null || bookmark.imageUrl!.trim().isEmpty) {
        // Fetch itself failed (bot challenge / network) and nothing is stored
        // yet — fall back to an automatic page screenshot. A previously
        // stored URL is kept as-is: the failure is probably transient.
        bookmark.imageUrl = UrlHelper.fallbackPreviewUrl(resolvedUrl);
      }
      await ref.read(repositoryProvider).updateBookmark(bookmark);
    } catch (e) {
      debugPrint('Error refreshing metadata: $e');
    } finally {
      ref.read(refreshingBookmarkIdsProvider.notifier).update(
            (set) => set.where((id) => id != bookmark.id).toSet(),
          );
      ref.invalidate(bookmarksProvider);
      ref.invalidate(unsortedBookmarksProvider);
      final colId = bookmark.collection.value?.id;
      if (colId != null) {
        ref.invalidate(collectionBookmarksProvider(colId));
      }
    }
  }

    Future<void> removeTag(Bookmark bookmark, String tag) async {
    final repo = ref.read(repositoryProvider);
    bookmark.tags = List.from(bookmark.tags)..remove(tag);
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    ref.invalidate(allTagsProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> markAsUnread(Bookmark bookmark) async {
    final repo = ref.read(repositoryProvider);
    if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
      try {
        await bookmark.collection.load();
      } catch (_) {}
    }
    bookmark.isRead = false;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> markAsRead(Bookmark bookmark) async {
    final repo = ref.read(repositoryProvider);
    if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
      try {
        await bookmark.collection.load();
      } catch (_) {}
    }
    bookmark.isRead = true;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> togglePin(Bookmark bookmark) async {
    final repo = ref.read(repositoryProvider);
    if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
      try {
        await bookmark.collection.load();
      } catch (_) {}
    }
    bookmark.isPinned = !bookmark.isPinned;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> moveToCollection(Bookmark bookmark, BookmarkCollection? collection) async {
    await moveBookmarksToCollection([bookmark], collection);
  }

  Future<void> moveBookmarksToCollection(List<Bookmark> bookmarks, BookmarkCollection? collection) async {
    if (bookmarks.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final oldCollectionIds = <int>{};
    for (final bookmark in bookmarks) {
      if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
        try {
          await bookmark.collection.load();
        } catch (_) {}
      }
      final oldId = bookmark.collection.value?.id;
      if (oldId != null && (collection == null || oldId != collection.id)) {
        oldCollectionIds.add(oldId);
      }
      bookmark.collection.value = collection;
    }
    await repo.updateBookmarks(bookmarks);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    if (collection != null) {
      ref.invalidate(collectionBookmarksProvider(collection.id));
    }
    for (final oldId in oldCollectionIds) {
      ref.invalidate(collectionBookmarksProvider(oldId));
    }
  }

  Future<void> removeFromCollection(Bookmark bookmark) async {
    await moveToCollection(bookmark, null);
  }

  Future<void> removeBookmarksFromCollection(List<Bookmark> bookmarks) async {
    await moveBookmarksToCollection(bookmarks, null);
  }

  Future<void> updateNotes(Bookmark bookmark, String notes) async {
    final repo = ref.read(repositoryProvider);
    bookmark.notes = notes;
    await repo.updateBookmark(bookmark);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    if (bookmark.collection.value != null) {
      ref.invalidate(
          collectionBookmarksProvider(bookmark.collection.value!.id));
    }
  }

  Future<void> deleteBookmark(Bookmark bookmark, {int? collectionId}) async {
    await deleteBookmarks([bookmark], collectionId: collectionId);
  }

  Future<void> deleteBookmarks(List<Bookmark> bookmarks, {int? collectionId}) async {
    if (bookmarks.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final affectedCollectionIds = <int>{};
    if (collectionId != null) {
      affectedCollectionIds.add(collectionId);
    }
    for (final bookmark in bookmarks) {
      if (bookmark.collection.isAttached && !bookmark.collection.isLoaded) {
        try {
          await bookmark.collection.load();
        } catch (_) {}
      }
      final colId = bookmark.collection.value?.id;
      if (colId != null) {
        affectedCollectionIds.add(colId);
      }
    }
    final ids = bookmarks.map((b) => b.id).toList();
    await repo.deleteBookmarks(ids);
    ref.invalidate(bookmarksProvider);
    ref.invalidate(unsortedBookmarksProvider);
    ref.invalidate(collectionsProvider);
    for (final colId in affectedCollectionIds) {
      ref.invalidate(collectionBookmarksProvider(colId));
    }
    ref.invalidate(collectionBookmarksProvider);
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

  Future<void> addCollection(String name, String colorHex, int iconCode, {int? parentId}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);
      final collection = BookmarkCollection()
        ..name = name
        ..colorHex = colorHex
        ..iconCodePoint = iconCode
        ..iconFontFamily = 'MaterialIcons'
        ..parentId = parentId
        ..createdAt = DateTime.now();

      await repo.addCollection(collection);
      ref.invalidate(collectionsProvider);
      ref.invalidate(allCollectionsProvider);
      ref.invalidate(singleCollectionProvider(collection.id));
      if (parentId != null) {
        ref.invalidate(subCollectionsProvider(parentId));
      }
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
      ref.invalidate(allCollectionsProvider);
      ref.invalidate(singleCollectionProvider(collection.id));
      if (collection.parentId != null) {
        ref.invalidate(subCollectionsProvider(collection.parentId!));
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCollection(BookmarkCollection collection) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repositoryProvider);
      final parentId = collection.parentId;
      await repo.deleteCollection(collection.id);
      ref.invalidate(collectionsProvider);
      ref.invalidate(allCollectionsProvider);
      ref.invalidate(singleCollectionProvider(collection.id));
      ref.invalidate(unsortedBookmarksProvider);
      ref.invalidate(collectionBookmarksProvider(collection.id));
      ref.invalidate(bookmarksProvider);
      if (parentId != null) {
        ref.invalidate(subCollectionsProvider(parentId));
      }
      ref.invalidate(subCollectionsProvider(collection.id));
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








