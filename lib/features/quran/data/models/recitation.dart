class Recitation {
  final String id;
  final String title;
  final String audioUrl;
  final String reciterName;
  final String? mushafId;
  final String? mushafName;
  final String? duration; // Optional duration (e.g. "00:05:40" or "340" seconds)
  final String audioSource; // 'archive' or 'telegram'
  final String? telegramFileId;
  final int? fileSize;
  final String? fileName;

  const Recitation({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.reciterName,
    this.mushafId,
    this.mushafName,
    this.duration,
    this.audioSource = 'archive',
    this.telegramFileId,
    this.fileSize,
    this.fileName,
  });

  factory Recitation.fromJson(Map<String, dynamic> json) {
    return Recitation(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      reciterName: json['reciter_name'] ?? '',
      mushafId: json['mushaf_id']?.toString(),
      mushafName: json['mushaf_name'],
      duration: json['duration']?.toString(), // Get from API if available
      audioSource: json['audio_source'] ?? 'archive',
      telegramFileId: json['telegram_file_id'],
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      fileName: json['file_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'audio_url': audioUrl,
      'reciter_name': reciterName,
      'mushaf_id': mushafId,
      'mushaf_name': mushafName,
      'duration': duration,
      'audio_source': audioSource,
      'telegram_file_id': telegramFileId,
      'file_size': fileSize,
      'file_name': fileName,
    };
  }

  /// Whether this recitation streams from Telegram
  bool get isTelegram => audioSource == 'telegram';

  /// Whether this recitation is from archive.org or direct URL
  bool get isArchive => audioSource == 'archive';
}