import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mihrab/features/quran/logic/global_audio_manager.dart';
import 'package:mihrab/features/auth/ui/screens/auth_screen.dart';
import 'package:mihrab/features/prayers/logic/notification_manager.dart';
import 'package:mihrab/core/widgets/glass_card.dart';

class AdhanSelectionScreen extends StatefulWidget {
  const AdhanSelectionScreen({super.key});

  @override
  State<AdhanSelectionScreen> createState() => _AdhanSelectionScreenState();
}

class _AdhanSelectionScreenState extends State<AdhanSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ StreamSubscription عشان نلغيه كل مرة قبل ما نعمل listen جديد
  StreamSubscription? _playerSubscription;

  final List<Map<String, dynamic>> _regularAdhans = [
    {'id': 'mohamed_hosny', 'name': 'محمد حسني'},
    {'id': 'takbeer', 'name': 'تكبير فقط (قصير)'},
    {'id': 'mulla', 'name': 'أذان الحرم المكي'},
    {'id': 'qassas', 'name': 'محمد مروان قصاص'},
    {'id': 'ramadan', 'name': 'محمود محمد رمضان'},
    {'id': 'refaat', 'name': 'محمد رفعت'},
    {'id': 'abd_toba', 'name': 'عبدالتواب جامع'},
  ];

  final List<Map<String, dynamic>> _fajrAdhans = [
    {'id': 'takbeer', 'name': 'تكبير فقط'},
    {'id': 'mulla', 'name': 'أذان الفجر (مكة المكرمة)'},
    {'id': 'qassas', 'name': 'أذان الفجر (القصاص)'},
  ];

  String _selectedRegular = 'takbeer';
  String _selectedFajr = 'takbeer';

  // ✅ الـ fileName الكامل اللي شغّال دلوقتي (null = مفيش حاجة بتشتغل)
  String? _playingFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSelections();
  }

  @override
  void dispose() {
    // ✅ إلغاء الـ subscription عند الخروج
    _playerSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ✅ دالة مركزية لحساب اسم الملف — مكانش واحد
  String _getFileName(String id, bool isFajrTab) {
    if (isFajrTab && (id == 'mulla' || id == 'qassas')) {
      return 'fajr_$id';
    }
    return id;
  }

  Future<void> _loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRegular = prefs.getString('adhan_sound') ?? 'takbeer';
      _selectedFajr = prefs.getString('fajr_sound') ?? 'takbeer';
    });
  }

  Future<void> _saveSelection(String prefKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, value);

    setState(() {
      if (prefKey == 'adhan_sound') {
        _selectedRegular = value;
      } else {
        _selectedFajr = value;
      }
    });

    try {
      await NotificationManager.rescheduleAllNotifications();
    } catch (e) {
      debugPrint('rescheduleAllNotifications error: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "تم حفظ اختيار المؤذن وتحديث الإشعارات ✅",
            style: TextStyle(),
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _preview(String id, {bool isFajrTab = false}) async {
    final fileName = _getFileName(id, isFajrTab); // ✅ دالة مركزية

    try {
      // ✅ لو نفس الملف بيشتغل → وقّفه وارجع
      if (_playingFile == fileName) {
        await GlobalAudioManager().player.stop();
        // setState بيتعمل في listener بالأسفل لما processingState يبقى idle
        return;
      }

      // ✅ وقّف اللي شغّال قبل كده
      await GlobalAudioManager().player.stop();

      // ✅ حدّث الـ state فوراً عشان الزرار يتحول لـ pause على طول
      if (mounted) setState(() => _playingFile = fileName);

      await GlobalAudioManager().player.setAudioSource(
            AudioSource.asset(
              'assets/sounds/$fileName.mp3',
              tag: MediaItem(
                id: fileName,
                title: "معاينة الأذان",
                album: "إعدادات التطبيق",
              ),
            ),
          );

      await GlobalAudioManager().player.play();

      // ✅ إلغاء الـ subscription القديم قبل ما نعمل واحد جديد — المشكلة الأساسية
      await _playerSubscription?.cancel();
      _playerSubscription =
          GlobalAudioManager().player.playerStateStream.listen((state) {
        // ✅ الصوت خلص أو اتوقف → صفّر الـ state
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          if (mounted) setState(() => _playingFile = null);
        }
      });
    } catch (e) {
      debugPrint('_preview error: $e');
      if (mounted) setState(() => _playingFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Get.locale?.languageCode == 'ar';

    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor =
        isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    final tabBgColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    final tabUnselectedColor = isDark ? Colors.white70 : Colors.black54;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: isDark
                  ? const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/background.png'),
                        fit: BoxFit.cover,
                      ),
                    )
                  : BoxDecoration(color: Colors.grey[100]),
            ),
            if (isDark)
              Container(color: const Color(0xFF071814).withOpacity(0.85)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isArabic
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: iconColor,
                          ),
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "اختر المؤذن",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: tabBgColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      labelColor: isDark ? Colors.black : Colors.white,
                      unselectedLabelColor: tabUnselectedColor,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "الصلوات"),
                        Tab(text: "صلاة الفجر"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(
                          _regularAdhans,
                          _selectedRegular,
                          'adhan_sound',
                          false,
                          isDark,
                        ),
                        _buildList(
                          _fajrAdhans,
                          _selectedFajr,
                          'fajr_sound',
                          true,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list,
    String selectedId,
    String prefKey,
    bool isFajrTab,
    bool isDark,
  ) {
    final borderColor =
        isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final playIconColor = isDark ? Colors.white : Colors.black54;
    final selectedIconColor =
        isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final String id = item['id'];

        // ✅ نفس الدالة المركزية
        final String fileName = _getFileName(id, isFajrTab);

        final bool isSelected = selectedId == id;
        final bool isPlaying =
            _playingFile == fileName; // ✅ مقارنة بالـ fileName مش الـ id

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(15),
            onTap: () => _saveSelection(prefKey, id),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _preview(id, isFajrTab: isFajrTab),
                  child: CircleAvatar(
                    backgroundColor: isSelected
                        ? borderColor
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    child: Icon(
                      // ✅ الأيقونة بتتغير صح دلوقتي
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : playIconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item['name'],
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: selectedIconColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
