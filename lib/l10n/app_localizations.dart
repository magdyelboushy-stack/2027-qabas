import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق قبس'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @advancedRepeat.
  ///
  /// In ar, this message translates to:
  /// **'التكرار المتقدم'**
  String get advancedRepeat;

  /// No description provided for @advancedRepeatDesc.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص تكرار الآيات والمقاطع'**
  String get advancedRepeatDesc;

  /// No description provided for @advancedRepeatActive.
  ///
  /// In ar, this message translates to:
  /// **'تكرار مقطع مخصص نشط'**
  String get advancedRepeatActive;

  /// No description provided for @fromAyah.
  ///
  /// In ar, this message translates to:
  /// **'من آية'**
  String get fromAyah;

  /// No description provided for @toAyah.
  ///
  /// In ar, this message translates to:
  /// **'إلى آية'**
  String get toAyah;

  /// No description provided for @ayahRepeatCount.
  ///
  /// In ar, this message translates to:
  /// **'تكرار كل آية'**
  String get ayahRepeatCount;

  /// No description provided for @blockRepeatCount.
  ///
  /// In ar, this message translates to:
  /// **'تكرار المقطع كاملاً'**
  String get blockRepeatCount;

  /// No description provided for @startRecitation.
  ///
  /// In ar, this message translates to:
  /// **'بدء التلاوة'**
  String get startRecitation;

  /// No description provided for @noInternet.
  ///
  /// In ar, this message translates to:
  /// **'بدون إنترنت'**
  String get noInternet;

  /// No description provided for @recitationOfflineMessage.
  ///
  /// In ar, this message translates to:
  /// **'لن تتمكن من تشغيل التلاوات الآن. يمكنك فتح التنزيلات التي على جهازك.'**
  String get recitationOfflineMessage;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get ok;

  /// No description provided for @goToDownloads.
  ///
  /// In ar, this message translates to:
  /// **'الانتقال إلى التنزيلات'**
  String get goToDownloads;

  /// No description provided for @failedSendMessage.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال الرسالة'**
  String get failedSendMessage;

  /// No description provided for @settingsSavedSuccessAdhan.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات بنجاح وتحديث الأذان ✅'**
  String get settingsSavedSuccessAdhan;

  /// No description provided for @calculationMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get calculationMethod;

  /// No description provided for @egyptian.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get egyptian;

  /// No description provided for @ummAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى (السعودية)'**
  String get ummAlQura;

  /// No description provided for @muslimWorldLeague.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get muslimWorldLeague;

  /// No description provided for @karachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية بكراتشي'**
  String get karachi;

  /// No description provided for @northAmerica.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية (ISNA)'**
  String get northAmerica;

  /// No description provided for @dubai.
  ///
  /// In ar, this message translates to:
  /// **'دبي'**
  String get dubai;

  /// No description provided for @kuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get kuwait;

  /// No description provided for @qatar.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get qatar;

  /// No description provided for @turkey.
  ///
  /// In ar, this message translates to:
  /// **'تركيا'**
  String get turkey;

  /// No description provided for @cancelingDownloads.
  ///
  /// In ar, this message translates to:
  /// **'جاري إلغاء التحميلات...'**
  String get cancelingDownloads;

  /// No description provided for @noInternetConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.'**
  String get noInternetConnection;

  /// No description provided for @allSurahDownloaded.
  ///
  /// In ar, this message translates to:
  /// **'جميع السور محملة بالفعل'**
  String get allSurahDownloaded;

  /// No description provided for @downloadConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد التحميل'**
  String get downloadConfirmation;

  /// Download confirmation message with count of surahs
  ///
  /// In ar, this message translates to:
  /// **'سيتم تحميل {count} سورة'**
  String willDownloadSurah(int count);

  /// No description provided for @preview.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get preview;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get retry;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @lessons.
  ///
  /// In ar, this message translates to:
  /// **'دروس دينية'**
  String get lessons;

  /// No description provided for @gizaVoices.
  ///
  /// In ar, this message translates to:
  /// **'شيوخ الجيزة'**
  String get gizaVoices;

  /// No description provided for @tartil.
  ///
  /// In ar, this message translates to:
  /// **'ترتيل'**
  String get tartil;

  /// No description provided for @tajweed.
  ///
  /// In ar, this message translates to:
  /// **'تجويد'**
  String get tajweed;

  /// No description provided for @muteSound.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الصوت'**
  String get muteSound;

  /// No description provided for @openApp.
  ///
  /// In ar, this message translates to:
  /// **'فتح التطبيق'**
  String get openApp;

  /// No description provided for @stop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @signInWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بواسطة Google'**
  String get signInWithGoogle;

  /// No description provided for @fastingDays.
  ///
  /// In ar, this message translates to:
  /// **'أيام الصيام'**
  String get fastingDays;

  /// No description provided for @missedDays.
  ///
  /// In ar, this message translates to:
  /// **'الأيام الفائتة'**
  String get missedDays;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUs;

  /// No description provided for @updateLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط التحديث'**
  String get updateLink;

  /// No description provided for @targetCount.
  ///
  /// In ar, this message translates to:
  /// **'العدد المستهدف'**
  String get targetCount;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get reset;

  /// No description provided for @notificationDiagnosticsScreen.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص الإشعارات'**
  String get notificationDiagnosticsScreen;

  /// No description provided for @generalNotificationStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الإشعارات العامة'**
  String get generalNotificationStatus;

  /// No description provided for @scheduledNotificationsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الإشعارات المجدولة'**
  String get scheduledNotificationsCount;

  /// Label for scheduled notifications count
  ///
  /// In ar, this message translates to:
  /// **'{count} إشعار'**
  String scheduledCountLabel(int count);

  /// No description provided for @rescheduleNotificationsSuccess.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إعادة جدولة الإشعارات بنجاح'**
  String get rescheduleNotificationsSuccess;

  /// Error message when rescheduling notifications
  ///
  /// In ar, this message translates to:
  /// **'❌ خطأ أثناء الجدولة: {error}'**
  String rescheduleNotificationsError(String error);

  /// No description provided for @rescheduleNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إعادة جدولة الإشعارات'**
  String get rescheduleNotifications;

  /// No description provided for @updateInfo.
  ///
  /// In ar, this message translates to:
  /// **'تحديث المعلومات'**
  String get updateInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
