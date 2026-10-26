import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran_utils;
import '../data/services/quran_foundation_api.dart';
import '../data/models/quran_reciter_model.dart';
import '../data/models/quran_word_model.dart';

import '../logic/global_audio_manager.dart';
import 'mushaf_download_manager.dart';
import 'package:get/get.dart';

/// Provider مركزي للتحكم في تشغيل صوتيات القرآن
class QuranAudioProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = GlobalAudioManager().player;

  // الحالة
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _errorMessage;

  // القارئ الحالي
  String _selectedReciterId = '7'; // العفاسي افتراضيًا
  List<QuranReciterModel> _reciters = [];

  // التكرار
  int _repeatCount = 1; // عدد التكرارات (1 = مرة واحدة, -1 = تكرار لا نهائي)
  int _currentRepeat = 0;
  bool _isRepeating = false;

  // التشغيل المستمر وسرعة التشغيل
  bool _continuousPlayback = false;
  double _playbackSpeed = 1.0;

  // الآية الحالية
  int? _currentSurah;
  int? _currentAyah;

  // التكرار المتقدم
  bool _isAdvancedRepeat = false;
  int? _advancedStartSurah;
  int? _advancedStartAyah;
  int? _advancedEndSurah;
  int? _advancedEndAyah;
  int _advancedBlockRepeatCount = 1; // -1 for infinite
  int _currentAdvancedBlockRepeat = 1;

  // Getters
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String? get errorMessage => _errorMessage;
  String get selectedReciterId => _selectedReciterId;
  List<QuranReciterModel> get reciters => _reciters;
  int get repeatCount => _repeatCount;
  int get currentRepeat => _currentRepeat;
  bool get isRepeating => _isRepeating;
  bool get continuousPlayback => _continuousPlayback;
  double get playbackSpeed => _playbackSpeed;
  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  AudioPlayer get audioPlayer => _audioPlayer;

  bool get hasActiveSession => _currentSurah != null && _currentAyah != null;
  bool get isAdvancedRepeat => _isAdvancedRepeat;

  /// اسم القارئ الحالي
  String get currentReciterName {
    try {
      final reciter = _reciters.firstWhere(
        (r) => r.id == _selectedReciterId,
      );
      return reciter.arabicName;
    } catch (_) {
      return Get.locale?.languageCode == 'ar' ? 'قارئ غير معروف' : 'Unknown Reciter';
    }
  }

  /// اسم السورة الحالية
  String get currentSurahName {
    if (_currentSurah == null) return '';
    return quran_utils.getSurahNameArabic(_currentSurah!);
  }

  QuranAudioProvider() {
    _loadSavedReciter();
    _loadSavedSettings();
    _setupPlayerListener();
    loadReciters();
  }

  /// تحميل القارئ المحفوظ
  Future<void> _loadSavedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    // Support legacy int values
    final savedVal = prefs.get('selected_quran_reciter_id');
    if (savedVal != null) {
      _selectedReciterId = savedVal.toString();
    } else {
      _selectedReciterId = '7';
    }
    notifyListeners();
  }

  /// تحميل الإعدادات المحفوظة
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _continuousPlayback = prefs.getBool('quran_continuous_playback') ?? false;
    _repeatCount = prefs.getInt('quran_repeat_count') ?? 1;
    _playbackSpeed = prefs.getDouble('quran_playback_speed') ?? 1.0;
    _audioPlayer.setSpeed(_playbackSpeed);
    notifyListeners();
  }

  /// حفظ القارئ المختار
  Future<void> _saveReciter(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_quran_reciter_id', reciterId);
  }

  /// حفظ الإعدادات
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quran_continuous_playback', _continuousPlayback);
    await prefs.setInt('quran_repeat_count', _repeatCount);
    await prefs.setDouble('quran_playback_speed', _playbackSpeed);
  }

  ConcatenatingAudioSource? _playlist;
  bool _isPreloading = false;

  /// إعداد مراقب حالة المشغل
  void _setupPlayerListener() {
    _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      
      // عند انتهاء التشغيل (وصل لنهاية القائمة)
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
        _isRepeating = false;
        _currentRepeat = 0;
      }
      
      if (wasPlaying != _isPlaying || state.processingState == ProcessingState.completed) {
        notifyListeners();
      }
    });

    // مراقب تغيير المقطع الحالي - أكثر دقة من sequenceStateStream
    _audioPlayer.currentIndexStream.listen((index) {
      if (index == null || _playlist == null) return;
      if (index < 0 || index >= _playlist!.children.length) return;
      
      _updateCurrentAyahFromIndex(index);
    });

    _audioPlayer.sequenceStateStream.listen((state) {
      if (state?.currentSource == null) return;
      
      final tag = state!.currentSource!.tag as MediaItem;
      int? s;
      int? a;
      
      // نستخرج السورة والآية من الـ ID لتجنب مشاكل نقل extras في الخلفية
      final parts = tag.id.split('_');
      if (parts.length >= 3 && parts[0] == 'ayah') {
        s = int.tryParse(parts[1]);
        a = int.tryParse(parts[2]);
      }
      
      if (s != null && a != null) {
        bool changed = false;
        if (_currentSurah != s || _currentAyah != a) {
          _currentSurah = s;
          _currentAyah = a;
          changed = true;
        }

        // حساب عدد مرات تكرار الآية الحالية التي تم تشغيلها حتى الآن
        if (_playlist != null && state.currentIndex >= 0) {
          int repeatCountSoFar = 0;
          for (int i = 0; i <= state.currentIndex; i++) {
            if (i < _playlist!.children.length) {
              final t = _playlist!.children[i].sequence.first.tag as MediaItem;
              final tParts = t.id.split('_');
              if (tParts.length >= 3 && tParts[1] == s.toString() && tParts[2] == a.toString()) {
                repeatCountSoFar++;
              }
            }
          }
          _currentRepeat = repeatCountSoFar;
          changed = true;
        }

        if (changed) notifyListeners();

        // التجهيز المسبق للآية التالية (Preloading)
        if (_continuousPlayback && _playlist != null) {
          if (state.currentIndex >= _playlist!.children.length - 2) {
            _preloadNextAyah(s, a);
          }
        }
      }
    });
  }

  /// تحديث الآية الحالية من فهرس المقطع
  void _updateCurrentAyahFromIndex(int index) {
    if (_playlist == null || index >= _playlist!.children.length) return;
    
    try {
      final tag = _playlist!.children[index].sequence.first.tag as MediaItem;
      final parts = tag.id.split('_');
      if (parts.length >= 3 && parts[0] == 'ayah') {
        final s = int.tryParse(parts[1]);
        final a = int.tryParse(parts[2]);
        if (s != null && a != null && (_currentSurah != s || _currentAyah != a)) {
          _currentSurah = s;
          _currentAyah = a;
          debugPrint('🎵 انتقل للآية: سورة $s آية $a');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تحديث الآية من الفهرس: $e');
    }
  }

  /// التجهيز المسبق للآية التالية في الخلفية
  Future<void> _preloadNextAyah(int currentS, int currentA) async {
    if (_isPreloading || _playlist == null) return;
    _isPreloading = true;

    try {
      final totalVerses = quran_utils.getVerseCount(currentS);
      int nextS = currentS;
      int nextA = currentA + 1;

      if (_isAdvancedRepeat) {
        if (currentS == _advancedEndSurah && currentA == _advancedEndAyah) {
          if (_advancedBlockRepeatCount == -1 || _currentAdvancedBlockRepeat < _advancedBlockRepeatCount) {
            _currentAdvancedBlockRepeat++;
            nextS = _advancedStartSurah!;
            nextA = _advancedStartAyah!;
          } else {
            _isPreloading = false;
            return; // انتهى تكرار المقطع
          }
        } else {
          if (nextA > totalVerses) {
            if (currentS < 114) {
              nextS = currentS + 1;
              nextA = 1;
            } else {
              _isPreloading = false;
              return;
            }
          }
        }
      } else {
        if (nextA > totalVerses) {
          if (currentS < 114) {
            nextS = currentS + 1;
            nextA = 1;
          } else {
            _isPreloading = false;
            return; // وصلنا لنهاية المصحف
          }
        }
      }
      // تحقق مما إذا كانت الآية (للنطاق/اللفة الحالية) موجودة في آخر القائمة
      bool alreadyExists = false;
      if (_playlist!.children.isNotEmpty) {
        // نتحقق من آخر عناصر في الـ playlist (بدل البحث في كل القائمة التي قد تحتوي على لفات سابقة)
        final lastElementsCount = _repeatCount == -1 ? 1 : _repeatCount;
        final startCheckIndex = _playlist!.children.length > lastElementsCount 
            ? _playlist!.children.length - lastElementsCount 
            : 0;
            
        for (int i = startCheckIndex; i < _playlist!.children.length; i++) {
          final tag = _playlist!.children[i].sequence.first.tag as MediaItem;
          final parts = tag.id.split('_');
          if (parts.length >= 3 && parts[1] == nextS.toString() && parts[2] == nextA.toString()) {
            // نتحقق أيضاً من اللفة الحالية إذا كان تكرار متقدم
            if (_isAdvancedRepeat) {
              final blockStr = 'block$_currentAdvancedBlockRepeat';
              if (tag.id.contains(blockStr)) {
                alreadyExists = true;
                break;
              }
            } else {
              alreadyExists = true;
              break;
            }
          }
        }
      }

      if (!alreadyExists) {
        final localPath = await MushafDownloadManager.getLocalAyahPath(
          _selectedReciterId,
          nextS,
          nextA,
        );
        final isLocal = localPath != null;

        String? audioUrl;
        if (!isLocal) {
          audioUrl = await QuranFoundationApi.getAyahAudioUrl(
            _selectedReciterId,
            nextS,
            nextA,
          );
        }

        // إضافة حسب التكرار — كل تكرار يحتاج AudioSource و MediaItem id مستقل
        final repeats = _repeatCount == -1 ? 1 : _repeatCount;
        for (int i = 0; i < repeats; i++) {
          final blockTag = _isAdvancedRepeat ? '_block$_currentAdvancedBlockRepeat' : '';
          
          AudioSource source;
          if (isLocal) {
            source = AudioSource.file(
              localPath!,
              tag: MediaItem(
                id: 'ayah_${nextS}_${nextA}_$i$blockTag',
                title: '${quran_utils.getSurahNameArabic(nextS)} - آية $nextA',
                album: 'القرآن الكريم',
                extras: {'surah': nextS, 'ayah': nextA},
              ),
            );
          } else if (audioUrl != null) {
            final separator = audioUrl.contains('?') ? '&' : '?';
            final uniqueUrl = '$audioUrl${separator}repeat=$i&block=$_currentAdvancedBlockRepeat';
            source = AudioSource.uri(
              Uri.parse(uniqueUrl),
              tag: MediaItem(
                id: 'ayah_${nextS}_${nextA}_$i$blockTag',
                title: '${quran_utils.getSurahNameArabic(nextS)} - آية $nextA',
                album: 'القرآن الكريم',
                extras: {'surah': nextS, 'ayah': nextA},
              ),
            );
          } else {
            continue;
          }
          await _playlist!.add(source);
        }
      }
    } catch (e) {
      debugPrint('⚠️ فشل التجهيز المسبق للآية التالية: $e');
    } finally {
      _isPreloading = false;
    }
  }

  /// تشغيل الآية السابقة
  Future<void> playPreviousAyah() async {
    if (_currentSurah == null || _currentAyah == null) return;

    // إذا كنا في قائمة تشغيل، يمكننا الرجوع للعنصر السابق
    if (_playlist != null && _audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
      return;
    }

    int prevSurah = _currentSurah!;
    int prevAyah = _currentAyah! - 1;

    if (prevAyah < 1) {
      if (_currentSurah! > 1) {
        prevSurah = _currentSurah! - 1;
        prevAyah = quran_utils.getVerseCount(prevSurah);
      } else {
        return;
      }
    }

    await playAyah(prevSurah, prevAyah);
  }

  /// الانتقال للآية التالية يدوياً
  Future<void> playNextAyahManual() async {
    if (_playlist != null && _audioPlayer.hasNext) {
      // نتخطى كل التكرارات للآية الحالية وننتقل للآية التي تليها
      int? nextIndex;
      final currentIndex = _audioPlayer.currentIndex ?? 0;
      for (int i = currentIndex + 1; i < _playlist!.children.length; i++) {
        final tag = _playlist!.children[i].sequence.first.tag as MediaItem;
        final parts = tag.id.split('_');
        if (parts.length >= 3 && (parts[1] != _currentSurah.toString() || parts[2] != _currentAyah.toString())) {
          nextIndex = i;
          break;
        }
      }
      
      if (nextIndex != null) {
        await _audioPlayer.seek(Duration.zero, index: nextIndex);
        return;
      }
    }

    // إذا لم تكن القائمة تحتوي على الآية التالية بعد (أو نلعب بدون متابعة مستمرة)
    if (_currentSurah == null || _currentAyah == null) return;
    final totalVerses = quran_utils.getVerseCount(_currentSurah!);
    int nextS = _currentSurah!;
    int nextA = _currentAyah! + 1;
    if (nextA > totalVerses) {
      if (_currentSurah! < 114) {
        nextS = _currentSurah! + 1;
        nextA = 1;
      } else {
        return;
      }
    }
    await playAyah(nextS, nextA);
  }

  /// جلب قائمة القراء
  Future<void> loadReciters() async {
    try {
      final data = await QuranFoundationApi.getReciters();
      _reciters = data.map((json) => QuranReciterModel.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في جلب القراء: $e');
    }
  }

  /// تغيير القارئ
  void setReciter(String reciterId) {
    _selectedReciterId = reciterId;
    _saveReciter(reciterId);
    notifyListeners();
    
    // إذا كان يقرأ حالياً، نوقف ونبدأ من نفس الآية بالقارئ الجديد
    if (_currentSurah != null && _currentAyah != null) {
      playAyah(_currentSurah!, _currentAyah!);
    }
  }

  /// تبديل التشغيل المستمر
  void toggleContinuousPlayback() {
    _continuousPlayback = !_continuousPlayback;
    _saveSettings();
    notifyListeners();
    if (_continuousPlayback && _currentSurah != null && _currentAyah != null) {
      _preloadNextAyah(_currentSurah!, _currentAyah!);
    }
  }

  /// تعيين التشغيل المستمر
  void setContinuousPlayback(bool value) {
    _continuousPlayback = value;
    _saveSettings();
    notifyListeners();
    if (_continuousPlayback && _currentSurah != null && _currentAyah != null) {
      _preloadNextAyah(_currentSurah!, _currentAyah!);
    }
  }

  /// تحديد عدد التكرارات
  void setRepeatCount(int count) {
    if (_repeatCount == count) return;
    
    _repeatCount = count;
    _saveSettings();
    notifyListeners();
    
    // تحديث نمط التكرار في المشغل لو كان لا نهائي
    if (_repeatCount == -1) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    
    // إعادة تشغيل الآية الحالية لتطبيق إعداد التكرار الجديد فوراً
    if (_isPlaying && _currentSurah != null && _currentAyah != null) {
      playAyah(_currentSurah!, _currentAyah!);
    }
  }

  /// تغيير سرعة التشغيل
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    _audioPlayer.setSpeed(speed);
    _saveSettings();
    notifyListeners();
  }

  /// تشغيل صوت آية
  Future<void> playAyah(int surahNumber, int ayahNumber, {int? repeat}) async {
    _isAdvancedRepeat = false; // تعطيل التكرار المتقدم
    _isLoading = true;
    _errorMessage = null;
    _currentSurah = surahNumber;
    _currentAyah = ayahNumber;
    if (repeat != null) {
      _repeatCount = repeat;
    }
    _currentRepeat = 1;
    _isRepeating = _repeatCount > 1 || _repeatCount == -1;
    
    if (_repeatCount == -1) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }
    
    notifyListeners();

    try {
      final localPath = await MushafDownloadManager.getLocalAyahPath(
        _selectedReciterId,
        surahNumber,
        ayahNumber,
      );
      final isLocal = localPath != null;

      String? audioUrl;
      if (!isLocal) {
        audioUrl = await QuranFoundationApi.getAyahAudioUrl(
          _selectedReciterId,
          surahNumber,
          ayahNumber,
        );
      }

      debugPrint('🎵 محاولة تشغيل: ${isLocal ? "محلي $localPath" : audioUrl}');

      // كل تكرار يحتاج AudioSource و MediaItem id مستقل (just_audio لا يدعم نفس الكائن عدة مرات)
      _playlist = ConcatenatingAudioSource(children: []);
      final repeats = _repeatCount == -1 ? 1 : _repeatCount;
      for (int i = 0; i < repeats; i++) {
        AudioSource source;
        if (isLocal) {
          source = AudioSource.file(
            localPath!,
            tag: MediaItem(
              id: 'ayah_${surahNumber}_${ayahNumber}_$i',
              title: '${quran_utils.getSurahNameArabic(surahNumber)} - آية $ayahNumber',
              album: 'القرآن الكريم',
              extras: {'surah': surahNumber, 'ayah': ayahNumber},
            ),
          );
        } else if (audioUrl != null) {
          final separator = audioUrl.contains('?') ? '&' : '?';
          final uniqueUrl = '$audioUrl${separator}repeat=$i';
          source = AudioSource.uri(
            Uri.parse(uniqueUrl),
            tag: MediaItem(
              id: 'ayah_${surahNumber}_${ayahNumber}_$i',
              title: '${quran_utils.getSurahNameArabic(surahNumber)} - آية $ayahNumber',
              album: 'القرآن الكريم',
              extras: {'surah': surahNumber, 'ayah': ayahNumber},
            ),
          );
        } else {
          continue;
        }
        await _playlist!.add(source);
      }

      await _audioPlayer.setAudioSource(_playlist!);
      
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      
      _audioPlayer.play();
      
      // نبدأ تجهيز الآية التالية لو المتابعة شغالة
      if (_continuousPlayback) {
        _preloadNextAyah(surahNumber, ayahNumber);
      }
    } catch (e) {
      _isLoading = false;
      
      final isAr = Get.locale?.languageCode == 'ar';
      final errorStr = e.toString().toLowerCase();
      bool noInternet = errorStr.contains('socketexception') || 
                        errorStr.contains('failed host lookup') || 
                        errorStr.contains('clientexception');
                        
      if (e is PlayerException) {
        if (e.message?.toLowerCase().contains('socketexception') == true ||
            e.message?.toLowerCase().contains('failed host lookup') == true) {
          noInternet = true;
        }
      }
      
      if (noInternet) {
        _errorMessage = isAr 
            ? 'لا يوجد اتصال بالإنترنت. يرجى تحميل السورة أولاً للاستماع بدون إنترنت.'
            : 'No internet connection. Please download the Surah first to listen offline.';
      } else {
        _errorMessage = isAr 
            ? 'فشل تشغيل الآية، يرجى المحاولة لاحقاً.'
            : 'Failed to play Ayah, please try again later.';
      }
      
      debugPrint('❌ $_errorMessage');
      
      // إظهار رسالة خطأ واضحة للمستخدم
      Get.snackbar(
        isAr ? 'خطأ في التشغيل' : 'Playback Error',
        _errorMessage!,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.only(bottom: 120, left: 16, right: 16), // فوق المشغل المصغر
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.white),
        duration: const Duration(seconds: 4),
      );
      
      notifyListeners();
    }
  }

  /// تشغيل مقطع تكرار متقدم
  Future<void> playAdvancedRepeat({
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
    required int ayahRepeatCount,
    required int blockRepeatCount,
  }) async {
    _isAdvancedRepeat = true;
    _advancedStartSurah = startSurah;
    _advancedStartAyah = startAyah;
    _advancedEndSurah = endSurah;
    _advancedEndAyah = endAyah;
    _repeatCount = ayahRepeatCount;
    _advancedBlockRepeatCount = blockRepeatCount;
    _currentAdvancedBlockRepeat = 1;
    
    _isLoading = true;
    _errorMessage = null;
    _currentSurah = startSurah;
    _currentAyah = startAyah;
    _currentRepeat = 1;
    _isRepeating = true;
    _audioPlayer.setLoopMode(LoopMode.off);
    notifyListeners();

    try {
      final localPath = await MushafDownloadManager.getLocalAyahPath(
        _selectedReciterId,
        startSurah,
        startAyah,
      );
      final isLocal = localPath != null;

      String? audioUrl;
      if (!isLocal) {
        audioUrl = await QuranFoundationApi.getAyahAudioUrl(
          _selectedReciterId,
          startSurah,
          startAyah,
        );
      }

      _playlist = ConcatenatingAudioSource(children: []);
      final repeats = _repeatCount == -1 ? 1 : _repeatCount;
      for (int i = 0; i < repeats; i++) {
        AudioSource source;
        if (isLocal) {
          source = AudioSource.file(
            localPath!,
            tag: MediaItem(
              id: 'ayah_${startSurah}_${startAyah}_${i}_block1',
              title: '${quran_utils.getSurahNameArabic(startSurah)} - آية $startAyah',
              album: 'القرآن الكريم',
              extras: {'surah': startSurah, 'ayah': startAyah},
            ),
          );
        } else if (audioUrl != null) {
          final separator = audioUrl.contains('?') ? '&' : '?';
          final uniqueUrl = '$audioUrl${separator}repeat=$i&block=1';
          source = AudioSource.uri(
            Uri.parse(uniqueUrl),
            tag: MediaItem(
              id: 'ayah_${startSurah}_${startAyah}_${i}_block1',
              title: '${quran_utils.getSurahNameArabic(startSurah)} - آية $startAyah',
              album: 'القرآن الكريم',
              extras: {'surah': startSurah, 'ayah': startAyah},
            ),
          );
        } else {
          continue;
        }
        await _playlist!.add(source);
      }

      await _audioPlayer.setAudioSource(_playlist!);
      
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      
      _audioPlayer.play();
      
      // التجهيز المسبق للآية التالية في المقطع (إجباري في وضع التكرار المتقدم)
      _preloadNextAyah(startSurah, startAyah);
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل تشغيل المقطع: $e';
      debugPrint('❌ $e');
      notifyListeners();
    }
  }

  /// تشغيل صوت كلمة مفردة
  Future<void> playWord(String audioRelativeUrl) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fullUrl = QuranFoundationApi.getWordAudioUrl(audioRelativeUrl);
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(fullUrl),
          tag: MediaItem(
            id: 'word_$audioRelativeUrl',
            title: 'كلمة قرآنية',
            album: 'القرآن الكريم',
          ),
        ),
      );
      
      _isLoading = false;
      _isPlaying = true;
      notifyListeners();
      
      // لا نستخدم await هنا
      _audioPlayer.play();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل تشغيل الكلمة: $e';
      debugPrint('❌ $e');
      notifyListeners();
    }
  }

  /// إيقاف مؤقت
  void pause() {
    _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// استئناف
  void resume() {
    _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }

  /// إيقاف كامل
  void stop() {
    _audioPlayer.stop();
    _isPlaying = false;
    _isRepeating = false;
    _currentRepeat = 0;
    _currentSurah = null;
    _currentAyah = null;
    notifyListeners();
  }

  /// جلب كلمات الآية مع بيانات الصوت
  Future<List<QuranWordModel>> getAyahWords(int surahNumber, int ayahNumber) async {
    try {
      final verseData = await QuranFoundationApi.getVerseWords(surahNumber, ayahNumber);
      final words = verseData['words'] as List;
      return words
          .map((w) => QuranWordModel.fromJson(Map<String, dynamic>.from(w)))
          .where((w) => w.isWord) // فقط الكلمات وليس أرقام الآيات
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب كلمات الآية: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
