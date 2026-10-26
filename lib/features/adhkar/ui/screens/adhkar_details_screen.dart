import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../../quran/logic/global_audio_manager.dart';
import '../../data/adhkar_audio_storage.dart';
import '../../data/adhkar_model.dart';
import '../../data/adhkar_preferences.dart';
import '../../../../core/translations/app_locale_keys.dart';

class AdhkarDetailsScreen extends StatefulWidget {
  final AdhkarCategory category;

  const AdhkarDetailsScreen({super.key, required this.category});

  @override
  State<AdhkarDetailsScreen> createState() => _AdhkarDetailsScreenState();
}

class _AdhkarDetailsScreenState extends State<AdhkarDetailsScreen> {
  late final PageController _pageController;
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _currentPage = 0;
  int _currentCount = 0;
  int _targetCount = 1;
  bool _isPlaying = false;
  bool _isAudioLoading = false;
  bool _isDownloading = false;
  bool _isCurrentDownloaded = false;
  bool _isAutoAdvancing = false;
  Set<int> _favoriteIds = <int>{};

  bool get _isArabic => Get.locale?.languageCode != 'en';

  String _t({required String ar, required String en}) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _audioPlayer = GlobalAudioManager().player;
    _targetCount = _getTargetCount(0);
    _loadFavorites();
    _bindPlayerState();
    _syncCurrentDownloadState();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _pageController.dispose();
    _audioPlayer.stop();
    super.dispose();
  }

  void _bindPlayerState() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isAudioLoading = state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _isAudioLoading = false;
        }
      });
      if (state.processingState == ProcessingState.completed) {
        _handleAudioCompleted();
      }
    });
  }

  int _getTargetCount(int page) {
    if (page >= widget.category.items.length) return 1;
    final count = widget.category.items[page].count;
    return count > 0 ? count : 1;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('favorite_adhkar') ?? '[]';
    final decoded = json.decode(raw) as List<dynamic>;
    if (!mounted) return;
    setState(() {
      _favoriteIds = decoded.map((e) => e as int).toSet();
    });
  }

  Future<void> _toggleFavorite(int id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await prefs.setString(
        'favorite_adhkar', json.encode(_favoriteIds.toList()));
    await AdhkarPreferences.lightImpact();
    if (!mounted) return;
    showGlassSnackBar(
      context,
      _favoriteIds.contains(id)
          ? _t(ar: AppLocaleKeys.addedToFavorites.tr, en: 'Added to favorites')
          : _t(ar: AppLocaleKeys.removedFromFavorites.tr, en: 'Removed from favorites'),
    );
  }

  Future<void> _syncCurrentDownloadState() async {
    final item = widget.category.items[_currentPage];
    final downloaded = await isAdhkarAudioDownloaded(item);
    if (!mounted) return;
    setState(() {
      _isCurrentDownloaded = downloaded;
    });
  }

  List<String> _buildAudioCandidates(String audioPath) {
    final cleaned = audioPath.trim().replaceAll('\\', '/');
    if (cleaned.isEmpty) return const <String>[];

    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return <String>[
        cleaned.replaceFirst('http://', 'https://'),
        cleaned,
      ].toSet().toList();
    }

    final relative = cleaned.startsWith('/') ? cleaned.substring(1) : cleaned;
    final fileName = relative.split('/').last;
    return <String>[
      'https://www.hisnmuslim.com/audio/ar/$fileName',
      'https://hisnmuslim.com/audio/ar/$fileName',
      'http://www.hisnmuslim.com/audio/ar/$fileName',
      'http://hisnmuslim.com/audio/ar/$fileName',
    ].toSet().toList();
  }

  Future<void> _toggleAudio(String audioPath) async {
    final currentItem = widget.category.items[_currentPage];

    if (audioPath.trim().isEmpty) {
      showGlassSnackBar(
        context,
        _t(
            ar: AppLocaleKeys.noAudioAvailableForDhikr.tr,
            en: 'No audio available for this dhikr'),
        isError: true,
      );
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.stop();
      return;
    }

    final localPath = await localAdhkarAudioPathIfExists(currentItem);
    final candidates = <String>[
      if (localPath != null) localPath,
      ..._buildAudioCandidates(audioPath),
    ];
    if (candidates.isEmpty) return;

    setState(() => _isAudioLoading = true);

    Object? lastError;
    for (final url in candidates) {
      try {
        await _audioPlayer.stop();
        final tag = MediaItem(
          id: '${widget.category.id}-${currentItem.id}-$url',
          album: widget.category.category,
          title: currentItem.text,
          artist: widget.category.category,
          displayTitle: widget.category.category,
        );
        if (url.startsWith('http://') || url.startsWith('https://')) {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(url), tag: tag),
          );
        } else {
          await _audioPlayer.setAudioSource(
            AudioSource.file(url, tag: tag),
          );
        }
        await _audioPlayer.play();
        return;
      } catch (error) {
        lastError = error;
      }
    }

    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isAudioLoading = false;
    });
    debugPrint('Adhkar audio error: $lastError');
    showGlassSnackBar(
      context,
      _t(
        ar: AppLocaleKeys.audioPlayFailedRetry.tr,
        en: 'Audio playback failed, please try again',
      ),
      isError: true,
    );
  }

  Future<void> _toggleDownloadCurrentAudio() async {
    final item = widget.category.items[_currentPage];
    if (item.audio.trim().isEmpty) {
      showGlassSnackBar(
        context,
        _t(
            ar: AppLocaleKeys.noAudioFileForDhikr.tr,
            en: 'No audio file for this dhikr'),
        isError: true,
      );
      return;
    }

    if (_isCurrentDownloaded) {
      await deleteAdhkarAudio(item);
      if (!mounted) return;
      setState(() => _isCurrentDownloaded = false);
      showGlassSnackBar(
        context,
        _t(ar: AppLocaleKeys.downloadedAudioDeleted.tr, en: 'Downloaded audio deleted'),
      );
      return;
    }

    final candidates = _buildAudioCandidates(item.audio);
    if (candidates.isEmpty) return;

    setState(() => _isDownloading = true);
    Object? lastError;

    for (final url in candidates) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await saveAdhkarAudio(item, response.bodyBytes);
          if (!mounted) return;
          setState(() {
            _isDownloading = false;
            _isCurrentDownloaded = true;
          });
          showGlassSnackBar(
            context,
            _t(
              ar: AppLocaleKeys.audioDownloadedForOffline.tr,
              en: 'Dhikr audio downloaded for offline playback',
            ),
          );
          return;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (!mounted) return;
    setState(() => _isDownloading = false);
    debugPrint('Adhkar download error: $lastError');
    showGlassSnackBar(
      context,
      _t(ar: AppLocaleKeys.audioDownloadFailed.tr, en: 'Failed to download audio'),
      isError: true,
    );
  }

  Future<void> _advanceCount() async {
    if (_currentCount >= _targetCount) return;

    setState(() => _currentCount++);
    await AdhkarPreferences.lightImpact();

    if (_currentCount >= _targetCount) {
      await AdhkarPreferences.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await _goToNextOrFinish();
    }
  }

  Future<void> _copyDhikr(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await AdhkarPreferences.selectionClick();
    if (!mounted) return;
    showGlassSnackBar(
      context,
      _t(ar: AppLocaleKeys.dhikrCopiedMsg.tr, en: 'Dhikr copied'),
    );
  }

  void _onPageChanged(int index) {
    _audioPlayer.stop();
    setState(() {
      _currentPage = index;
      _currentCount = 0;
      _targetCount = _getTargetCount(index);
      _isPlaying = false;
      _isAudioLoading = false;
      _isDownloading = false;
    });
    _syncCurrentDownloadState();
  }

  Future<void> _handleAudioCompleted() async {
    if (_isAutoAdvancing || !mounted) return;

    if (_currentCount < _targetCount) {
      setState(() => _currentCount = _targetCount);
    }
    await _goToNextOrFinish();
  }

  Future<void> _goToNextOrFinish() async {
    if (_isAutoAdvancing || !mounted) return;
    _isAutoAdvancing = true;

    try {
      if (_currentPage < widget.category.items.length - 1) {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      } else {
        showGlassSnackBar(
          context,
          _t(
            ar: AppLocaleKeys.adhkarCompletedSuccess.tr,
            en: 'May Allah accept, you completed the adhkar',
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      _isAutoAdvancing = false;
    }
  }

  Future<void> _showAdhkarList() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF16312B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6E7E77);
    final accent = const Color(0xFF2A8B68);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text(
                  _t(ar: AppLocaleKeys.adhkarList.tr, en: 'Adhkar list'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: widget.category.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.category.items[index];
                    final isCurrent = index == _currentPage;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.pop(context);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? accent.withOpacity(0.12)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF4F8F6)),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isCurrent
                                ? accent
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFD7E8DF)),
                          ),
                        ),
                        child: Text(
                          item.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            color: isCurrent ? accent : textColor,
                            fontSize: 14,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topColor = isDark ? const Color(0xFF071814) : const Color(0xFFF7FBF8);
    final bottomColor =
        isDark ? const Color(0xFF0E241E) : const Color(0xFFE4F0EA);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF6A8479);
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF);
    final accent = const Color(0xFF74D7C0);
    final accentDark = const Color(0xFF2A8B68);
    final item = widget.category.items[_currentPage];
    final isFavorite = _favoriteIds.contains(item.id);
    final remaining = (_targetCount - _currentCount).clamp(0, _targetCount);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bottomColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildHeader(titleColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _MetaBadge(
                        label:
                            '${_currentPage + 1}/${widget.category.items.length}',
                        color: accentDark,
                        textColor: titleColor,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      _MetaBadge(
                        label: _isArabic
                            ? AppLocaleKeys.remainingCount.trParams({'count': remaining.toString()})
                            : '$remaining remaining',
                        color: accentDark,
                        textColor: titleColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.category.items.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final pageItem = widget.category.items[index];
                      final note = pageItem.bless.trim();
                      final combinedText = note.isEmpty
                          ? pageItem.text
                          : '${pageItem.text}\n\n$note';

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _advanceCount,
                                borderRadius: BorderRadius.circular(28),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(22, 22, 22, 18),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accent.withOpacity(0.10),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (note.isNotEmpty)
                                        Text(
                                          note,
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            color: accentDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      if (note.isNotEmpty)
                                        const SizedBox(height: 14),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Text(
                                            pageItem.text,
                                            textAlign: TextAlign.center,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              color: titleColor,
                                              fontSize: 28,
                                              height: 1.95,
                                              fontFamily: 'UthmanTN',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Divider(color: borderColor),
                                      const SizedBox(height: 12),
                                      Text(
                                        _isArabic
                                            ? _countLabel(pageItem.count)
                                            : _englishCountLabel(
                                                pageItem.count),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (note.isNotEmpty)
                                        Text(
                                          _isArabic
                                              ? AppLocaleKeys.shareOrCopyHint.tr
                                              : 'Use copy to keep the dhikr text',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 12,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      if (!pageItem.text.contains(note))
                                        SizedBox(
                                          height: 0,
                                          child: Text(combinedText),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            _BottomActionButton(
                              icon: isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? const Color(0xFFD45B5B)
                                  : accentDark,
                              onTap: () => _toggleFavorite(item.id),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: _advanceCount,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [accent, accentDark],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$remaining',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _BottomActionButton(
                              icon: _isAudioLoading
                                  ? Icons.hourglass_top_rounded
                                  : (_isPlaying
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded),
                              color: accentDark,
                              onTap: _isAudioLoading
                                  ? () {}
                                  : () => _toggleAudio(item.audio),
                            ),
                            const SizedBox(width: 10),
                            _BottomActionButton(
                              icon: _isDownloading
                                  ? Icons.downloading_rounded
                                  : (_isCurrentDownloaded
                                      ? Icons.delete_outline_rounded
                                      : Icons.download_rounded),
                              color: _isCurrentDownloaded
                                  ? const Color(0xFFD45B5B)
                                  : accentDark,
                              onTap: _isDownloading
                                  ? () {}
                                  : _toggleDownloadCurrentAudio,
                            ),
                            const SizedBox(width: 10),
                            _BottomActionButton(
                              icon: Icons.copy_rounded,
                              color: accentDark,
                              onTap: () => _copyDhikr(
                                item.bless.trim().isEmpty
                                    ? item.text
                                    : '${item.text}\n\n${item.bless.trim()}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color titleColor) {
    final backIcon = _isArabic
        ? Icons.arrow_back_ios_new_rounded
        : Icons.arrow_forward_ios_rounded;

    final backButton = _CircleButton(
      icon: backIcon,
      onTap: () => Navigator.pop(context),
      color: titleColor,
    );

    final menuButton = _CircleButton(
      icon: Icons.menu_rounded,
      onTap: _showAdhkarList,
      color: titleColor,
    );

    return Row(
      children: _isArabic
          ? [
              backButton,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.category.category.tr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              menuButton,
            ]
          : [
              menuButton,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.category.category.tr,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              backButton,
            ],
    );
  }

  String _countLabel(int count) {
    final labels = {
      1: AppLocaleKeys.oneTime.tr,
      2: AppLocaleKeys.twoTimes.tr,
      3: AppLocaleKeys.threeTimes.tr,
      4: AppLocaleKeys.fourTimes.tr,
      5: AppLocaleKeys.fiveTimes.tr,
      7: AppLocaleKeys.sevenTimes.tr,
      10: AppLocaleKeys.tenTimes.tr,
      33: AppLocaleKeys.thirtyThreeTimes.tr,
      100: AppLocaleKeys.hundredTimes.tr,
    };
    return labels[count] ?? AppLocaleKeys.countTimes.trParams({'count': count.toString()});
  }

  String _englishCountLabel(int count) {
    if (count == 1) return 'Repeat once';
    if (count == 2) return 'Repeat twice';
    return 'Repeat $count times';
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool isDark;

  const _MetaBadge({
    required this.label,
    required this.color,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BottomActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
