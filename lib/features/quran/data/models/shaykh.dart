import 'mushaf_category.dart'; // ✅ استيراد الموديل الجديد

class Shaykh {
  final String id;
  final String name;
  final String bio;
  final String imageUrl;
  final String category;
  final List<MushafCategory> availableMushafs; // ✅ القائمة الجديدة

  const Shaykh({
    required this.id,
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.category,
    this.availableMushafs = const [],
  });

  factory Shaykh.fromJson(Map<String, dynamic> json) {
    List<MushafCategory> mushafs = [];
    if (json['mushafs'] != null && json['mushafs'] is List) {
      mushafs = (json['mushafs'] as List)
          .map((e) => MushafCategory.fromJson(e))
          .toList();
    }

    return Shaykh(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      bio: json['bio'] ?? 'قارئ القرآن الكريم',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? 'egyptian',
      availableMushafs: mushafs, // ✅
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'image_url': imageUrl,
      'category': category,
      'mushafs': availableMushafs.map((m) => m.toJson()).toList(),
    };
  }
}