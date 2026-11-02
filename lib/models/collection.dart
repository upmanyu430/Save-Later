import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'collection.g.dart';

/// Font family that icons persisted in the database are stored under.
const String kStoredIconFontFamily = 'MaterialIcons';

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

  @ignore
  bool get hasWhiteIcon => isWhiteIconColor(color);

  /// Only Black (#1C1C1C) and Slate Blue/Purple (#6A5ACD) use white icons.
  /// All other colors use dark border-color (black) icons.
  static bool isWhiteIconColor(Color color) {
    // ignore: deprecated_member_use
    final v = color.value & 0x00FFFFFF;
    return v == 0x1C1C1C || v == 0x6A5ACD;
  }

  static bool isWhiteIconColorHex(String? hexString) {
    if (hexString == null) return false;
    final hex = hexString
        .replaceFirst('#', '')
        .replaceFirst(RegExp(r'^0x', caseSensitive: false), '')
        .trim()
        .toUpperCase();
    final hex6 = hex.length >= 6 ? hex.substring(hex.length - 6) : hex;
    return hex6 == '1C1C1C' || hex6 == '6A5ACD';
  }

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
