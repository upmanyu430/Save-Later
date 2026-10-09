import 'package:isar/isar.dart';
import 'collection.dart';

part 'bookmark.g.dart';

@collection
class Bookmark {
  Id id = Isar.autoIncrement;

  late String url;
  
  String? title;
  
  String? description;

  // User-authored notes, kept separate from fetched page metadata.
  String notes = '';
  
  String? imageUrl;
  
  String? sourceDomain;
  
  @Index()
  bool isRead = false;

  @Index()
  DateTime createdAt = DateTime.now();

  List<String> tags = [];

  @Index()
  bool isPinned = false;

  // A link to the collection it belongs to
  final collection = IsarLink<BookmarkCollection>();
}

