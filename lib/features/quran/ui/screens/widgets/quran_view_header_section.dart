import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/translations/app_locale_keys.dart';

class QuranViewHeaderSection extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final bool hasRecitations;
  final bool isBatchDownloading;
  final int downloadedCount;
  final int totalToDownload;
  final String mushafName;
  final Future<void> Function() onToggleBatchDownload;

  const QuranViewHeaderSection({
    super.key,
    required this.isDark,
    required this.isLoading,
    required this.hasRecitations,
    required this.isBatchDownloading,
    required this.downloadedCount,
    required this.totalToDownload,
    required this.mushafName,
    required this.onToggleBatchDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                mushafName,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF79D8C4)
                      : const Color(0xFF0F6A5C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isLoading && hasRecitations)
                GestureDetector(
                  onTap: onToggleBatchDownload,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isBatchDownloading
                          ? Colors.redAccent.withOpacity(0.1)
                          : (isDark
                              ? const Color(0xFFD4AF37).withOpacity(0.1)
                              : const Color(0xFFB8860B).withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isBatchDownloading
                            ? Colors.redAccent
                            : (isDark
                                ? const Color(0xFF79D8C4)
                                : const Color(0xFF0F6A5C)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isBatchDownloading
                              ? Icons.cancel_outlined
                              : Icons.download_rounded,
                          color: isBatchDownloading
                              ? Colors.redAccent
                              : (isDark
                                  ? const Color(0xFF79D8C4)
                                  : const Color(0xFF0F6A5C)),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isBatchDownloading
                              ? AppLocaleKeys.cancelDownload.tr
                              : AppLocaleKeys.downloadAll.tr,
                          style: TextStyle(
                            color: isBatchDownloading
                                ? Colors.redAccent
                                : (isDark
                                    ? const Color(0xFF79D8C4)
                                    : const Color(0xFF0F6A5C)),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isBatchDownloading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (isBatchDownloading && totalToDownload > 0)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'يتم الآن جدولة السور: $downloadedCount / $totalToDownload',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF79D8C4)
                              : const Color(0xFF0F6A5C),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((downloadedCount / totalToDownload) * 100).toInt()}%',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF79D8C4)
                              : const Color(0xFF0F6A5C),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: downloadedCount / totalToDownload,
                      backgroundColor: (isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFFB8860B))
                          .withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFFB8860B),
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
