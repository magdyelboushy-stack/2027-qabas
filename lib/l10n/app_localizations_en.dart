// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qabas App';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get advancedRepeat => 'Advanced Repeat';

  @override
  String get advancedRepeatDesc => 'Customize ayahs and block repeat';

  @override
  String get advancedRepeatActive => 'Custom block repeat active';

  @override
  String get fromAyah => 'From Ayah';

  @override
  String get toAyah => 'To Ayah';

  @override
  String get ayahRepeatCount => 'Ayah Repeat';

  @override
  String get blockRepeatCount => 'Block Repeat';

  @override
  String get startRecitation => 'Start Recitation';

  @override
  String get noInternet => 'No Internet';

  @override
  String get recitationOfflineMessage =>
      'You won\'t be able to play recitations now. You can open the downloads on your device.';

  @override
  String get ok => 'OK';

  @override
  String get goToDownloads => 'Go to Downloads';

  @override
  String get failedSendMessage => 'Failed to send message';

  @override
  String get settingsSavedSuccessAdhan =>
      'Settings saved successfully and adhan updated ✅';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get egyptian => 'Egyptian General Authority of Surveying';

  @override
  String get ummAlQura => 'Um Al-Qura (Saudi Arabia)';

  @override
  String get muslimWorldLeague => 'Muslim World League';

  @override
  String get karachi => 'Karachi University';

  @override
  String get northAmerica => 'North America (ISNA)';

  @override
  String get dubai => 'Dubai';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Qatar';

  @override
  String get turkey => 'Turkey';

  @override
  String get cancelingDownloads => 'Canceling downloads...';

  @override
  String get noInternetConnection =>
      'No internet connection. Please check the network.';

  @override
  String get allSurahDownloaded => 'All chapters are already downloaded';

  @override
  String get downloadConfirmation => 'Download Confirmation';

  @override
  String willDownloadSurah(int count) {
    return 'Will download $count chapter(s)';
  }

  @override
  String get preview => 'Preview';

  @override
  String get retry => 'Retry';

  @override
  String get all => 'All';

  @override
  String get lessons => 'Lessons';

  @override
  String get gizaVoices => 'Giza Voices';

  @override
  String get tartil => 'Tartil';

  @override
  String get tajweed => 'Tajweed';

  @override
  String get muteSound => 'Mute Sound';

  @override
  String get openApp => 'Open App';

  @override
  String get stop => 'Stop';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get signInWithGoogle => 'Sign In with Google';

  @override
  String get fastingDays => 'Fasting Days';

  @override
  String get missedDays => 'Missed Days';

  @override
  String get close => 'Close';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get updateLink => 'Update Link';

  @override
  String get targetCount => 'Target Count';

  @override
  String get reset => 'Reset';

  @override
  String get notificationDiagnosticsScreen => 'Notification Diagnostics';

  @override
  String get generalNotificationStatus => 'General Notification Status';

  @override
  String get scheduledNotificationsCount => 'Scheduled Notifications Count';

  @override
  String scheduledCountLabel(int count) {
    return '$count notification(s)';
  }

  @override
  String get rescheduleNotificationsSuccess =>
      '✅ Notifications rescheduled successfully';

  @override
  String rescheduleNotificationsError(String error) {
    return '❌ Rescheduling error: $error';
  }

  @override
  String get rescheduleNotifications => 'Reschedule Notifications';

  @override
  String get updateInfo => 'Update Info';
}
