class CustomAlarm {
  final int id;
  final String title; // ✅ الحقل الجديد: اسم التنبيه
  final List<String> prayerNames;
  final int offsetMinutes;
  final bool isBefore;
  final String soundName;
  bool isEnabled;

  CustomAlarm({
    required this.id,
    required this.title, // ✅ مطلوب
    required this.prayerNames,
    required this.offsetMinutes,
    required this.isBefore,
    required this.soundName,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title, // ✅ حفظ
    'prayerNames': prayerNames,
    'offsetMinutes': offsetMinutes,
    'isBefore': isBefore,
    'soundName': soundName,
    'isEnabled': isEnabled,
  };

  factory CustomAlarm.fromJson(Map<String, dynamic> json) => CustomAlarm(
    id: json['id'],
    title: json['title'] ?? 'تنبيه مخصص', // ✅ استرجاع (مع قيمة افتراضية للقديم)
    prayerNames: List<String>.from(json['prayerNames'] ?? [json['prayerName']]),
    offsetMinutes: json['offsetMinutes'],
    isBefore: json['isBefore'],
    soundName: json['soundName'],
    isEnabled: json['isEnabled'],
  );
}