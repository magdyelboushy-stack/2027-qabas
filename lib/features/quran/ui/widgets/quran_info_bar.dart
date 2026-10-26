import 'package:flutter/material.dart';

/// Quran Info Bar - شريط معلومات القرآن
/// يعرض الحزب والصفحة وزر "الدارات"
class QuranInfoBar extends StatelessWidget {
  final int currentPage;
  final bool isDark;
  final VoidCallback? onDaratPressed;
  
  const QuranInfoBar({
    super.key,
    required this.currentPage,
    required this.isDark,
    this.onDaratPressed,
  });

  @override
  Widget build(BuildContext context) {
    // حساب رقم الحزب (كل 10 صفحات = حزب واحد تقريباً)
    final hizbNumber = ((currentPage - 1) ~/ 10) + 1;
    
    final Color bgColor = isDark ? const Color(0xff2A2A2A) : const Color(0xFFFFF8E0);
    final Color textColor = isDark ? Colors.white70 : const Color(0xFF8B6F47);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFF8B6F47).withOpacity(0.2);

    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الحزب (اليسار)
          Text(
            "الحزب $hizbNumber",
            style: TextStyle(
              
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          
          // الصفحة (الوسط)
          Text(
            "الصفحة $currentPage",
            style: TextStyle(
              
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          
          // الدارات (اليمين)
          InkWell(
            onTap: onDaratPressed,
            child: Row(
              children: [
                Text(
                  "الدارات",
                  style: TextStyle(
                    
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.menu_book_rounded,
                  size: 18,
                  color: textColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
