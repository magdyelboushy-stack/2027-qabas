class SurahDatabaseService {
  SurahDatabaseService._();
  static final SurahDatabaseService instance = SurahDatabaseService._();

  Future<void> initialize() async {}

  Future<String?> getWordMeaning(int suraId, int ayaId, int wordId) async =>
      null;

  Future<String?> getWordEerab(int suraId, int ayaId, int wordId) async =>
      null;

  Future<String?> getWordTasreef(int suraId, int ayaId, int wordId) async =>
      null;

  Future<List<Map<String, dynamic>>> getAyaWordsWithMeanings(
          int suraId, int ayaId) async =>
      const [];

  Future<List<Map<String, dynamic>>> searchWordInQuran(String word) async =>
      const [];

  Future<String?> getTafsirMoyassar(int suraId, int ayaId) async => null;

  Future<String?> getTafsirSaadi(int suraId, int ayaId) async => null;

  Future<String?> getTafsirKatheer(int suraId, int ayaId) async => null;

  Future<String?> getTafsirTabary(int suraId, int ayaId) async => null;

  Future<String?> getTafsirBaghawy(int suraId, int ayaId) async => null;

  Future<String?> getTafsirMokhtasar(int suraId, int ayaId) async => null;

  Future<String?> getTafsirByName(String name, int suraId, int ayaId) async =>
      null;

  Future<String?> getAyaEerab(int suraId, int ayaId) async => null;

  Future<String?> getAyaWordEerab(int suraId, int ayaId) async => null;

  Future<String?> getAyaNozool(int suraId, int ayaId) async => null;

  Future<String?> getAyaTajweed(int suraId, int ayaId) async => null;

  Future<String?> getEnglishTranslation(int suraId, int ayaId) async => null;

  Future<void> dispose() async {}
}
