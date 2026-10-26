import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- الألوان الفخمة (Dark Luxury) ---
  static const Color deepNavy = Color(0xFF0A1128); // كحلي غامق جداً
  static const Color royalBlue = Color(0xFF1C2541); // لون الكروت
  static const Color gold = Color(0xFFFFD700);      // ذهبي
  static const Color cyanGlow = Color(0xFF00E5FF);  // سماوي
  static const Color textWhite = Color(0xFFF8F9FA);

  // 1. الثيم الداكن (الأساسي - الفخم)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepNavy,
    primaryColor: gold,
    fontFamily: 'Cairo', // Local Asset Font

    // النصوص
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textWhite, fontFamily: 'Cairo'),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: gold, fontFamily: 'Cairo'), 
      bodyLarge: TextStyle(fontSize: 18, color: textWhite, fontFamily: 'Cairo'), 
      bodyMedium: TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Cairo'),
    ),

    // الأيقونات
    iconTheme: const IconThemeData(color: gold, size: 24),

    // الأزرار
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.black,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ),

    // البار العلوي
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textWhite),
      iconTheme: IconThemeData(color: textWhite),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
  );

  // 2. الثيم الفاتح (تمت إضافته لحل الخطأ)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // رمادي فاتح
    primaryColor: const Color(0xFF00695C), // أخضر إسلامي
    fontFamily: 'Cairo', // Local Asset Font - Changed from UthmanTN

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: 'Cairo'),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00695C), fontFamily: 'Cairo'),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.black87, fontFamily: 'Cairo'),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Cairo'),
    ),

    iconTheme: const IconThemeData(color: Color(0xFF00695C), size: 24),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      iconTheme: IconThemeData(color: Colors.black),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}
