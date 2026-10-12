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
}
