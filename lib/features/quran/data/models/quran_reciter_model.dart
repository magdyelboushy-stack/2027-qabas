import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

/// موديل القارئ من Quran.Foundation API
class QuranReciterModel {
  final String id;
  final String reciterName;
  final String? style;
  final String translatedName;

  const QuranReciterModel({
    required this.id,
    required this.reciterName,
    this.style,
    required this.translatedName,
  });

  factory QuranReciterModel.fromJson(Map<String, dynamic> json) {
    return QuranReciterModel(
      id: json['id'].toString(),
      reciterName: json['reciter_name'] as String,
      style: json['style'] as String?,
      translatedName: json['translated_name']?['name'] as String? ?? json['reciter_name'] as String,
    );
  }

  /// الاسم الكامل مع الأسلوب (إن وجد)
  String get displayName {
    if (style != null && style!.isNotEmpty) {
      return '$reciterName ($style)';
    }
    return reciterName;
  }

  /// الاسم العربي المقابل
  String get arabicName {
    const nameMap = {
      'AbdulBaset AbdulSamad': 'عبد الباسط عبد الصمد',
      'Abdur-Rahman as-Sudais': 'عبد الرحمن السديس',
      'Abu Bakr al-Shatri': 'أبو بكر الشاطري',
      'Hani ar-Rifai': 'هاني الرفاعي',
      'Mahmoud Khalil Al-Husary': 'محمود خليل الحصري',
      'Mishari Rashid al-`Afasy': 'مشاري راشد العفاسي',
      'Mohamed Siddiq al-Minshawi': 'محمد صديق المنشاوي',
      'Sa`ud ash-Shuraym': 'سعود الشريم',
      'Mohamed al-Tablawi': 'محمد الطبلاوي',
      'Ali Jaber': 'علي جابر',
      'Yaser Salamah': 'ياسر سلامة',
    };
    final baseName = nameMap[reciterName] ?? (Get.locale?.languageCode == 'ar' ? reciterName : translatedName);
    if (style != null && style!.isNotEmpty) {
      final styleLoc = style == 'Murattal' ? AppLocaleKeys.reciterTypeMurattal.tr 
                     : style == 'Mujawwad' ? AppLocaleKeys.reciterTypeMujawwad.tr 
                     : style == 'Muallim' ? AppLocaleKeys.reciterTypeMuallim.tr 
                     : style!;
      return '$baseName ($styleLoc)';
    }
    return baseName;
  }

  /// تصنيف القارئ
  String get categoryName {
    if (style == 'Mujawwad' || style == 'مجود') return AppLocaleKeys.reciterTypeMujawwad.tr;
    if (style == 'Muallim' || style == 'معلم') return AppLocaleKeys.reciterTypeMuallim.tr;
    return AppLocaleKeys.reciterTypeMurattal.tr; // الافتراضي
  }
}
