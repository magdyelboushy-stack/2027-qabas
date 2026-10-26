// هذا الموديل يمثل المصحف الذي تم اختياره (تراويح، مرتل، إلخ) - Updated



class MushafCategory {
  final String id;
  final String name;
  final double totalSizeGB; // ✅ حجم المصحف بالجيجا
  final double totalSizeMB; // ✅ حجم المصحف بالميجا (جديد)
  final bool isSeries; // ✅ هل هو سلسلة (مجلد)؟

  MushafCategory({
    required this.id, 
    required this.name,
    this.totalSizeGB = 0,
    this.totalSizeMB = 0,
    this.isSeries = false,
  });

  factory MushafCategory.fromJson(Map<String, dynamic> json) {
    return MushafCategory(
      id: json['id'].toString(),
      name: json['name'] ?? 'مصحف عام',
      totalSizeGB: double.tryParse(json['total_size_gb']?.toString() ?? '0') ?? 0,
      totalSizeMB: double.tryParse(json['total_size_mb']?.toString() ?? '0') ?? 0,
      isSeries: json['is_series'] == true || json['is_series'] == 1 || json['is_series'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total_size_gb': totalSizeGB,
      'total_size_mb': totalSizeMB,
      'is_series': isSeries,
    };
  }
}