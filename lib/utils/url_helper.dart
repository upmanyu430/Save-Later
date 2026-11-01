import 'dart:convert';
import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlHelper {
  // Regex matching http/https URLs or www. domains in text
  static final RegExp _urlRegex = RegExp(
    r'(https?:\/\/[^\s]+|www\.[^\s]+)',
    caseSensitive: false,
  );

  // Regex matching standalone domain-like paths (e.g. "github.com/flutter")
  static final RegExp _domainRegex = RegExp(
    r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^\s]*)?$',
  );

  /// Extracts the first valid HTTP/HTTPS or www URL from [text].
  ///
  /// Strips surrounding sentence punctuation like '.', ',', '!', '?', etc.
  /// Also handles enclosing parentheses around the URL while preserving balanced parentheses.
  /// Returns null if no URL is found.
  static String? extractUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final match = _urlRegex.firstMatch(trimmed);
    if (match == null) {
      if (_domainRegex.hasMatch(trimmed)) {
        return trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
            ? trimmed
            : 'https://$trimmed';
      }
      return null;
    }

    String url = match.group(0)!;

    // Strip trailing punctuation: .,!?:;'"
    url = url.replaceAll(RegExp(r'''[.,!?:;'"\]]+$'''), '');

    // If there is an unbalanced closing parenthesis at the end (e.g., "(https://example.com)"), strip it
    while (url.endsWith(')') && '('.allMatches(url).length < ')'.allMatches(url).length) {
      url = url.substring(0, url.length - 1);
    }

    // Re-check trailing punctuation after stripping parenthesis
    url = url.replaceAll(RegExp(r'''[.,!?:;'"\]]+$'''), '');

    if (url.startsWith(RegExp(r'www\.', caseSensitive: false))) {
      url = 'https://$url';
    }

    return url.isNotEmpty ? url : null;
  }

  /// Checks if [url] represents a valid web URL or host.
  static bool isValidUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    final normalized = trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? trimmed
        : 'https://$trimmed';

    try {
      final uri = Uri.tryParse(normalized);
      if (uri == null || uri.host.isEmpty) return false;
      return uri.host == 'localhost' || uri.host.contains('.');
    } catch (_) {
      return false;
    }
  }

  /// Checks whether [urlOrHost] is a known URL shortener or sharing wrapper service.
  static bool isRedirectWrapper(String? urlOrHost) {
    if (urlOrHost == null) return false;
    final trimmed = urlOrHost.trim().toLowerCase();
    if (trimmed.isEmpty) return false;

    final uri = Uri.tryParse(trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? trimmed
        : 'https://$trimmed');

    final host = uri?.host.toLowerCase() ?? trimmed;
    final path = uri?.path.toLowerCase() ?? '';

    if (host == 'share.google' ||
        path.contains('share.google') ||
        (host.endsWith('google.com') && (path.startsWith('/url') || path.startsWith('/share')))) {
      return true;
    }

    const wrappers = {
      'share.google',
      't.co',
      'bit.ly',
      'bitly.com',
      'goo.gl',
      'tinyurl.com',
      'ow.ly',
      'is.gd',
      'buff.ly',
      'ift.tt',
      'dlvr.it',
      'fb.me',
      'lnkd.in',
      'trib.al',
      'linktr.ee',
    };

    return wrappers.contains(host);
  }

  /// Resolves relative image URLs against a base URL.
  /// Handles protocol-relative URLs (`//domain.com/img.png`),
  /// root-relative URLs (`/img.png`), and path-relative URLs (`img.png`).
  static String? resolveImageUrl(String? imageUrl, String? baseUrl) {
    if (imageUrl == null) return null;
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return trimmed;
    }

    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return trimmed;
    }

    final cleanBase = baseUrl.trim().startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? baseUrl.trim()
        : 'https://${baseUrl.trim()}';

    final baseUri = Uri.tryParse(cleanBase);
    if (baseUri == null) return trimmed;

    try {
      return baseUri.resolveUri(uri).toString();
    } catch (_) {
      return trimmed;
    }
  }

  /// thum.io live page-screenshot endpoint, used as an automatic preview
  /// fallback for pages whose OpenGraph image cannot be scraped (AWS WAF /
  /// Cloudflare bot challenges respond 202/403 to any client) or whose stored
  /// CDN link has expired (e.g. Instagram signed URLs).
  static String fallbackPreviewUrl(String url, {int width = 1200}) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    return 'https://image.thum.io/get/width/$width/crop/900/$trimmed';
  }

  /// Resolves HTTP redirect chains (e.g. share.google, bit.ly, t.co) to find the canonical URL.
  /// Uses GET with automatic redirect following so services that only redirect on GET (like Google share links)
  /// are properly resolved.
  /// Falls back to the original [url] if network fails or resolution times out.
  static Future<String> resolveFinalUrl(
    String url, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    final normalized = trimmed.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? trimmed
        : 'https://$trimmed';

    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = timeout;
      client.badCertificateCallback = (cert, host, port) => true;

      final uri = Uri.parse(normalized);
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = true;
      request.maxRedirects = 5;
      request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36');

      final response = await request.close().timeout(timeout);
      Uri currentUri = uri;
      for (final redirect in response.redirects) {
        currentUri = currentUri.resolveUri(redirect.location);
      }
      await response.drain().catchError((_) {});
      return currentUri.toString();
    } catch (_) {
      return normalized;
    } finally {
      client?.close(force: true);
    }
  }

  /// Fetches webpage metadata (title, description, image) using realistic browser headers
  /// to avoid 403 Forbidden responses from protected websites (e.g., Microsoft Store, Cloudflare, etc.).
  static Future<Metadata?> fetchMetadata(
    String url, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final cleanUrl = extractUrl(url) ?? url.trim();
    if (!isValidUrl(cleanUrl)) return null;

    final targetUri = Uri.tryParse(cleanUrl.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? cleanUrl
        : 'https://$cleanUrl');
    if (targetUri == null) return null;

    const headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };

    try {
      final response = await http.get(targetUri, headers: headers).timeout(timeout);
      if (response.statusCode == 200) {
        final document = parser.parse(utf8.decode(response.bodyBytes, allowMalformed: true));
        final data = MetadataParser.parse(document, url: targetUri.toString());

        // Check additional meta tags for image if OpenGraph / TwitterCard missed it:
        if (data.image == null || data.image!.trim().isEmpty) {
          final ogSecure = document.querySelector('meta[property="og:image:secure_url"]')?.attributes['content'];
          final twitterSrc = document.querySelector('meta[name="twitter:image:src"]')?.attributes['content'];
          final linkImg = document.querySelector('link[rel="image_src"]')?.attributes['href'];
          final linkIcon = document.querySelector('link[rel="apple-touch-icon"]')?.attributes['href'] ??
              document.querySelector('link[rel="icon"]')?.attributes['href'];
          final fallbackImg = ogSecure ?? twitterSrc ?? linkImg ?? linkIcon;
          if (fallbackImg != null && fallbackImg.trim().isNotEmpty) {
            data.image = resolveImageUrl(fallbackImg, targetUri.toString());
          }
        }

        // Check title fallback if empty or just domain
        if (data.title == null || data.title!.trim().isEmpty) {
          final ogTitle = document.querySelector('meta[property="og:title"]')?.attributes['content'];
          final twitterTitle = document.querySelector('meta[name="twitter:title"]')?.attributes['content'];
          data.title = ogTitle ?? twitterTitle ?? document.querySelector('title')?.text.trim();
        }

        // Check description fallback
        if (data.description == null || data.description!.trim().isEmpty) {
          final ogDesc = document.querySelector('meta[property="og:description"]')?.attributes['content'];
          final twitterDesc = document.querySelector('meta[name="twitter:description"]')?.attributes['content'];
          final metaDesc = document.querySelector('meta[name="description"]')?.attributes['content'];
          data.description = ogDesc ?? twitterDesc ?? metaDesc;
        }

        if (data.image != null) {
          data.image = resolveImageUrl(data.image, targetUri.toString());
        }

        return data;
      }
    } catch (_) {
      // Fall through to MetadataFetch.extract
    }

    try {
      return await MetadataFetch.extract(targetUri.toString()).timeout(timeout);
    } catch (_) {
      return null;
    }
  }
}
