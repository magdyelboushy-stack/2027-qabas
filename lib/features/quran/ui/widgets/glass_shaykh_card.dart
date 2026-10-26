import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:mihrab/core/utils/platform.dart';
import '../../data/models/shaykh.dart';

class GlassShaykhCard extends StatelessWidget {
  final Shaykh shaykh;
  final VoidCallback onViewQuran;

  const GlassShaykhCard({
    super.key,
    required this.shaykh,
    required this.onViewQuran,
  });

  String _getFixedUrl(String url) {
    if (isAndroid && url.contains('localhost')) {
      return url.replaceFirst('localhost', 'mihrab-app.alwaysdata.net').replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final String fixedImageUrl = _getFixedUrl(shaykh.imageUrl);

    // ✅ تحديد الثيم
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // الألوان
    final cardColor = isDark ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
    final shadowList = isDark ? <BoxShadow>[] : [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))];

    return GestureDetector(
      onTap: onViewQuran,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            decoration: BoxDecoration(
              // في الداكن: تدرج خفيف، في الفاتح: أبيض سادة
              gradient: isDark ? LinearGradient(
                colors: [
                  const Color.fromRGBO(2, 44, 131, 1).withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: isDark ? null : Colors.white,
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: shadowList,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- صورة الشيخ ---
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: (isDark ? Colors.cyanAccent : Colors.blueAccent).withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: fixedImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(fixedImageUrl)
                        : const AssetImage('assets/default_shaykh.png') as ImageProvider,
                  ),
                ),

                // --- المعلومات ---
                Column(
                  children: [
                    Text(
                      shaykh.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shaykh.bio.isNotEmpty ? shaykh.bio : 'قارئ للقرآن',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 11,
                        
                      ),
                    ),
                  ],
                ),

                // --- زر العرض ---
                SizedBox(
                  width: double.infinity,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: onViewQuran,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.cyanAccent.withOpacity(0.8) : Colors.blueAccent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'عرض المصحف',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        
                      ),
                    ),
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