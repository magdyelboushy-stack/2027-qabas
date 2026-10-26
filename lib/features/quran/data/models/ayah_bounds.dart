class AyahBounds {
  final int surahNumber;
  final int ayahNumber;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  AyahBounds({
    required this.surahNumber,
    required this.ayahNumber,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  factory AyahBounds.fromMap(Map<String, dynamic> map) {
    return AyahBounds(
      surahNumber: map['sura_number'] ?? 0,
      ayahNumber: map['ayah_number'] ?? 0,
      minX: map['min_x'] ?? 0,
      minY: map['min_y'] ?? 0,
      maxX: map['max_x'] ?? 0,
      maxY: map['max_y'] ?? 0,
    );
  }
}