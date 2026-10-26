import 'package:flutter/material.dart';

class AdhanTheme {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<Color> backgroundGradient;
  final String? backgroundImage;
  final Color prayerNameColor;
  final Color prayerTimeColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final bool showMosqueImage;
  final String? mosqueImagePath;
  final bool showPatterns;
  final double prayerNameSize;
  final double prayerTimeSize;

  const AdhanTheme({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.backgroundGradient,
    this.backgroundImage,
    required this.prayerNameColor,
    required this.prayerTimeColor,
    required this.buttonColor,
    required this.buttonTextColor,
    this.showMosqueImage = true,
    this.mosqueImagePath,
    this.showPatterns = true,
    this.prayerNameSize = 64.0,
    this.prayerTimeSize = 32.0,
  });

  // Pre-defined themes with beautiful, premium designs
  static const AdhanTheme classicMosque = AdhanTheme(
    id: 'classic_mosque',
    nameAr: 'الكلاسيكي',
    nameEn: 'Classic Mosque',
    backgroundGradient: [
      Color(0xFF0A4D68), // Deep ocean blue
      Color(0xFF088395), // Turquoise
      Color(0xFF05BFDB), // Bright cyan
    ],
    prayerNameColor: Color(0xFFFFD93D), // Bright gold
    prayerTimeColor: Color(0xFFF8F6F4), // Off-white
    buttonColor: Color(0xFFFFD93D), // Bright gold
    buttonTextColor: Color(0xFF0A4D68), // Deep blue
    showMosqueImage: true,
    showPatterns: true,
    prayerNameSize: 68.0,
  );

  static const AdhanTheme modernGradient = AdhanTheme(
    id: 'modern_gradient',
    nameAr: 'العصري',
    nameEn: 'Modern Gradient',
    backgroundGradient: [
      Color(0xFF6A00F4), // Deep purple
      Color(0xFF9D4EDD), // Medium purple
      Color(0xFFE0AAFF), // Light purple
    ],
    prayerNameColor: Color(0xFFFFFFFF), // Pure white
    prayerTimeColor: Color(0xFFE0AAFF), // Light purple
    buttonColor: Color(0xFFFFFFFF), // White
    buttonTextColor: Color(0xFF6A00F4), // Deep purple
    showMosqueImage: true,
    showPatterns: false,
    prayerNameSize: 72.0,
  );

  static const AdhanTheme elegantGold = AdhanTheme(
    id: 'elegant_gold',
    nameAr: 'الذهبي الفاخر',
    nameEn: 'Elegant Gold',
    backgroundGradient: [
      Color(0xFF000000), // Pure black
      Color(0xFF1A1A2E), // Dark navy
      Color(0xFF16213E), // Navy blue
    ],
    prayerNameColor: Color(0xFFFFD700), // Pure gold
    prayerTimeColor: Color(0xFFFFF8DC), // Cornsilk
    buttonColor: Color(0xFFFFD700), // Pure gold
    buttonTextColor: Color(0xFF000000), // Black
    showMosqueImage: true,
    showPatterns: true,
    prayerNameSize: 70.0,
  );

  static const AdhanTheme minimal = AdhanTheme(
    id: 'minimal',
    nameAr: 'البسيط',
    nameEn: 'Minimal',
    backgroundGradient: [
      Color(0xFF2C3E50), // Dark slate
      Color(0xFF34495E), // Medium slate
      Color(0xFF2C3E50), // Dark slate
    ],
    prayerNameColor: Color(0xFFECF0F1), // Light gray
    prayerTimeColor: Color(0xFFBDC3C7), // Silver
    buttonColor: Color(0xFFECF0F1), // Light gray
    buttonTextColor: Color(0xFF2C3E50), // Dark slate
    showMosqueImage: false,
    showPatterns: false,
    prayerNameSize: 76.0,
  );

  static const AdhanTheme emeraldNight = AdhanTheme(
    id: 'emerald_night',
    nameAr: 'الليل الزمردي',
    nameEn: 'Emerald Night',
    backgroundGradient: [
      Color(0xFF004D40), // Deep teal
      Color(0xFF00695C), // Teal
      Color(0xFF00897B), // Light teal
    ],
    prayerNameColor: Color(0xFF76FF03), // Bright lime
    prayerTimeColor: Color(0xFFE0F2F1), // Very light teal
    buttonColor: Color(0xFF76FF03), // Bright lime
    buttonTextColor: Color(0xFF004D40), // Deep teal
    showMosqueImage: true,
    showPatterns: true,
    prayerNameSize: 68.0,
  );

  static const AdhanTheme sunsetGlow = AdhanTheme(
    id: 'sunset_glow',
    nameAr: 'وهج الغروب',
    nameEn: 'Sunset Glow',
    backgroundGradient: [
      Color(0xFFFF6B6B), // Coral red
      Color(0xFFFF8E53), // Orange
      Color(0xFFFECA57), // Yellow
    ],
    prayerNameColor: Color(0xFFFFFFFF), // White
    prayerTimeColor: Color(0xFFFFF5E1), // Light yellow
    buttonColor: Color(0xFFFFFFFF), // White
    buttonTextColor: Color(0xFFFF6B6B), // Coral red
    showMosqueImage: true,
    showPatterns: false,
    prayerNameSize: 70.0,
  );

  static List<AdhanTheme> get allThemes => [
    classicMosque,
    modernGradient,
    elegantGold,
    emeraldNight,
    sunsetGlow,
    minimal,
  ];

  static AdhanTheme getById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => classicMosque,
    );
  }
}
