import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../quran/logic/global_audio_manager.dart';
import '../auth/ui/screens/auth_screen.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/translations/app_locale_keys.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSinking = false; // ✨ Sinking animation state

  final List<Map<String, String>> _pages = [
    {
      'title': AppLocaleKeys.themeTitle,
      'desc': AppLocaleKeys.themeDesc,
      'image': 'assets/welcome/theme_img.png', // User will add this image
    },
    {
      'title': AppLocaleKeys.locationTitle,
      'desc': AppLocaleKeys.locationDesc,
      'image': 'assets/welcome/location_img.png', // User will add this image
    },
    {
      'title': AppLocaleKeys.adhanTitle,
      'desc': AppLocaleKeys.adhanDesc,
      'image': 'assets/welcome/adhan_img.png', // User will add this image
    },
    {
      'title': AppLocaleKeys.notifTitle,
      'desc': AppLocaleKeys.notifDesc,
      'image': 'assets/welcome/notif_img.png', // User will add this image
    },
  ];

  String _selectedAdhanId = 'mohamed_hosny';
  String _playingAdhanId = '';
  AudioPlayer get _audioPlayer => GlobalAudioManager().player;

  final List<Map<String, String>> _adhansList = [
    {'key': AppLocaleKeys.mohamedHosny, 'file': 'mohamed_hosny'},
    {'key': AppLocaleKeys.mohamedGom3a, 'file': 'mohamedgom3a'},
    {'key': AppLocaleKeys.takbeer, 'file': 'takbeer'},
    {'key': AppLocaleKeys.mulla, 'file': 'mulla'},
    {'key': AppLocaleKeys.qassas, 'file': 'qassas'},
    {'key': AppLocaleKeys.ramadan, 'file': 'ramadan'},
    {'key': AppLocaleKeys.refaat, 'file': 'refaat'},
    {'key': AppLocaleKeys.abdToba, 'file': 'abd_toba'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _playAdhan(String fileId) async {
    try {
      if (_playingAdhanId == fileId) {
        await _audioPlayer.stop();
        setState(() => _playingAdhanId = '');
      } else {
        await _audioPlayer.setAudioSource(
          AudioSource.asset(
            'assets/sounds/$fileId.mp3',
            tag: MediaItem(id: fileId, title: AppLocaleKeys.preview.tr),
          ),
        );
        await _audioPlayer.play();
        setState(() => _playingAdhanId = fileId);

        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => _playingAdhanId = '');
          }
        });
      }
    } catch (_) {}
  }

  void _nextPage() async {
    // 🌍 Location Permission
    if (_currentPage == 1) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    }
    // 🔔 Notification Permission
    else if (_currentPage == 3) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_setup_completed', true);
    await prefs.setString('adhan_sound', _selectedAdhanId);

    if (mounted) {
      setState(() => _isSinking = true);
      // Wait for the sink animation to complete
      await Future.delayed(const Duration(milliseconds: 400));
      Get.offAll(
        () => const AuthScreen(),
        transition: Transition.downToUp, // ✨ Slides up from the bottom
        duration: const Duration(milliseconds: 600),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // ✨ السر هنا: سنجعل لون خلفية الشاشة العلوية دائماً "كريمي فاتح" حتى في الوضع الداكن
    // هذا سيحافظ على "الخدعة السحرية" ولن تتحول الصور إلى اللون الأسود أبداً!
    // بينما البطاقة السفلية (Card) ستتغير للوضع الداكن بشكل طبيعي.
    final Color bgColor = const Color(0xFFFDECDA);
    final Color cardColor =
        isDark ? const Color(0xFF1A3636) : const Color(0xFF0C4D3E);
    final Color mutedTextColor =
        isDark ? Colors.white60 : const Color(0xFF8BA69C);

    final bool isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedScale(
        scale: _isSinking ? 0.92 : 1.0, // ✨ Sink scale
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isSinking ? 0.0 : 1.0, // ✨ Fade out
          duration: const Duration(milliseconds: 400),
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar: Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(), // Placeholder for balance
                      if (!isLastPage)
                        GestureDetector(
                          onTap: _finishSetup,
                          child: Text(
                            AppLocaleKeys.skip.tr,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      else
                        const SizedBox(
                            height: 24), // Invisible placeholder to keep height
                    ],
                  ),
                ),

                // Middle: Illustration PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0), // Image takes full width
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: Transform.scale(
                                  scale:
                                      1.5, // Makes the images huge and gorgeous
                                  alignment: Alignment.bottomCenter,
                                  child: Image.asset(
                                    _pages[index]['image']!,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter,
                                    color:
                                        bgColor, // Magic trick: Blends the white background into the app background!
                                    colorBlendMode: BlendMode.multiply,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image_outlined,
                                              size: 80,
                                              color:
                                                  cardColor.withOpacity(0.3)),
                                          const SizedBox(height: 16),
                                          Text(
                                            "Add ${_pages[index]['image']?.split('/').last}",
                                            style: TextStyle(
                                                color:
                                                    cardColor.withOpacity(0.5)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom: Dark Green Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                      top: 40, bottom: 40, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _pages[_currentPage]['title']!.tr,
                          key: ValueKey('title_$_currentPage'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _pages[_currentPage]['desc']!.tr,
                          key: ValueKey('desc_$_currentPage'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: mutedTextColor,
                          ),
                        ),
                      ),

                      // Interactive Controls
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildInteractiveControls(isDark, cardColor),
                      ),

                      const SizedBox(height: 24),

                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next / Start Button
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isLastPage)
                                Icon(Icons.arrow_back,
                                    color: cardColor, size: 20)
                              else
                                Icon(Icons.check_circle_outline,
                                    color: cardColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isLastPage
                                    ? AppLocaleKeys.startNow.tr
                                    : AppLocaleKeys.next.tr,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: cardColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🛠 Interactive Settings Controls
  Widget _buildInteractiveControls(bool isDark, Color cardColor) {
    if (_currentPage == 0) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChoiceBtn(
                AppLocaleKeys.lightMode.tr,
                Icons.light_mode,
                !isDark,
                cardColor,
                () => themeProvider.setThemeMode(ThemeMode.light)),
            const SizedBox(width: 16),
            _buildChoiceBtn(AppLocaleKeys.darkMode.tr, Icons.dark_mode, isDark,
                cardColor, () => themeProvider.setThemeMode(ThemeMode.dark)),
          ],
        ),
      );
    } else if (_currentPage == 2) {
      return Padding(
        key: const ValueKey('adhan'),
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play Button
              GestureDetector(
                onTap: () => _playAdhan(_selectedAdhanId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _playingAdhanId == _selectedAdhanId
                        ? Colors.white
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70),
                  ),
                  child: Icon(
                    _playingAdhanId == _selectedAdhanId
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: _playingAdhanId == _selectedAdhanId
                        ? cardColor
                        : Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dropdown
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAdhanId,
                  dropdownColor: cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white),
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAdhanId = newValue;
                      });
                      _playAdhan(newValue); // Auto-play when selected
                    }
                  },
                  items: _adhansList.map<DropdownMenuItem<String>>(
                      (Map<String, String> adhan) {
                    return DropdownMenuItem<String>(
                      value: adhan['file'],
                      child: Text(adhan['key']!.tr),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox(key: ValueKey('empty'), height: 0);
  }

  Widget _buildChoiceBtn(String title, IconData icon, bool isSelected,
      Color cardColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? cardColor : Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: isSelected ? cardColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
