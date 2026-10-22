import 'dart:io';

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
}
