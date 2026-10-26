/// موديل التفسير المتاح
class TafsirInfoModel {
  final int id;
  final String name;
  final String authorName;
  final String languageName;
  final String slug;

  const TafsirInfoModel({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
    required this.slug,
  });

  factory TafsirInfoModel.fromJson(Map<String, dynamic> json) {
    return TafsirInfoModel(
      id: json['id'] as int,
      name: json['name'] as String,
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? 'arabic',
      slug: json['slug'] as String? ?? '',
    );
  }

  /// هل هو تفسير عربي
  bool get isArabic => languageName == 'arabic';
}

/// موديل نص التفسير لآية
class TafsirTextModel {
  final int tafsirId;
  final String text;
  final String verseKey;

  const TafsirTextModel({
    required this.tafsirId,
    required this.text,
    required this.verseKey,
  });

  factory TafsirTextModel.fromJson(Map<String, dynamic> json) {
    return TafsirTextModel(
      tafsirId: json['resource_id'] as int? ?? json['tafsir_id'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      verseKey: json['verse_key'] as String? ?? '',
    );
  }

  /// النص بدون HTML tags
  String get plainText {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
