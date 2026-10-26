import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:quran/quran.dart' as quran_utils;

import 'package:mihrab/core/translations/app_locale_keys.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../logic/quran_audio_provider.dart';
import '../../logic/mushaf_download_manager.dart';

class MushafDownloadsScreen extends StatefulWidget {
  const MushafDownloadsScreen({super.key});

  @override
  State<MushafDownloadsScreen> createState() => _MushafDownloadsScreenState();
}

class _MushafDownloadsScreenState extends State<MushafDownloadsScreen> {
  late MushafDownloadManager _downloadManager;
  late String _currentReciterId;

  @override
  void initState() {
    super.initState();
    _downloadManager = MushafDownloadManager.instance;
    final audio = Provider.of<QuranAudioProvider>(context, listen: false);
    _currentReciterId = audio.selectedReciterId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadManager.checkAllSurahs(_currentReciterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final accent = isDark ? const Color(0xFF2A8B68) : const Color(0xFF00695C);
    final audio = Provider.of<QuranAudioProvider>(context);

    // If reciter changed, update the tracked reciter
    if (audio.selectedReciterId != _currentReciterId) {
      _currentReciterId = audio.selectedReciterId;
      _downloadManager.checkAllSurahs(_currentReciterId);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E241E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          Get.locale?.languageCode == 'ar' ? 'تنزيلات المصحف المرتل' : 'Mushaf Audio Downloads',
          style: TextStyle(
            fontFamily: 'Cairo',
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0E241E) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0.5,
      ),
      body: ListenableBuilder(
        listenable: _downloadManager,
        builder: (context, child) {
          int totalDownloadedAyahs = 0;
          for (int s = 1; s <= 114; s++) {
            totalDownloadedAyahs += _downloadManager.getStatus(_currentReciterId, s)?.downloadedAyahs ?? 0;
          }
          final double totalProgress = totalDownloadedAyahs / 6236;

          return Column(
            children: [
              // Header & Full Mushaf Download
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0E241E) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: accent.withOpacity(0.1),
                          child: Icon(Icons.person, color: accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 32,
                                child: Builder(
                                  builder: (context) {
                                    String? safeValue = _currentReciterId;
                                    if (audio.reciters.isNotEmpty) {
                                      final exists = audio.reciters.any((r) => r.id == _currentReciterId);
                                      if (!exists) {
                                        safeValue = audio.reciters.first.id;
                                        // Update state safely after build
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {
                                              _currentReciterId = safeValue!;
                                            });
                                            _downloadManager.checkAllSurahs(safeValue!);
                                          }
                                        });
                                      }
                                    }

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: safeValue,
                                        isExpanded: true,
                                        isDense: true,
                                        dropdownColor: isDark ? const Color(0xFF0E241E) : Colors.white,
                                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: accent),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        items: audio.reciters.map((reciter) {
                                          return DropdownMenuItem<String>(
                                            value: reciter.id,
                                            child: Text(
                                              reciter.arabicName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newId) {
                                          if (newId != null && newId != _currentReciterId) {
                                            setState(() {
                                              _currentReciterId = newId;
                                            });
                                            _downloadManager.checkAllSurahs(newId);
                                            audio.setReciter(newId); // Apply to the mushaf player too
                                          }
                                        },
                                      ),
                                    );
                                  }
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Get.locale?.languageCode == 'ar' ? "الآيات المحملة للشيخ المختار:" : "Downloaded Ayahs:"} $totalDownloadedAyahs / 6236',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_downloadManager.isMushafDownloading)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: totalProgress,
                            color: accent,
                            backgroundColor: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _downloadManager.cancelFullMushaf(_currentReciterId);
                              },
                              icon: const Icon(Icons.stop_rounded, color: Colors.red),
                              label: Text(
                                AppLocaleKeys.stopDownload.tr,
                                style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (totalDownloadedAyahs == 6236)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              Get.locale?.languageCode == 'ar' ? 'المصحف محمل بالكامل' : 'Mushaf Fully Downloaded',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _downloadManager.downloadFullMushaf(_currentReciterId);
                          },
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          label: Text(
                            Get.locale?.languageCode == 'ar' ? 'تحميل المصحف كاملاً' : 'Download Full Mushaf',
                            style: const TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Surahs List
              Expanded(
                child: ListView.builder(
                  itemCount: 114,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final surah = index + 1;
                    final isAr = Get.locale?.languageCode == 'ar';
                    final surahName = isAr ? quran_utils.getSurahNameArabic(surah) : quran_utils.getSurahNameEnglish(surah);
                    final verseCount = quran_utils.getVerseCount(surah);
                    final status = _downloadManager.getStatus(_currentReciterId, surah);
                    
                    final isDownloading = status?.isDownloading ?? false;
                    final isCompleted = status?.isCompleted ?? false;
                    final progress = status?.progress ?? 0.0;
                    final downloadedCount = status?.downloadedAyahs ?? 0;
                    final hasError = status?.errorMessage != null;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0E241E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasError ? Colors.red.withOpacity(0.5) : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$surah',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${isAr ? "سورة" : "Surah"} $surahName',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$verseCount ${isAr ? "آية" : "Ayahs"}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            if (hasError)
                              Text(
                                status!.errorMessage!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                              ),
                            if (isDownloading && !hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  color: accent,
                                  backgroundColor: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                          ],
                        ),
                        trailing: _buildTrailingAction(
                          surah,
                          isDownloading,
                          isCompleted,
                          downloadedCount,
                          verseCount,
                          accent,
                          hasError,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrailingAction(
    int surah,
    bool isDownloading,
    bool isCompleted,
    int downloadedCount,
    int totalAyahs,
    Color accent,
    bool hasError,
  ) {
    if (isCompleted) {
      return IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        onPressed: () {
          _downloadManager.deleteSurah(_currentReciterId, surah);
        },
      );
    }
    
    if (isDownloading && !hasError) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$downloadedCount/$totalAyahs',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_rounded, color: Colors.red),
            onPressed: () {
              _downloadManager.cancelDownload(_currentReciterId, surah);
            },
          ),
        ],
      );
    }

    return IconButton(
      icon: Icon(hasError ? Icons.refresh_rounded : Icons.download_rounded, color: accent),
      onPressed: () {
        _downloadManager.downloadSurah(_currentReciterId, surah);
      },
    );
  }
}
