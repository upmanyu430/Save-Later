import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/models/collection.dart';

void main() {
  group('BookmarkCollection.parseColor & .color unit tests', () {
    test('parses 6-character hex without #', () {
      final color = BookmarkCollection.parseColor('FFD166');
      expect(color, equals(const Color(0xFFFFD166)));

      final collection = BookmarkCollection()..colorHex = 'FFD166';
      expect(collection.color, equals(const Color(0xFFFFD166)));
    });

    test('parses 6-character hex with #', () {
      final color = BookmarkCollection.parseColor('#FF9EAA');
      expect(color, equals(const Color(0xFFFF9EAA)));

      final collection = BookmarkCollection()..colorHex = '#FF9EAA';
      expect(collection.color, equals(const Color(0xFFFF9EAA)));
    });

    test('parses 8-character hex without # (previously crashed with FormatException)', () {
      final color = BookmarkCollection.parseColor('FFFFD166');
      expect(color, equals(const Color(0xFFFFD166)));

      final collection = BookmarkCollection()..colorHex = 'FFFFD166';
      expect(collection.color, equals(const Color(0xFFFFD166)));
    });

    test('parses 8-character hex with #', () {
      final color = BookmarkCollection.parseColor('#AABBCCDD');
      expect(color, equals(const Color(0xAABBCCDD)));

      final collection = BookmarkCollection()..colorHex = '#AABBCCDD';
      expect(collection.color, equals(const Color(0xAABBCCDD)));
    });

    test('parses hex with leading 0x', () {
      final color = BookmarkCollection.parseColor('0xFFFFD166');
      expect(color, equals(const Color(0xFFFFD166)));
    });

    test('parses 3-character shorthand hex', () {
      final color = BookmarkCollection.parseColor('#FFF');
      expect(color, equals(const Color(0xFFFFFFFF)));
    });

    test('gracefully handles malformed or empty hex without throwing FormatException', () {
      expect(BookmarkCollection.parseColor(''), equals(const Color(0xFFFFD166)));
      expect(BookmarkCollection.parseColor('not-a-color'), equals(const Color(0xFFFFD166)));
      expect(BookmarkCollection.parseColor(null), equals(const Color(0xFFFFD166)));

      final collection = BookmarkCollection()..colorHex = 'invalid_hex';
      expect(collection.color, equals(const Color(0xFFFFD166)));
    });
  });
}
