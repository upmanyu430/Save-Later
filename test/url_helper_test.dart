import 'dart:io';
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

  group('UrlHelper.isRedirectWrapper', () {
    test('returns true for known shortener and share wrapper domains', () {
      expect(UrlHelper.isRedirectWrapper('share.google'), isTrue);
      expect(UrlHelper.isRedirectWrapper('https://share.google/abc123'), isTrue);
      expect(UrlHelper.isRedirectWrapper('bit.ly'), isTrue);
      expect(UrlHelper.isRedirectWrapper('https://t.co/xyz'), isTrue);
      expect(UrlHelper.isRedirectWrapper('tinyurl.com'), isTrue);
    });

    test('returns false for standard web domains', () {
      expect(UrlHelper.isRedirectWrapper('https://opencode.ai'), isFalse);
      expect(UrlHelper.isRedirectWrapper('github.com'), isFalse);
      expect(UrlHelper.isRedirectWrapper('flutter.dev'), isFalse);
      expect(UrlHelper.isRedirectWrapper(null), isFalse);
      expect(UrlHelper.isRedirectWrapper(''), isFalse);
    });
  });

  group('UrlHelper.fallbackPreviewUrl', () {
    test('wraps the page url into the thum.io screenshot endpoint', () {
      expect(
        UrlHelper.fallbackPreviewUrl('https://www.imdb.com/title/tt0111161/'),
        'https://image.thum.io/get/width/1200/crop/900/https://www.imdb.com/title/tt0111161/',
      );
    });

    test('supports a custom width', () {
      expect(
        UrlHelper.fallbackPreviewUrl('https://example.com/page?id=1', width: 800),
        'https://image.thum.io/get/width/800/crop/900/https://example.com/page?id=1',
      );
    });

    test('returns empty string for empty input', () {
      expect(UrlHelper.fallbackPreviewUrl(''), '');
      expect(UrlHelper.fallbackPreviewUrl('   '), '');
    });
  });

  group('UrlHelper.resolveImageUrl', () {
    test('returns null for null or empty imageUrl', () {
      expect(UrlHelper.resolveImageUrl(null, 'https://example.com'), isNull);
      expect(UrlHelper.resolveImageUrl('', 'https://example.com'), isNull);
      expect(UrlHelper.resolveImageUrl('   ', 'https://example.com'), isNull);
    });

    test('returns absolute HTTP/HTTPS URLs unchanged', () {
      expect(
        UrlHelper.resolveImageUrl('https://opencode.ai/social.png', 'https://opencode.ai'),
        'https://opencode.ai/social.png',
      );
      expect(
        UrlHelper.resolveImageUrl('http://example.com/pic.jpg', 'https://other.com'),
        'http://example.com/pic.jpg',
      );
    });

    test('normalizes protocol-relative URLs with https', () {
      expect(
        UrlHelper.resolveImageUrl('//cdn.example.com/image.png', 'https://example.com'),
        'https://cdn.example.com/image.png',
      );
    });

    test('resolves root-relative URLs against base URL', () {
      expect(
        UrlHelper.resolveImageUrl('/social-share.png', 'https://opencode.ai'),
        'https://opencode.ai/social-share.png',
      );
      expect(
        UrlHelper.resolveImageUrl('/social-share.png', 'https://opencode.ai/subpage/path'),
        'https://opencode.ai/social-share.png',
      );
    });

    test('resolves path-relative URLs against base URL', () {
      expect(
        UrlHelper.resolveImageUrl('assets/img.png', 'https://example.com/blog/'),
        'https://example.com/blog/assets/img.png',
      );
      expect(
        UrlHelper.resolveImageUrl('../img.png', 'https://example.com/blog/sub/'),
        'https://example.com/blog/img.png',
      );
    });
  });

  group('UrlHelper.resolveFinalUrl', () {
    late HttpServer server;
    late String serverUrl;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://${server.address.host}:${server.port}';

      server.listen((HttpRequest request) {
        if (request.uri.path == '/step1') {
          request.response
            ..statusCode = HttpStatus.movedTemporarily
            ..headers.set(HttpHeaders.locationHeader, '$serverUrl/step2')
            ..close();
        } else if (request.uri.path == '/step2') {
          request.response
            ..statusCode = HttpStatus.movedPermanently
            ..headers.set(HttpHeaders.locationHeader, '$serverUrl/final')
            ..close();
        } else if (request.uri.path == '/final') {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('Hello')
            ..close();
        } else if (request.uri.path == '/hang') {
          // Keep request open to trigger client timeout
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              request.response.close();
            } catch (_) {}
          });
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('follows redirect chain to final target', () async {
      final resolved = await UrlHelper.resolveFinalUrl('$serverUrl/step1');
      expect(resolved, '$serverUrl/final');
    });

    test('returns direct URL when no redirects occur', () async {
      final resolved = await UrlHelper.resolveFinalUrl('$serverUrl/final');
      expect(resolved, '$serverUrl/final');
    });
    test('returns normalized URL on timeout and safely closes client', () async {
      final resolved = await UrlHelper.resolveFinalUrl(
        '$serverUrl/hang',
        timeout: const Duration(milliseconds: 60),
      );
      expect(resolved, '$serverUrl/hang');
    });

    test('returns normalized URL on socket error and safely closes client', () async {
      final resolved = await UrlHelper.resolveFinalUrl(
        'http://127.0.0.1:1/unreachable',
        timeout: const Duration(milliseconds: 60),
      );
      expect(resolved, 'http://127.0.0.1:1/unreachable');
    });
  });
}
