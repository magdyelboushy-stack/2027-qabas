import 'dart:ui';
import 'dart:math'; // لاستخدام الدالة العشوائية
import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart'; // فعل هذا السطر إذا أضفت مكتبة المشاركة

class VerseOfTheDayCard extends StatefulWidget {
  const VerseOfTheDayCard({super.key});

  @override
  State<VerseOfTheDayCard> createState() => _VerseOfTheDayCardState();
}

class _VerseOfTheDayCardState extends State<VerseOfTheDayCard> {
  // متغير لحفظ الآية المختارة
  late Map<String, String> _selectedVerse;

  // --- قائمة منتقاة لآيات مؤثرة ومبشرة ---
  final List<Map<String, String>> _influentialVerses = [
    {
      'text': 'وَمَنْ أَعْرَضَ عَن ذِكْرِي فَإِنَّ لَهُ مَعِيشَةً ضَنكًا وَنَحْشُرُهُ يَوْمَ الْقِيَامَةِ أَعْمَىٰ',
      'surah': 'سورة طه - الآية 124'
    },
    {
      'text': 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا * إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      'surah': 'سورة الشرح - الآية 5-6'
    },
    {
      'text': 'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
      'surah': 'سورة البقرة - الآية 186'
    },
    {
      'text': 'قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنفُسِهِمْ لَا تَقْنَطُوا مِن رَّحْمَةِ اللَّهِ ۚ إِنَّ اللَّهَ يَغْفِرُ الذُّنُوبَ جَمِيعًا',
      'surah': 'سورة الزمر - الآية 53'
    },
    {
      'text': 'وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ',
      'surah': 'سورة الضحى - الآية 5'
    },
    {
      'text': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      'surah': 'سورة الرعد - الآية 28'
    },
    {
      'text': 'وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا',
      'surah': 'سورة الطور - الآية 48'
    },
    {
      'text': 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      'surah': 'سورة البقرة - الآية 286'
    },
    {
      'text': 'إِنَّ اللَّهَ مَعَ الصَّابِرِينَ',
      'surah': 'سورة البقرة - الآية 153'
    },
    {
      'text': 'وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ',
      'surah': 'سورة غافر - الآية 60'
    },
    {
      'text': 'رَبَّنَا وَلَا تُحَمِّلْنَا مَا لَا طَاقَةَ لَنَا بِهِ',
      'surah': 'سورة البقرة - الآية 286'
    },
    {
      'text': 'فَدَعَا رَبَّهُ أَنِّي مَغْلُوبٌ ف انتَصِرْ',
      'surah': 'سورة القمر - الآية 10'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomVerse();
  }

  void _pickRandomVerse() {
    setState(() {
      _selectedVerse = _influentialVerses[Random().nextInt(_influentialVerses.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 1. تحديد الثيم الحالي
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ 2. تعريف الألوان بناءً على الوضع (Dark/Light)
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.cyanAccent.withOpacity(0.9) : Theme.of(context).primaryColor;
    final iconColor = isDark ? Colors.amber : Colors.amber.shade700;
    final dividerColor = isDark ? Colors.white24 : Colors.grey.shade300;

    // خلفية الكارت (زجاجية في الداكن / بيضاء في الفاتح)
    final cardColor = isDark ? Colors.cyanAccent.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            // إضافة ظل خفيف فقط في الوضع الفاتح ليبرز الكارت
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر (أيقونة وعنوان وزر تحديث)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'آية اليوم',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _pickRandomVerse,
                    child: Icon(Icons.refresh, color: isDark ? Colors.white54 : Colors.grey, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // نص الآية
              Center(
                child: Text(
                  '"${_selectedVerse['text']}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                     // خط قرآني
                    height: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // اسم السورة
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedVerse['surah']!,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Divider(color: dividerColor),

              // زر المشاركة
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // كود المشاركة (إذا فعلت مكتبة share_plus)
                      // Share.share('${_selectedVerse['text']} - ${_selectedVerse['surah']} \n\nتمت المشاركة من تطبيق قبس');
                    },
                    icon: Icon(Icons.share, color: isDark ? Colors.white70 : Colors.grey.shade600, size: 18),
                    label: Text(
                        'مشاركة',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, )
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}