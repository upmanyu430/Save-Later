import 'package:flutter_test/flutter_test.dart';
import 'package:save_later/utils/url_helper.dart';

void main() {
  group('UrlHelper.extractUrl', () {
    test('extracts pure URL correctly', () {
      expect(
        UrlHelper.extractUrl('https://flutter.dev'),
        'https://flutter.dev',
      );
      expect(
        UrlHelper.extractUrl('http://example.com/path?arg=1'),
        'http://example.com/path?arg=1',
      );
    });

    test('extracts URL from descriptive text prefix (e.g. shared intent)', () {
      expect(
        UrlHelper.extractUrl('Check this out: https://flutter.dev'),
        'https://flutter.dev',
      );
      expect(
        UrlHelper.extractUrl('Hey, look at this link https://example.com/news/123 - thoughts?'),
        'https://example.com/news/123',
      );
    });

    test('extracts URL from multi-line shared text', () {
      const multiline = '''
Check out this amazing article!

https://flutter.dev/docs/get-started

Hope you like it!
''';
      expect(
        UrlHelper.extractUrl(multiline),
        'https://flutter.dev/docs/get-started',
      );
    });

    test('strips trailing punctuation outside the URL', () {
      expect(
        UrlHelper.extractUrl('Check this out: https://flutter.dev/docs.'),
        'https://flutter.dev/docs',
      );
      expect(
        UrlHelper.extractUrl('Great read: https://example.com/article!'),
        'https://example.com/article',
      );
      expect(
        UrlHelper.extractUrl('Did you see https://example.com/story?'),
        'https://example.com/story',
      );
      expect(
        UrlHelper.extractUrl('Check this, https://example.com/page,'),
        'https://example.com/page',
      );
    });

    test('handles parenthesized URLs and balanced URL parentheses', () {
      expect(
        UrlHelper.extractUrl('(https://example.com/nested)'),
        'https://example.com/nested',
      );
      expect(
        UrlHelper.extractUrl('https://en.wikipedia.org/wiki/Flutter_(software)'),
        'https://en.wikipedia.org/wiki/Flutter_(software)',
      );
    });

    test('normalizes www URLs with https', () {
      expect(
        UrlHelper.extractUrl('Shared from browser: www.github.com/flutter/flutter'),
        'https://www.github.com/flutter/flutter',
      );
    });

    test('returns null for non-URL text', () {
      expect(UrlHelper.extractUrl('Just plain text with no link'), isNull);
      expect(UrlHelper.extractUrl(''), isNull);
      expect(UrlHelper.extractUrl('   '), isNull);
    });
  });

  group('UrlHelper.isValidUrl', () {
    test('returns true for valid URLs', () {
      expect(UrlHelper.isValidUrl('https://flutter.dev'), isTrue);
      expect(UrlHelper.isValidUrl('http://localhost:3000'), isTrue);
      expect(UrlHelper.isValidUrl('www.google.com'), isTrue);
      expect(UrlHelper.isValidUrl('github.com'), isTrue);
    });

    test('returns false for invalid text', () {
      expect(UrlHelper.isValidUrl('just words'), isFalse);
      expect(UrlHelper.isValidUrl(''), isFalse);
    });
  });
}
