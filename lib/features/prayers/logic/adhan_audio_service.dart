import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import '../../quran/logic/global_audio_manager.dart';

class AdhanAudioService {
  static final AdhanAudioService _instance = AdhanAudioService._internal();

  factory AdhanAudioService() {
    return _instance;
  }

  AdhanAudioService._internal();

  AudioPlayer get _player => GlobalAudioManager().player;

  /// Play the Adhan audio for the given sound ID
  Future<void> playAdhan(String soundId) async {
    try {
      // 1. Initialize Session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Stop any current playback
      await _player.stop();

      String assetPath = 'assets/sounds/$soundId.mp3';
      debugPrint('🔊 Playing Adhan: $assetPath');

      // ✅ REQUIRED: Must include MediaItem tag for background playback
      // Determine readable name (matching Setup Wizard)
      String title = "أذان الصلاة";
      String artist = "المؤذن";
      
      if (soundId.contains("hosny")) { artist = "محمد حسني"; }
      else if (soundId.contains("takbeer")) { artist = "تكبيرات فقط"; }
      else if (soundId.contains("mulla")) { artist = "علي ملا (مكة)"; }
      else if (soundId.contains("qassas")) { artist = "محمد مروان قصاص"; }
      else if (soundId.contains("ramadan")) { artist = "محمود محمد رمضان"; }
      else if (soundId.contains("refaat")) { artist = "محمد رفعت"; }
      else if (soundId.contains("abd_toba")) { artist = "عبدالتواب جامع"; }

      final audioSource = AudioSource.asset(
        assetPath,
        tag: MediaItem(
          id: soundId,
          title: title,
          artist: artist,
          artUri: null, // Optional: Add app icon URI if needed
        ),
      );

      await _player.setAudioSource(audioSource);
      await _player.play();
      
      // Auto-stop when finished
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          stopAdhan();
        }
      });

    } catch (e) {
      debugPrint('❌ Error playing Adhan audio: $e');
    }
  }

  /// Stop the Adhan audio immediately
  Future<void> stopAdhan() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('❌ Error stopping Adhan: $e');
    }
  }
  
  bool get isPlaying => _player.playing;
}
