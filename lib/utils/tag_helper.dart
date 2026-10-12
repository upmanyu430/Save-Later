class TagHelper {
  /// Strips whitespace, punctuation, and delimiters, then converts to lower-case.
  /// Examples:
  /// - "UI", "ui", "U.I.", "u-i" all produce "ui"
  /// - "Front-End", "front end", "frontend" all produce "frontend"
  /// - "Node.js", "NodeJS" all produce "nodejs"
  static String normalize(String tag) {
    return tag
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s._\-–—/\\,;:!?"`~#]+'), '');
  }

  /// Checks if [newTag] is canonically equivalent to any tag in [existingTags].
  static bool isDuplicate(String newTag, Iterable<String> existingTags) {
    final clean = newTag.trim();
    if (clean.isEmpty) return false;
    final normalizedNew = normalize(clean);
    if (normalizedNew.isEmpty) return false;

    for (final existing in existingTags) {
      if (normalize(existing) == normalizedNew) {
        return true;
      }
    }
    return false;
  }

  /// Finds an existing tag in [existingTags] that matches [input]
  /// either by case-insensitive equality or by normalized equivalence.
  static String? findCanonicalTag(String input, Iterable<String> existingTags) {
    final clean = input.trim();
    if (clean.isEmpty) return null;

    final lowerClean = clean.toLowerCase();
    // 1. Check exact case-insensitive match first
    for (final tag in existingTags) {
      if (tag.toLowerCase() == lowerClean) {
        return tag;
      }
    }

    // 2. Check normalized match (e.g., "U.I." -> "UI", "front-end" -> "Frontend")
    final normalizedClean = normalize(clean);
    if (normalizedClean.isNotEmpty) {
      for (final tag in existingTags) {
        if (normalize(tag) == normalizedClean) {
          return tag;
        }
      }
    }

    return null;
  }

  /// Resolves [input] to an existing canonical tag if one exists,
  /// or returns the trimmed [input] if it is new.
  static String resolveTag(String input, Iterable<String> existingTags) {
    return findCanonicalTag(input, existingTags) ?? input.trim();
  }

  /// Returns suggestions from [existingTags] matching [query],
  /// filtering out any tags in [exclude].
  static List<String> getSuggestions(
    String query,
    Iterable<String> existingTags, {
    Iterable<String> exclude = const [],
    int limit = 10,
  }) {
    final excludedNormalized = exclude.map(normalize).toSet();
    final candidateTags = existingTags.where((t) {
      final clean = t.trim();
      if (clean.isEmpty) return false;
      return !excludedNormalized.contains(normalize(clean));
    }).toList();

    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      candidateTags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return candidateTags.take(limit).toList();
    }

    final lowerQuery = cleanQuery.toLowerCase();
    final normalizedQuery = normalize(cleanQuery);

    final exactMatches = <String>[];
    final prefixMatches = <String>[];
    final containsMatches = <String>[];
    final normalizedMatches = <String>[];

    for (final tag in candidateTags) {
      final lowerTag = tag.toLowerCase();
      final normalizedTag = normalize(tag);

      if (lowerTag == lowerQuery || (normalizedQuery.isNotEmpty && normalizedTag == normalizedQuery)) {
        exactMatches.add(tag);
      } else if (lowerTag.startsWith(lowerQuery)) {
        prefixMatches.add(tag);
      } else if (lowerTag.contains(lowerQuery)) {
        containsMatches.add(tag);
      } else if (normalizedQuery.isNotEmpty && normalizedTag.contains(normalizedQuery)) {
        normalizedMatches.add(tag);
      }
    }

    prefixMatches.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    containsMatches.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    normalizedMatches.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final results = <String>[];
    final seen = <String>{};

    for (final list in [exactMatches, prefixMatches, containsMatches, normalizedMatches]) {
      for (final tag in list) {
        if (seen.add(tag.toLowerCase())) {
          results.add(tag);
          if (results.length >= limit) return results;
        }
      }
    }

    return results;
  }
}
