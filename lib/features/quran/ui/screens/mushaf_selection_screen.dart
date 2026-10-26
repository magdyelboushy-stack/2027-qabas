import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/shaykh.dart';
import '../../data/models/mushaf_category.dart';
import 'quran_view_screen.dart'; // الشاشة التي سننتقل إليها
import 'series_detail_screen.dart'; // ✅ Import Series Detail Screen

class MushafSelectionScreen extends StatelessWidget {
  final Shaykh shaykh;

  const MushafSelectionScreen({super.key, required this.shaykh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnglish = Get.locale?.languageCode == 'en';
    final textColor = isDark ? Colors.white : const Color(0xFF0A1F1B);
    final hasMushafs = shaykh.availableMushafs.isNotEmpty;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A1F1B) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            isEnglish ? "Choose Mushaf" : "اختر المصحف", 
            style: TextStyle(
              color: textColor,  
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: hasMushafs
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          isEnglish ? "Sheikh ${shaykh.name}" : "الشيخ ${shaykh.name}",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C), 
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: shaykh.availableMushafs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final mushaf = shaykh.availableMushafs[index];
                            return _buildMushafItem(context, mushaf, isDark, isEnglish);
                          },
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF112824) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_off_outlined, 
                            size: 60, 
                            color: isDark ? const Color(0xFF35554D) : const Color(0xFFB0C4BF),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isEnglish 
                              ? 'No recitations available for this Sheikh' 
                              : 'لا توجد تلاوات متاحة لهذا الشيخ حالياً',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,  
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafItem(BuildContext context, MushafCategory mushaf, bool isDark, bool isEnglish) {
    final cardBg = isDark ? const Color(0xFF112824) : Colors.white;
    final iconBg = isDark ? const Color(0xFF173A34) : const Color(0xFFEAF5F1);
    final iconColor = isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C);
    final titleColor = isDark ? Colors.white : const Color(0xFF0A1F1B);
    final subColor = isDark ? const Color(0xFFA7C1BA) : const Color(0xFF6F8E87);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFF071513) : const Color(0xFF0A5448)).withOpacity(isDark ? 0.22 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (mushaf.isSeries) {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (ctx) => SeriesDetailScreen(
                     shaykh: shaykh,
                     series: mushaf,
                   ),
                 ),
               );
            } else {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (ctx) => QuranViewScreen(
                     shaykh: shaykh,
                     mushafId: mushaf.id,
                     mushafName: mushaf.name, 
                   ),
                 ),
               );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    mushaf.isSeries ? Icons.folder_open_rounded : Icons.library_books_rounded, 
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mushaf.name, 
                        style: TextStyle(
                          color: titleColor,  
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mushaf.totalSizeGB > 0 
                            ? "${mushaf.totalSizeGB.toStringAsFixed(2)} ${isEnglish ? 'GB' : 'جيجا'}"
                            : (mushaf.totalSizeMB > 0 
                                ? "${mushaf.totalSizeMB.toStringAsFixed(2)} ${isEnglish ? 'MB' : 'ميجابايت'}"
                                : (isEnglish ? "Tap to view" : "اضغط للعرض")),
                        style: TextStyle(
                          color: subColor, 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEnglish ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded, 
                    color: subColor.withOpacity(0.8), 
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
