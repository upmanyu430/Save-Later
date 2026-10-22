import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'collection.g.dart';

@collection
class BookmarkCollection {
  Id id = Isar.autoIncrement;

  late String name;
  
  // Hex color string, e.g., 'FFAABB' or 'FFFFD166'
  late String colorHex;
  
  // CodePoint for the icon
  late int iconCodePoint;
  
  // Font family for the icon, usually 'MaterialIcons'
  late String iconFontFamily;

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  int? parentId;

  @ignore
  Color get color => parseColor(colorHex);

  static Color parseColor(String? hexString, [Color fallback = const Color(0xFFFFD166)]) {
    if (hexString == null) return fallback;
    try {
      String hex = hexString
          .replaceFirst('#', '')
          .replaceFirst(RegExp(r'^0x', caseSensitive: false), '')
          .trim();
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}
