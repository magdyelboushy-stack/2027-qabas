import 'package:flutter/material.dart';
import 'last_read_card.dart';

class TopHeaderSection extends StatelessWidget {
  const TopHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350, // ارتفاع كافي للـ Stack
      child: Stack(
        clipBehavior: Clip.none, // <--- هام: للسماح للصورة بالظهور خارج حدود الـ SizedBox
        alignment: Alignment.topCenter,
        children: [
          // 1.1. صورة المصحف (الطبقة الخلفية) - تقليل الارتفاع وإعادة الضبط لـ top: 0
          Positioned(
            top: -50, // <--- نرفعه قليلاً (20 بكسل) ليظهر الجزء العلوي
            child: Image.asset(
              'assets/quran_book.png',
              height: 500, // <--- تعديل الارتفاع إلى 350
            ),
          ),

          // 1.2. كارت "Last Read" الزجاجي (الطبقة الأمامية) - رفع الكارد للأعلى
          Positioned(
            top: 100, // <--- رفع الكارد ليصبح على ارتفاع 100 بكسل فقط
            left: 16,
            right: 16,
            child: LastReadCard(
              lastReadSurah: 'Al-Fatihah',
              lastReadAyah: '1',
            ),
          ),
        ],
      ),
    );
  }
}