import 'package:quran_library/quran_library.dart';

void bootstrapQuranController() {
  QuranCtrl.instance;
}

Future<void> initQuranLibrary() async {
  await QuranLibrary().init();
}

List<dynamic> getAllSurahsFromLibrary() {
  return QuranLibrary().getAllSurahs();
}
