import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class GlobalAudioManager {
  static final GlobalAudioManager _instance = GlobalAudioManager._internal();
  factory GlobalAudioManager() => _instance;
  GlobalAudioManager._internal();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<bool> isPlayerExpanded = ValueNotifier(false);
  final ValueNotifier<bool> playerReady = ValueNotifier(false);
  final ValueNotifier<bool> showMiniPlayer = ValueNotifier(false); // ✅ Control visibility explicitly
}
