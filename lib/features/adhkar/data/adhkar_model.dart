class DhikrItem {
  final int id;
  final String text;
  final int count;
  final String audio;
  final String filename;
  final String bless; // Evidence / additional note

  const DhikrItem({
    required this.id,
    required this.text,
    required this.count,
    required this.audio,
    required this.filename,
    this.bless = '',
  });

  factory DhikrItem.fromJson(Map<String, dynamic> json) {
    return DhikrItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      count: int.tryParse(json['count'].toString()) ?? 1,
      audio: json['audio'] ?? '',
      filename: json['filename'] ?? '',
      bless: json['bless'] ?? '',
    );
  }
}

class AdhkarCategory {
  final int id;
  final String category;
  final String audio;
  final String filename;
  final List<DhikrItem> items;

  const AdhkarCategory({
    required this.id,
    required this.category,
    required this.audio,
    required this.filename,
    required this.items,
  });

  factory AdhkarCategory.fromJson(Map<String, dynamic> json) {
    final list = json['array'] as List? ?? [];
    final itemsList = list.map((i) => DhikrItem.fromJson(i)).toList();

    return AdhkarCategory(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      audio: json['audio'] ?? '',
      filename: json['filename'] ?? '',
      items: itemsList,
    );
  }
}
