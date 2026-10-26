// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق قبس';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get advancedRepeat => 'التكرار المتقدم';

  @override
  String get advancedRepeatDesc => 'تخصيص تكرار الآيات والمقاطع';

  @override
  String get advancedRepeatActive => 'تكرار مقطع مخصص نشط';

  @override
  String get fromAyah => 'من آية';

  @override
  String get toAyah => 'إلى آية';

  @override
  String get ayahRepeatCount => 'تكرار كل آية';

  @override
  String get blockRepeatCount => 'تكرار المقطع كاملاً';

  @override
  String get startRecitation => 'بدء التلاوة';

  @override
  String get noInternet => 'بدون إنترنت';

  @override
  String get recitationOfflineMessage =>
      'لن تتمكن من تشغيل التلاوات الآن. يمكنك فتح التنزيلات التي على جهازك.';

  @override
  String get ok => 'حسناً';

  @override
  String get goToDownloads => 'الانتقال إلى التنزيلات';

  @override
  String get failedSendMessage => 'فشل إرسال الرسالة';

  @override
  String get settingsSavedSuccessAdhan =>
      'تم حفظ الإعدادات بنجاح وتحديث الأذان ✅';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get egyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get ummAlQura => 'أم القرى (السعودية)';

  @override
  String get muslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get karachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get northAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get dubai => 'دبي';

  @override
  String get kuwait => 'الكويت';

  @override
  String get qatar => 'قطر';

  @override
  String get turkey => 'تركيا';

  @override
  String get cancelingDownloads => 'جاري إلغاء التحميلات...';

  @override
  String get noInternetConnection =>
      'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get allSurahDownloaded => 'جميع السور محملة بالفعل';

  @override
  String get downloadConfirmation => 'تأكيد التحميل';

  @override
  String willDownloadSurah(int count) {
    return 'سيتم تحميل $count سورة';
  }

  @override
  String get preview => 'معاينة';

  @override
  String get retry => 'إعادة';

  @override
  String get all => 'الكل';

  @override
  String get lessons => 'دروس دينية';

  @override
  String get gizaVoices => 'شيوخ الجيزة';

  @override
  String get tartil => 'ترتيل';

  @override
  String get tajweed => 'تجويد';

  @override
  String get muteSound => 'إيقاف الصوت';

  @override
  String get openApp => 'فتح التطبيق';

  @override
  String get stop => 'إيقاف';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get play => 'تشغيل';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بواسطة Google';

  @override
  String get fastingDays => 'أيام الصيام';

  @override
  String get missedDays => 'الأيام الفائتة';

  @override
  String get close => 'إغلاق';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get updateLink => 'رابط التحديث';

  @override
  String get targetCount => 'العدد المستهدف';

  @override
  String get reset => 'تصفير';

  @override
  String get notificationDiagnosticsScreen => 'تشخيص الإشعارات';

  @override
  String get generalNotificationStatus => 'حالة الإشعارات العامة';

  @override
  String get scheduledNotificationsCount => 'عدد الإشعارات المجدولة';

  @override
  String scheduledCountLabel(int count) {
    return '$count إشعار';
  }

  @override
  String get rescheduleNotificationsSuccess =>
      '✅ تم إعادة جدولة الإشعارات بنجاح';

  @override
  String rescheduleNotificationsError(String error) {
    return '❌ خطأ أثناء الجدولة: $error';
  }

  @override
  String get rescheduleNotifications => 'إعادة جدولة الإشعارات';

  @override
  String get updateInfo => 'تحديث المعلومات';
}
