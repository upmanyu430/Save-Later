import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'collection.g.dart';

@collection
class BookmarkCollection {
  Id id = Isar.autoIncrement;

  late String name;
  
  // Hex color string, e.g., 'FFAABB'
  late String colorHex;
  
  // CodePoint for the icon
  late int iconCodePoint;
  
  // Font family for the icon, usually 'MaterialIcons'
  late String iconFontFamily;

  @Index()
  DateTime createdAt = DateTime.now();

  @ignore
  Color get color => Color(int.parse('0xFF$colorHex'));
}
