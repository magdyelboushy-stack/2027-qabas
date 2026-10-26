/// موديل الكلمة القرآنية من Quran.Foundation API
class QuranWordModel {
  final int id;
  final int position;
  final String? audioUrl;
  final String charTypeName; // "word" or "end"
  final String textUthmani;
  final String text;
  final String? translationText;
  final String? transliterationText;
  final int pageNumber;
  final int lineNumber;

  const QuranWordModel({
    required this.id,
    required this.position,
    this.audioUrl,
    required this.charTypeName,
    required this.textUthmani,
    required this.text,
    this.translationText,
    this.transliterationText,
    required this.pageNumber,
    required this.lineNumber,
  });

  factory QuranWordModel.fromJson(Map<String, dynamic> json) {
    return QuranWordModel(
      id: json['id'] as int,
      position: json['position'] as int,
      audioUrl: json['audio_url'] as String?,
      charTypeName: json['char_type_name'] as String? ?? 'word',
      textUthmani: json['text_uthmani'] as String? ?? json['text'] as String? ?? '',
      text: json['text'] as String? ?? '',
      translationText: json['translation']?['text'] as String?,
      transliterationText: json['transliteration']?['text'] as String?,
      pageNumber: json['page_number'] as int? ?? 1,
      lineNumber: json['line_number'] as int? ?? 1,
    );
  }

  /// هل هي كلمة عادية (وليست رقم آية)
  bool get isWord => charTypeName == 'word';

  /// هل لها صوت
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
}
