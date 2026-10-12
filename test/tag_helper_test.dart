import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/utils/tag_helper.dart';

void main() {
  group('TagHelper.normalize', () {
    test('handles casing and trim', () {
      expect(TagHelper.normalize('  UI  '), 'ui');
      expect(TagHelper.normalize('FLUTTER'), 'flutter');
      expect(TagHelper.normalize('dart'), 'dart');
    });

    test('strips punctuation, dots, dashes, and underscores', () {
      expect(TagHelper.normalize('U.I.'), 'ui');
      expect(TagHelper.normalize('u.i.'), 'ui');
      expect(TagHelper.normalize('u-i'), 'ui');
      expect(TagHelper.normalize('u_i'), 'ui');
      expect(TagHelper.normalize('front-end'), 'frontend');
      expect(TagHelper.normalize('Front End'), 'frontend');
      expect(TagHelper.normalize('Node.js'), 'nodejs');
    });
  });

  group('TagHelper.isDuplicate', () {
    test('detects duplicates with different variations', () {
      final existing = ['UI', 'frontend', 'Flutter'];

      expect(TagHelper.isDuplicate('ui', existing), isTrue);
      expect(TagHelper.isDuplicate('U.I.', existing), isTrue);
      expect(TagHelper.isDuplicate('u.i.', existing), isTrue);
      expect(TagHelper.isDuplicate('u-i', existing), isTrue);
      expect(TagHelper.isDuplicate('front-end', existing), isTrue);
      expect(TagHelper.isDuplicate('FRONTEND', existing), isTrue);
      expect(TagHelper.isDuplicate('flutter', existing), isTrue);
    });

    test('returns false for non-duplicates and empty strings', () {
      final existing = ['UI', 'frontend'];

      expect(TagHelper.isDuplicate('backend', existing), isFalse);
      expect(TagHelper.isDuplicate('AI', existing), isFalse);
      expect(TagHelper.isDuplicate('', existing), isFalse);
      expect(TagHelper.isDuplicate('   ', existing), isFalse);
    });
  });

  group('TagHelper.findCanonicalTag', () {
    test('finds exact case-insensitive match first', () {
      final existing = ['UI', 'frontend', 'Flutter'];

      expect(TagHelper.findCanonicalTag('ui', existing), 'UI');
      expect(TagHelper.findCanonicalTag('FLUTTER', existing), 'Flutter');
      expect(TagHelper.findCanonicalTag('Frontend', existing), 'frontend');
    });

    test('finds normalized match when punctuation varies', () {
      final existing = ['UI', 'Frontend'];

      expect(TagHelper.findCanonicalTag('U.I.', existing), 'UI');
      expect(TagHelper.findCanonicalTag('u.i.', existing), 'UI');
      expect(TagHelper.findCanonicalTag('u-i', existing), 'UI');
      expect(TagHelper.findCanonicalTag('front-end', existing), 'Frontend');
      expect(TagHelper.findCanonicalTag('front end', existing), 'Frontend');
    });

    test('returns null for unknown tags', () {
      final existing = ['UI', 'Frontend'];

      expect(TagHelper.findCanonicalTag('React', existing), isNull);
      expect(TagHelper.findCanonicalTag('', existing), isNull);
    });
  });

  group('TagHelper.resolveTag', () {
    test('resolves to canonical tag when match exists', () {
      final existing = ['UI', 'Frontend'];

      expect(TagHelper.resolveTag('u.i.', existing), 'UI');
      expect(TagHelper.resolveTag('ui', existing), 'UI');
      expect(TagHelper.resolveTag('front-end', existing), 'Frontend');
    });

    test('returns trimmed input when no canonical tag exists', () {
      final existing = ['UI'];

      expect(TagHelper.resolveTag('  Dart  ', existing), 'Dart');
    });
  });

  group('TagHelper.getSuggestions', () {
    final existing = ['UI', 'UX', 'Frontend', 'Backend', 'Flutter', 'Firebase'];

    test('returns existing tags when query is empty, respecting exclude', () {
      final suggestions = TagHelper.getSuggestions('', existing, exclude: ['UI']);

      expect(suggestions.contains('UI'), isFalse);
      expect(suggestions.contains('UX'), isTrue);
      expect(suggestions.contains('Flutter'), isTrue);
    });

    test('filters by prefix, substring, and normalized equivalence', () {
      final suggestions = TagHelper.getSuggestions('f', existing);

      expect(suggestions.contains('Flutter'), isTrue);
      expect(suggestions.contains('Frontend'), isTrue);
      expect(suggestions.contains('Firebase'), isTrue);
      expect(suggestions.contains('Backend'), isFalse);
    });

    test('suggests canonical tag even when query includes punctuation', () {
      final suggestions = TagHelper.getSuggestions('u.i.', existing);

      expect(suggestions.first, 'UI');
    });

    test('excludes variations already present on bookmark', () {
      // If bookmark already has "UI", querying "u" should not suggest "UI"
      final suggestions = TagHelper.getSuggestions('u', existing, exclude: ['u.i.']);

      expect(suggestions.contains('UI'), isFalse);
      expect(suggestions.contains('UX'), isTrue);
    });
  });
}
