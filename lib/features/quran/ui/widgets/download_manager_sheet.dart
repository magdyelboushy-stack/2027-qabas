import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/quran_audio_provider.dart';
import '../../logic/quran_download_provider.dart';

/// ويدجت إدارة تحميل صوتيات المصحف
class DownloadManagerSheet extends StatelessWidget {
  final bool isDark;

  const DownloadManagerSheet({super.key, required this.isDark});

  static void show(BuildContext context, {required bool isDark}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadManagerSheet(isDark: isDark),
    );
  }

  // أسماء السور
  static const List<String> _surahNames = [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
    "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
    "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
    "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
    "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
    "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
    "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
    "التكوير", "الانفطار", "المطففين", "الانشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
    "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
    "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
    "المسد", "الإخلاص", "الفلق", "الناس"
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFBE0);
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final cardColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'تحميل المصحف الصوتي',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: Consumer2<QuranAudioProvider, QuranDownloadProvider>(
                  builder: (context, audioProvider, downloadProvider, _) {
                    final reciterId = audioProvider.selectedReciterId;
                    final selectedReciter = audioProvider.reciters
                        .where((r) => r.id == reciterId)
                        .firstOrNull;

                    return Column(
                      children: [
                        // القارئ الحالي
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.record_voice_over, color: accentColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'القارئ: ${selectedReciter?.arabicName ?? 'غير محدد'}',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // زر تحميل الكل  
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: downloadProvider.isDownloadingAll
                                ? Column(
                                    children: [
                                      LinearProgressIndicator(
                                        value: downloadProvider.totalDownloaded / 114,
                                        color: accentColor,
                                        backgroundColor: accentColor.withOpacity(0.1),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'جاري التحميل... ${downloadProvider.totalDownloaded}/114',
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                          TextButton(
                                            onPressed: () => downloadProvider.cancelDownloadAll(),
                                            child: Text('إلغاء', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () => downloadProvider.downloadAll(reciterId),
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text('تحميل المصحف كامل'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Divider(height: 1),

                        // قائمة السور
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: 114,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (context, index) {
                              final surahNum = index + 1;
                              final status = downloadProvider.downloadStatuses[surahNum];
                              final isCompleted = status?.isCompleted ?? false;
                              final isDownloading = status?.isDownloading ?? false;

                              return FutureBuilder<bool>(
                                future: downloadProvider.isSurahDownloaded(reciterId, surahNum),
                                builder: (context, snapshot) {
                                  final isAlreadyDownloaded = snapshot.data ?? false;

                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: accentColor.withOpacity(0.15),
                                      child: Text(
                                        '$surahNum',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      _surahNames[index],
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: isAlreadyDownloaded || isCompleted
                                        ? Icon(Icons.check_circle, color: Colors.green, size: 22)
                                        : isDownloading
                                            ? SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  color: accentColor,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : IconButton(
                                                icon: Icon(Icons.download_outlined, color: accentColor, size: 22),
                                                onPressed: () => downloadProvider.downloadSurah(reciterId, surahNum),
                                              ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
