/// Reads Firestore fields shaped as `{base}En`, `{base}Ar`, `{base}He`
/// with fallback to legacy single `{base}` (e.g. name, city, title).
class LocalizedContent {
  LocalizedContent._();

  static String _trim(dynamic v) => v?.toString().trim() ?? '';

  static String _suffixKey(String baseKey, String langCode) {
    final cap = langCode.isEmpty
        ? 'En'
        : '${langCode[0].toUpperCase()}${langCode.substring(1)}';
    return '$baseKey$cap';
  }

  static String pickFromMap(
    Map<String, dynamic> data,
    String languageCode, {
    required String baseKey,
  }) {
    final en = _trim(data[_suffixKey(baseKey, 'en')]);
    final ar = _trim(data[_suffixKey(baseKey, 'ar')]);
    final he = _trim(data[_suffixKey(baseKey, 'he')]);
    final legacy = _trim(data[baseKey]);

    String firstNonEmpty(List<String> order) {
      for (final s in order) {
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    switch (languageCode) {
      case 'ar':
        return firstNonEmpty([ar, en, he, legacy]);
      case 'he':
        return firstNonEmpty([he, en, ar, legacy]);
      default:
        return firstNonEmpty([en, ar, he, legacy]);
    }
  }
}
