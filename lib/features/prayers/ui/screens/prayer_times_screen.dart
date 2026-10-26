import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/ad_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../data/models/custom_alarm.dart';
import '../../logic/notification_manager.dart';
import '../../../../features/quran/logic/global_audio_manager.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  List<CustomAlarm> _alarms = [];
  AudioPlayer get _player => GlobalAudioManager().player;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadAlarms() async {
    final list = await NotificationManager.getCustomAlarms();
    setState(() => _alarms = list);
  }

  Future<void> _deleteAlarm(int id) async {
    await NotificationManager.removeCustomAlarm(id);
    _loadAlarms();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddAlarmSheet(
          onSave: (alarm) async {
            await NotificationManager.addCustomAlarm(alarm);
            _loadAlarms();
            Navigator.pop(context);
          },
          audioPlayer: _player,
        ),
      ),
    ).then((_) {
      _player.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF071814) : const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            AppLocaleKeys.customAlertsTitle.tr,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            AdService.nativeAdWidget(),
            Expanded(
              child: _alarms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.alarm_add,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppLocaleKeys.noAlertsYet.tr,
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        final prayersText = alarm.prayerNames
                            .map((p) => _getPrayerLabel(p))
                            .join('، ');

                        return Dismissible(
                          key: ValueKey(alarm.id),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteAlarm(alarm.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      color: Colors.cyanAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        alarm.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteAlarm(alarm.id),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$prayersText (${alarm.isBefore ? AppLocaleKeys.before.tr : AppLocaleKeys.after.tr} ${alarm.offsetMinutes} د)',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                                const Divider(height: 15),
                                InkWell(
                                  onTap: () async {
                                    try {
                                      if (_player.playing) await _player.stop();

                                      await _player.setAudioSource(
                                        AudioSource.asset(
                                          'assets/sounds/${alarm.soundName}.mp3',
                                          tag: MediaItem(
                                            id: 'preview',
                                            title: AppLocaleKeys.preview.tr,
                                          ),
                                        ),
                                      );
                                      _player.play();
                                    } catch (_) {}
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.volume_up,
                                        size: 16,
                                        color: Colors.cyanAccent,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _getSoundLabel(alarm.soundName),
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: Colors.cyanAccent,
            icon: const Icon(Icons.add_alarm, color: Colors.black),
            label: Text(
              AppLocaleKeys.addAlarm.tr,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            heroTag: 'custom_alarm_fab',
          ),
        ),
      ),
    );
  }

  String _getPrayerLabel(String prayer) {
    switch (prayer) {
      case 'fajr':
        return AppLocaleKeys.fajr.tr;
      case 'dhuhr':
        return AppLocaleKeys.dhuhr.tr;
      case 'asr':
        return AppLocaleKeys.asr.tr;
      case 'maghrib':
        return AppLocaleKeys.maghrib.tr;
      case 'isha':
        return AppLocaleKeys.isha.tr;
      default:
        return prayer;
    }
  }

  String _getSoundLabel(String sound) {
    switch (sound) {
      case 'takbeer':
        return AppLocaleKeys.takbeer.tr;
      case 'mulla':
        return AppLocaleKeys.mulla.tr;
      case 'qassas':
        return AppLocaleKeys.qassas.tr;
      default:
        return sound;
    }
  }
}

class AddAlarmSheet extends StatefulWidget {
  final Function(CustomAlarm) onSave;
  final AudioPlayer audioPlayer;

  const AddAlarmSheet({
    super.key,
    required this.onSave,
    required this.audioPlayer,
  });

  @override
  State<AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<AddAlarmSheet> {
  final TextEditingController _titleController = TextEditingController();
  final List<String> _selectedPrayers = ['fajr'];
  bool _isBefore = true;
  int _minutes = 15;
  String _selectedSound = 'takbeer';

  List<Map<String, String>> get _allPrayers => [
        {'val': 'fajr', 'name': AppLocaleKeys.fajr.tr},
        {'val': 'dhuhr', 'name': AppLocaleKeys.dhuhr.tr},
        {'val': 'asr', 'name': AppLocaleKeys.asr.tr},
        {'val': 'maghrib', 'name': AppLocaleKeys.maghrib.tr},
        {'val': 'isha', 'name': AppLocaleKeys.isha.tr},
      ];

  List<Map<String, String>> get _sounds => [
        {'val': 'takbeer', 'name': AppLocaleKeys.takbeer.tr},
        {'val': 'mulla', 'name': AppLocaleKeys.mulla.tr},
        {'val': 'qassas', 'name': AppLocaleKeys.qassas.tr},
      ];

  @override
  void dispose() {
    widget.audioPlayer.stop();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String sound) async {
    try {
      await widget.audioPlayer.stop();
      await widget.audioPlayer.setAudioSource(
        AudioSource.asset(
          'assets/sounds/$sound.mp3',
          tag: MediaItem(
            id: sound,
            title: AppLocaleKeys.soundPreviewTitle.tr,
          ),
        ),
      );
      widget.audioPlayer.play();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1C2541),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  AppLocaleKeys.newAlarm.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: AppLocaleKeys.alarmNameHint.tr,
                  labelStyle: const TextStyle(color: Colors.cyanAccent),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.edit, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocaleKeys.choosePrayers.tr,
                style: const TextStyle(color: Colors.cyanAccent),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _allPrayers.map((p) {
                  final isSelected = _selectedPrayers.contains(p['val']);
                  return FilterChip(
                    label: Text(p['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPrayers.add(p['val']!);
                        } else if (_selectedPrayers.length > 1) {
                          _selectedPrayers.remove(p['val']!);
                        }
                      });
                    },
                    selectedColor: Colors.cyanAccent,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                    backgroundColor: Colors.white10,
                    checkmarkColor: Colors.black,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ToggleButtons(
                    isSelected: [_isBefore, !_isBefore],
                    onPressed: (idx) => setState(() => _isBefore = idx == 0),
                    color: Colors.white,
                    selectedColor: Colors.black,
                    fillColor: Colors.cyanAccent,
                    borderRadius: BorderRadius.circular(10),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(AppLocaleKeys.before.tr),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(AppLocaleKeys.after.tr),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      children: [
                        Slider(
                          value: _minutes.toDouble(),
                          min: 1,
                          max: 60,
                          divisions: 59,
                          activeColor: Colors.cyanAccent,
                          onChanged: (val) =>
                              setState(() => _minutes = val.toInt()),
                        ),
                        Text(
                          '$_minutes دقيقة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    AppLocaleKeys.sound.tr,
                    style: const TextStyle(color: Colors.cyanAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSound,
                      dropdownColor: const Color(0xFF1E4D3E),
                      items: _sounds
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s['val'],
                              child: Text(
                                s['name']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedSound = val);
                        _previewSound(val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.orangeAccent,
                      size: 35,
                    ),
                    onPressed: () => _previewSound(_selectedSound),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    var finalTitle = _titleController.text.trim();
                    if (finalTitle.isEmpty) {
                      finalTitle = AppLocaleKeys.customAlertDefaultTitle.tr;
                    }

                    final alarm = CustomAlarm(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      title: finalTitle,
                      prayerNames: _selectedPrayers,
                      offsetMinutes: _minutes,
                      isBefore: _isBefore,
                      soundName: _selectedSound,
                    );
                    widget.onSave(alarm);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocaleKeys.saveAlarm.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
