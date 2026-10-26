import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../prayers/logic/notification_manager.dart';
import '../../../prayers/logic/prayer_times_controller.dart';
import '../../../quran/logic/global_audio_manager.dart';
import '../../../../core/translations/app_locale_keys.dart';

class AdhanSelectionPage extends StatefulWidget {
  final VoidCallback onNext;
  final double pageOffset;
  final Animation<double> floatAnimation;

  const AdhanSelectionPage({
    super.key,
    required this.onNext,
    required this.pageOffset,
    required this.floatAnimation,
  });

  @override
  State<AdhanSelectionPage> createState() => _AdhanSelectionPageState();
}

class _AdhanSelectionPageState extends State<AdhanSelectionPage> {
  String? _selectedAdhanId;
  String? _playingAdhanId;
  bool _adhanEnabled = true;
  AudioPlayer get _audioPlayer => GlobalAudioManager().player;

  final List<Map<String, String>> _adhansList = [
    {'name': AppLocaleKeys.mohamedHosnyName.tr, 'file': 'mohamed_hosny'},
    {'name': AppLocaleKeys.mohamedGomaaName.tr, 'file': 'mohamedgom3a'},
    {'name': AppLocaleKeys.takbeerOnlyName.tr, 'file': 'takbeer'},
    {'name': AppLocaleKeys.aliMullaName.tr, 'file': 'mulla'},
    {'name': AppLocaleKeys.mohamedQassasName.tr, 'file': 'qassas'},
    {'name': AppLocaleKeys.mahmoudRamadanName.tr, 'file': 'ramadan'},
    {'name': AppLocaleKeys.mohamedRefaatName.tr, 'file': 'refaat'},
    {'name': AppLocaleKeys.abdelTawabName.tr, 'file': 'abd_toba'},
  ];

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _playAdhan(String fileId) async {
    try {
      if (_playingAdhanId == fileId) {
        await _audioPlayer.stop();
        setState(() => _playingAdhanId = null);
      } else {
        await _audioPlayer.setAudioSource(
          AudioSource.asset(
            'assets/sounds/$fileId.mp3',
            tag: MediaItem(id: fileId, title: AppLocaleKeys.adhanPreview.tr),
          ),
        );
        await _audioPlayer.play();
        setState(() => _playingAdhanId = fileId);

        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => _playingAdhanId = null);
          }
        });
      }
    } catch (_) {}
  }

  void _saveAndFinish() async {
    await _audioPlayer.stop();
    final prefs = await SharedPreferences.getInstance();

    if (_adhanEnabled) {
      String sound = _selectedAdhanId ?? 'mohamed_hosny';
      await prefs.setString('adhan_sound', sound);
      await prefs.setString('sound_fajr', sound);
      await prefs.setString('sound_dhuhr', sound);
      await prefs.setString('sound_asr', sound);
      await prefs.setString('sound_maghrib', sound);
      await prefs.setString('sound_isha', sound);

      await NotificationManager.requestPermissionsUserAction();

      try {
        int retries = 0;
        while (!NotificationManager.channelsInitialized.value && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          retries++;
        }
        final times =
            await PrayerTimesController().getStoredOrDefaultPrayerTimes();
        await NotificationManager.schedulePrayers(times);
        await NotificationManager.scheduleAdhkar();
      } catch (_) {}

      await NotificationManager.setGlobalNotifications(true);
    } else {
      await NotificationManager.setGlobalNotifications(false);
      await NotificationManager.cancelAllNotifications();
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // Islamic Theme Base
    final primaryGlowColor =
        isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8860B);

    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Premium Glowing Header Icon
                AnimatedBuilder(
                  animation: widget.floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(widget.pageOffset * -100,
                          widget.floatAnimation.value * 1.5),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryGlowColor.withOpacity(0.25),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.campaign_rounded,
                                size: 50,
                                color: primaryGlowColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  AppLocaleKeys.adhanSoundName.tr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  AppLocaleKeys.chooseMuezzinHint.tr.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 30),

                // Enable Toggle Glassmorphism
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: SwitchListTile(
                    title: Text(AppLocaleKeys.enableAdhanSound.tr.tr,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    value: _adhanEnabled,
                    activeColor: primaryGlowColor,
                    onChanged: (val) {
                      setState(() {
                        _adhanEnabled = val;
                        if (!val) {
                          _audioPlayer.stop();
                          _playingAdhanId = null;
                        }
                      });
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Adhan List Premium
                ...List.generate(_adhansList.length, (index) {
                  final adhan = _adhansList[index];
                  final isSelected = _selectedAdhanId == adhan['file'] ||
                      (_selectedAdhanId == null && index == 0);
                  final isPlaying = _playingAdhanId == adhan['file'];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected && _adhanEnabled
                          ? (isDark
                              ? primaryGlowColor.withOpacity(0.15)
                              : primaryGlowColor.withOpacity(0.1))
                          : (isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.02)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected && _adhanEnabled
                            ? primaryGlowColor.withOpacity(0.6)
                            : (isDark ? Colors.white10 : Colors.black12),
                        width: isSelected && _adhanEnabled ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected && _adhanEnabled
                          ? [
                              BoxShadow(
                                color: primaryGlowColor.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: ListTile(
                      enabled: _adhanEnabled,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      onTap: () {
                        if (_adhanEnabled) {
                          setState(() => _selectedAdhanId = adhan['file']);
                        }
                      },
                      leading: GestureDetector(
                        onTap: _adhanEnabled
                            ? () => _playAdhan(adhan['file']!)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: isPlaying
                                ? LinearGradient(
                                    colors: isDark
                                        ? [
                                            primaryGlowColor,
                                            primaryGlowColor.withOpacity(0.7)
                                          ]
                                        : [
                                            primaryGlowColor,
                                            primaryGlowColor.withOpacity(0.8)
                                          ],
                                  )
                                : null,
                            color: isPlaying
                                ? null
                                : (isDark ? Colors.white12 : Colors.black12),
                            shape: BoxShape.circle,
                            boxShadow: isPlaying
                                ? [
                                    BoxShadow(
                                        color:
                                            primaryGlowColor.withOpacity(0.4),
                                        blurRadius: 10)
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: isPlaying
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            size: 22,
                          ),
                        ),
                      ),
                      title: Text(
                        adhan['name']!,
                        style: TextStyle(
                          color: _adhanEnabled
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white30 : Colors.black38),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: isSelected && _adhanEnabled
                          ? Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryGlowColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 16),
                            )
                          : null,
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Pinned Bottom Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: GestureDetector(
                onTap: _saveAndFinish,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              primaryGlowColor,
                              primaryGlowColor.withOpacity(0.7)
                            ]
                          : [
                              primaryGlowColor,
                              primaryGlowColor.withOpacity(0.8)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlowColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocaleKeys.continueBtnText.tr.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
