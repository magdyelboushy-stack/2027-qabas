import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/recitation.dart';
import '../../../../core/services/download_manager.dart';
import '../../data/models/shaykh.dart';
import '../../logic/global_audio_manager.dart';
import '../../../../core/services/audio_bookmark_service.dart';
import '../../../../features/auth/data/auth_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart' hide Rx;
import '../../../../core/utils/custom_showcase.dart';
import '../../data/favorites_manager.dart';
import '../../../../core/services/ad_service.dart';
import '../../logic/media_player_controller.dart';
import 'widgets/media_player_guest_dialog.dart';
import '../../../../core/utils/glass_snackbar.dart';
import '../../../../core/translations/app_locale_keys.dart';

// ══════════════════════════════════════════════════════════════════════
//  THEME TOKENS  (محدثة لتطابق الهوية البصرية للتطبيق)
// ══════════════════════════════════════════════════════════════════════
class _AppColors {
  // Light (درجات متناسقة مع الهوية في حالة وجود وضع نهاري)
  static const lightBg = Color(0xFFF0F5F3);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFE1EBE7);
  static const lightPrimary = Color(0xFF226351); // الأخضر الأساسي من التطبيق
  static const lightOnPrimary = Colors.white;
  static const lightText = Color(0xFF0E1F1A);
  static const lightSubText = Color(0xFF5D7B73);

  // Dark (متطابق تماماً مع ألوان الصورة المرفقة)
  static const darkBg =
      Color(0xFF0E1F1A); // لون الخلفية الداكن جداً (أسفل الشاشة)
  static const darkCard =
      Color(0xFF142C24); // لون الكروت (مثل كارت Reverent Voices)
  static const darkSurface = Color(0xFF1A382E); // لون الأسطح والخلفيات الفرعية
  static const darkPrimary = Color(
      0xFF388E75); // أخضر أفتح قليلاً للأزرار والـ Sliders عشان يظهر بوضوح
  static const darkOnPrimary = Colors.white;
  static const darkText =
      Color(0xFFE8F0EC); // أبيض مريح للعين ومائل لدرجات التطبيق
  static const darkSubText =
      Color(0xFF8B9E97); // لون النصوص الثانوية والأيقونات غير النشطة

  // Shared
  static const accentRed =
      Color(0xFF2F8F6B); // Accent updated to match the app theme
}

class _T {
  static Color bg(bool d) => d ? _AppColors.darkBg : _AppColors.lightBg;
  static Color card(bool d) => d ? _AppColors.darkCard : _AppColors.lightCard;
  static Color surface(bool d) =>
      d ? _AppColors.darkSurface : _AppColors.lightSurface;
  static Color primary(bool d) =>
      d ? _AppColors.darkPrimary : _AppColors.lightPrimary;
  static Color onPrimary(bool d) =>
      d ? _AppColors.darkOnPrimary : _AppColors.lightOnPrimary;
  static Color text(bool d) => d ? _AppColors.darkText : _AppColors.lightText;
  static Color sub(bool d) =>
      d ? _AppColors.darkSubText : _AppColors.lightSubText;
}

// ══════════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════════
class MediaPlayerScreen extends StatefulWidget {
  final Shaykh shaykh;
  final Recitation currentRecitation;
  final List<Recitation> allRecitations;
  final bool isOpeningFromMiniPlayer;

  const MediaPlayerScreen({
    super.key,
    required this.shaykh,
    required this.currentRecitation,
    required this.allRecitations,
    this.isOpeningFromMiniPlayer = false,
  });

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = GlobalAudioManager().player;
  late String _fixedImageUrl;

  // ── Animations ──
  late AnimationController _breatheCtrl;
  late AnimationController _pulseCtrl;

  // ── Showcase keys ──
  final GlobalKey _keyPlayPause = GlobalKey();
  final GlobalKey _keyNext = GlobalKey();
  final GlobalKey _keyPrevious = GlobalKey();
  final GlobalKey _keyPlaylist = GlobalKey();
  final GlobalKey _keyAddBookmark = GlobalKey();
  final GlobalKey _keyShowBookmarks = GlobalKey();

  bool _hasError = false;
  bool _startShowcasePending = false;

  StreamSubscription? _positionSub;

  // ── ValueNotifiers ──
  final _isFav = ValueNotifier(false);
  final _isDownloaded = ValueNotifier(false);
  final _isDownloading = ValueNotifier(false);
  final _dlProgress = ValueNotifier(0);
  final _dlStatus = ValueNotifier(0);

  String? _currentTaskId;
  StreamSubscription? _dlSub;
  Timer? _pollTimer;

  // ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    GlobalAudioManager().isPlayerExpanded.value = true;
    _fixedImageUrl =
        MediaPlayerController.normalizeImageUrl(widget.shaykh.imageUrl);

    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    if (!widget.isOpeningFromMiniPlayer) {
      _initAudioPlayer();
    } else {
      _startTrackingPosition();
    }

    _checkAndShowTutorial();
    _checkStatus();
    _initDownloadListener();

    _audioPlayer.currentIndexStream.listen((_) {
      if (mounted) _checkStatus();
    });
  }

  int _downloadStatusValue(dynamic status) {
    if (status is int) return status;
    try {
      return status.index as int;
    } catch (_) {
      return 0;
    }
  }

  bool _isCompleteStatus(int status) => status == 3;

  bool _isFailedStatus(int status) => status == 4 || status == 5;

  bool _isActiveStatus(int status) =>
      status == 1 || status == 2 || status == 6;

  bool _isPausedStatus(int status) => status == 6;

  // ── Download listener ──
  void _initDownloadListener() {
    _dlSub = DownloadManager.updates.listen((update) {
      final rec = _resolveCurrentRecitation();
      if (_currentTaskId == update.taskId || update.url == rec.audioUrl) {
        _currentTaskId ??= update.taskId;
        _dlProgress.value = update.progress;
        final status = _downloadStatusValue(update.status);
        _dlStatus.value = status;

        if (_isCompleteStatus(status)) {
          _isDownloading.value = false;
          _isDownloaded.value = true;
          _currentTaskId = null;
        } else if (_isFailedStatus(status)) {
          _isDownloading.value = false;
          _currentTaskId = null;
        } else if (status == 2 || _isPausedStatus(status)) {
          _isDownloading.value = true;
        }
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_isDownloading.value) _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final rec = _resolveCurrentRecitation();
    _isFav.value = await FavoritesManager.isFavorite(rec);
    final downloaded = await DownloadManager.isDownloaded(rec, widget.shaykh);
    _isDownloaded.value = downloaded;

    if (!downloaded) {
      final task = await DownloadManager.getTaskByUrl(rec.audioUrl);
      if (task != null) {
        _currentTaskId = task.taskId;
        _dlProgress.value = task.progress;
        _dlStatus.value = _downloadStatusValue(task.status);
        _isDownloading.value = _isActiveStatus(_dlStatus.value);
      } else {
        _isDownloading.value = false;
        _currentTaskId = null;
      }
    }
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('has_shown_media_tutorial') ?? false) && mounted) {
      setState(() => _startShowcasePending = true);
      await prefs.setBool('has_shown_media_tutorial', true);
    }
  }

  Future<void> _initAudioPlayer() async {
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      return !GlobalAudioManager().playerReady.value;
    });

    final currentIndex = widget.allRecitations
        .indexWhere((r) => r.id == widget.currentRecitation.id);
    final sources = <AudioSource>[];

    for (final rec in widget.allRecitations) {
      final tag = MediaItem(
        id: rec.id,
        album: widget.shaykh.name,
        title: rec.title,
        artUri: Uri.parse(_fixedImageUrl),
        extras: {
          'recitation': rec.toJson(),
          'mushafName':
              rec.mushafName ?? AppLocaleKeys.playerDefaultMushafName.tr,
        },
      );
      final localPath = await DownloadManager.isDownloaded(rec, widget.shaykh)
          ? await DownloadManager.getLocalFilePath(rec, widget.shaykh)
          : null;

      if (localPath != null) {
        sources.add(AudioSource.file(localPath, tag: tag));
      } else if (rec.audioUrl.isNotEmpty && File(rec.audioUrl).existsSync()) {
        sources.add(AudioSource.file(rec.audioUrl, tag: tag));
      } else {
        final uri = MediaPlayerController.safeParseAudioUri(rec.audioUrl);
        if (uri != null) sources.add(AudioSource.uri(uri, tag: tag));
      }
    }

    try {
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: currentIndex > -1 ? currentIndex : 0,
      );
      final lastPos = await AudioBookmarkService.getLastPosition(
          widget.currentRecitation.id);
      if (lastPos != null && lastPos > 5000) {
        await _audioPlayer.seek(Duration(milliseconds: lastPos));
        if (mounted)
          showGlassSnackBar(
              context, AppLocaleKeys.playerResumeFromLastPosition.tr);
      }
      _audioPlayer.play();
      GlobalAudioManager().showMiniPlayer.value = true;
      _startTrackingPosition();
    } catch (e) {
      debugPrint("Audio Error: $e");
      if (mounted) {
        setState(() => _hasError = true);
        showGlassSnackBar(context, AppLocaleKeys.playerPlaybackError.tr,
            isError: true);
      }
    }
  }

  void _startTrackingPosition() {
    _positionSub?.cancel();
    _positionSub = _audioPlayer.positionStream
        .throttleTime(const Duration(seconds: 3))
        .listen((pos) => _saveCurrentPosition(pos.inMilliseconds));
    _audioPlayer.sequenceStateStream.listen((_) => _checkStatus());
  }

  void _saveCurrentPosition(int ms) {
    final id = _getCurrentRecitationId();
    if (id != null) AudioBookmarkService.saveLastPosition(id, ms);
  }

  String? _getCurrentRecitationId() {
    final item = _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
    return item?.id;
  }

  Recitation _resolveCurrentRecitation() =>
      MediaPlayerController.resolveCurrentRecitation(
        allRecitations: widget.allRecitations,
        fallback: widget.currentRecitation,
        currentRecitationId: _getCurrentRecitationId(),
      );

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
    _positionSub?.cancel();
    _dlSub?.cancel();
    _pollTimer?.cancel();
    _saveCurrentPosition(_audioPlayer.position.inMilliseconds);
    Future.microtask(() {
      if (GlobalAudioManager().player.playing) {
        GlobalAudioManager().isPlayerExpanded.value = false;
        GlobalAudioManager().showMiniPlayer.value = true;
      }
    });
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (p, b, d) => PositionData(p, b, d ?? Duration.zero),
      );

  TextDirection get _textDirection =>
      Get.locale?.languageCode == 'en' ? TextDirection.ltr : TextDirection.rtl;

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: _textDirection,
      child: ShowCaseWidget(
        builder: (context) {
          if (_startShowcasePending) {
            _startShowcasePending = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ShowCaseWidget.of(context).startShowCase([
                _keyPlaylist,
                _keyAddBookmark,
                _keyShowBookmarks,
              ]);
            });
          }
          return Scaffold(
            backgroundColor: _T.bg(isDark),
            body: Stack(
              children: [
                _buildBlurredBg(isDark),
                SafeArea(
                  child: Column(
                    children: [
                      // ── Header ──
                      _buildHeader(context, isDark),

                      // ── Artwork  (flex 42) ──
                      Expanded(
                        flex: 42,
                        child: _buildArtwork(isDark),
                      ),

                      // ── Bottom panel  (flex 58) — NO scroll ──
                      Expanded(
                        flex: 58,
                        child: _buildBottomPanel(isDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Blurred background ──
  Widget _buildBlurredBg(bool isDark) {
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: _fixedImageUrl,
        fit: BoxFit.cover,
        color: isDark
            ? Colors.black.withOpacity(0.82)
            : Colors.white.withOpacity(0.78),
        colorBlendMode: BlendMode.srcOver,
        errorWidget: (_, __, ___) => Container(color: _T.bg(isDark)),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context, bool isDark) {
    final primary = _T.primary(isDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.keyboard_arrow_down_rounded,
              () => Navigator.pop(context), isDark),

          // Now playing indicator
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: playing
                            ? primary.withOpacity(0.5 + _pulseCtrl.value * 0.5)
                            : _T.sub(isDark),
                        boxShadow: playing
                            ? [
                                BoxShadow(
                                    color: primary.withOpacity(0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                AppLocaleKeys.playerNowPlaying.tr,
                style: TextStyle(
                  color: _T.text(isDark),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),

          CustomShowcase(
            globalKey: _keyPlaylist,
            title: AppLocaleKeys.playerPlaylist.tr,
            description: AppLocaleKeys.playerPlaylistDescription.tr,
            child: _circleBtn(Icons.queue_music_rounded,
                () => _showPlaylist(context, isDark), isDark),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _T.card(isDark).withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(
              color: _T.primary(isDark).withOpacity(0.25), width: 0.8),
        ),
        child: Icon(icon, color: _T.text(isDark), size: 22),
      ),
    );
  }

  // ── Artwork ──
  Widget _buildArtwork(bool isDark) {
    final primary = _T.primary(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      child: StreamBuilder<PlayerState>(
        stream: _audioPlayer.playerStateStream,
        builder: (_, snap) {
          final playing = snap.data?.playing ?? false;
          return AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) {
              final scale = playing ? 1.0 + (_breatheCtrl.value * 0.008) : 0.97;
              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(playing ? 0.40 : 0.12),
                        blurRadius: playing ? 36 : 12,
                        spreadRadius: playing ? 4 : 0,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _fixedImageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          placeholder: (_, __) => Container(
                            color: _T.card(isDark),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: primary, strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: _T.card(isDark),
                            child: Icon(Icons.music_note_rounded,
                                size: 64, color: _T.sub(isDark)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  _T.bg(isDark).withOpacity(0.7)
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_hasError) _buildErrorOverlay(isDark),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorOverlay(bool isDark) {
    final primary = _T.primary(isDark);
    return Container(
      color: _T.bg(isDark).withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: _T.sub(isDark)),
            const SizedBox(height: 12),
            Text(AppLocaleKeys.playerConnectionFailed.tr,
                style: TextStyle(
                    color: _T.text(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                setState(() => _hasError = false);
                _initAudioPlayer();
              },
              icon: Icon(Icons.refresh, color: _T.onPrimary(isDark)),
              label: Text(AppLocaleKeys.playerRetry.tr,
                  style: TextStyle(color: _T.onPrimary(isDark))),
              style: TextButton.styleFrom(
                backgroundColor: primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BOTTOM PANEL — no scroll, Column fills available space
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBottomPanel(bool isDark) {
    final primary = _T.primary(isDark);
    return Container(
      decoration: BoxDecoration(
        color: _T.bg(isDark).withOpacity(0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
            top: BorderSide(color: primary.withOpacity(0.12), width: 0.8)),
      ),
      child: Column(
        children: [
          // Drag pill
          const SizedBox(height: 10),
          Center(
              child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _T.sub(isDark).withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 12),

          // ── Track info + heart ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTrackInfoRow(isDark),
          ),
          const SizedBox(height: 8),

          // ── Mushaf badge ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildMushafBadge(isDark),
          ),
          const SizedBox(height: 12),

          // ── Progress ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildProgressSection(isDark),
          ),
          const SizedBox(height: 6),

          // ── Controls ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildControlsRow(isDark),
          ),
          const SizedBox(height: 10),

          // ── Visualizer ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildVisualizer(isDark),
          ),
          const SizedBox(height: 10),

          // ── Action row (fav + download) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildActionRow(isDark),
          ),
          const SizedBox(height: 8),

          // ── Bookmarks row ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildBookmarkControls(isDark),
          ),
          const SizedBox(height: 10),

          // ── Banner ad ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AdService.bannerAdWidget(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Track info row ──
  Widget _buildTrackInfoRow(bool isDark) {
    final primary = _T.primary(isDark);
    return StreamBuilder<SequenceState?>(
      stream: _audioPlayer.sequenceStateStream,
      builder: (_, snap) {
        final mediaItem = snap.data?.currentSource?.tag as MediaItem?;
        final title = mediaItem?.title ?? widget.currentRecitation.title;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.shaykh.name,
                      style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _T.text(isDark),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<bool>(
              valueListenable: _isFav,
              builder: (_, isFav, __) => GestureDetector(
                onTap: () async {
                  final rec = _resolveCurrentRecitation();
                  if (isFav)
                    await FavoritesManager.removeFavorite(context, rec);
                  else
                    await FavoritesManager.addFavorite(context, rec);
                  _checkStatus();
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isFav
                        ? _AppColors.accentRed.withOpacity(0.15)
                        : _T.surface(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFav
                          ? _AppColors.accentRed.withOpacity(0.45)
                          : _T.sub(isDark).withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFav ? _AppColors.accentRed : _T.sub(isDark),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Mushaf badge ──
  Widget _buildMushafBadge(bool isDark) {
    return StreamBuilder<SequenceState?>(
      stream: _audioPlayer.sequenceStateStream,
      builder: (_, snap) {
        final mediaItem = snap.data?.currentSource?.tag as MediaItem?;
        final name = mediaItem?.extras?['mushafName'] as String? ??
            widget.currentRecitation.mushafName ??
            AppLocaleKeys.playerDefaultMushafName.tr;
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: _T.surface(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _T.primary(isDark).withOpacity(0.2), width: 0.8),
            ),
            child: Text(name,
                style: TextStyle(
                    color: _T.sub(isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  // ── Controls row ──
  Widget _buildControlsRow(bool isDark) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          StreamBuilder<bool>(
            stream: _audioPlayer.shuffleModeEnabledStream,
            builder: (_, snap) {
              final on = snap.data ?? false;
              return _iconBtn(
                  icon: Icons.shuffle_rounded,
                  isActive: on,
                  isDark: isDark,
                  onTap: () => _audioPlayer.setShuffleModeEnabled(!on));
            },
          ),

          // Previous
          CustomShowcase(
            globalKey: _keyPrevious,
            title: AppLocaleKeys.playerPrevious.tr,
            description: AppLocaleKeys.playerPreviousDescription.tr,
            borderRadius: BorderRadius.circular(50),
            child: _iconBtn(
                icon: Icons.skip_previous_rounded,
                isDark: isDark,
                sizeBig: true,
                onTap: () => _audioPlayer.seekToPrevious()),
          ),

          // Play/Pause — big red
          CustomShowcase(
            globalKey: _keyPlayPause,
            title: AppLocaleKeys.playerPlayPause.tr,
            description: AppLocaleKeys.playerPlayPauseDescription.tr,
            borderRadius: BorderRadius.circular(50),
            child: _buildPlayPauseBtn(),
          ),

          // Next
          CustomShowcase(
            globalKey: _keyNext,
            title: AppLocaleKeys.playerNext.tr,
            description: AppLocaleKeys.playerNextDescription.tr,
            borderRadius: BorderRadius.circular(50),
            child: _iconBtn(
                icon: Icons.skip_next_rounded,
                isDark: isDark,
                sizeBig: true,
                onTap: () => _audioPlayer.seekToNext()),
          ),

          // Repeat
          StreamBuilder<LoopMode>(
            stream: _audioPlayer.loopModeStream,
            builder: (_, snap) {
              final lm = snap.data ?? LoopMode.off;
              return _iconBtn(
                  icon: Icons.repeat_rounded,
                  isActive: lm == LoopMode.one,
                  isDark: isDark,
                  onTap: () => _audioPlayer.setLoopMode(
                      lm == LoopMode.one ? LoopMode.off : LoopMode.one));
            },
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool isActive = false,
    bool sizeBig = false,
  }) {
    final primary = _T.primary(isDark);
    final btnSize = sizeBig ? 50.0 : 40.0;
    final iconSize = sizeBig ? 30.0 : 20.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? primary.withOpacity(0.15) : _T.surface(isDark),
          border: Border.all(
            color: isActive
                ? primary.withOpacity(0.4)
                : _T.sub(isDark).withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Icon(icon,
            color: isActive ? primary : _T.text(isDark).withOpacity(0.75),
            size: iconSize),
      ),
    );
  }

  Widget _buildPlayPauseBtn() {
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (_, snap) {
        final playing = snap.data?.playing ?? false;
        final loading = snap.data?.processingState == ProcessingState.loading ||
            snap.data?.processingState == ProcessingState.buffering;
        return GestureDetector(
          onTap: loading
              ? null
              : () => playing ? _audioPlayer.pause() : _audioPlayer.play(),
          child: AnimatedBuilder(
            animation: _breatheCtrl,
            builder: (_, __) => Transform.scale(
              scale: playing ? 1.0 + (_breatheCtrl.value * 0.025) : 1.0,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _AppColors.accentRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _AppColors.accentRed.withOpacity(0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: loading
                    ? const Center(
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5)))
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Progress bar ──
  Widget _buildProgressSection(bool isDark) {
    final primary = _T.primary(isDark);
    return StreamBuilder<PositionData>(
      stream: _positionDataStream,
      builder: (_, snap) {
        final pos = snap.data?.position ?? Duration.zero;
        final dur = snap.data?.duration ?? Duration.zero;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
                activeTrackColor: primary,
                inactiveTrackColor: _T.surface(isDark),
                thumbColor: Colors.white,
                overlayColor: primary.withOpacity(0.18),
              ),
              child: Slider(
                value: pos.inMilliseconds
                    .toDouble()
                    .clamp(0, dur.inMilliseconds.toDouble()),
                max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                onChanged: (v) =>
                    _audioPlayer.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_printDuration(pos),
                      style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  Text(_printDuration(dur),
                      style: TextStyle(color: _T.sub(isDark), fontSize: 11)),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── Visualizer ──
  Widget _buildVisualizer(bool isDark) {
    final primary = _T.primary(isDark);
    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (_, snap) {
        final playing = snap.data?.playing ?? false;
        return AnimatedBuilder(
          animation: _breatheCtrl,
          builder: (_, __) {
            final phase = _breatheCtrl.value * math.pi * 2;
            final bars = List.generate(38, (i) {
              final base = (math.sin(i * 0.6 + phase) + 1) / 2;
              final sec = (math.sin(i * 1.1 + phase * 1.3) + 1) / 2;
              final level = playing ? (base + sec) / 2 : (0.08 + base * 0.12);
              final h = 4.0 + level * 32.0;
              final highlight = i % 3 == 0 || i % 7 == 0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 3.5,
                height: h,
                decoration: BoxDecoration(
                  color: highlight
                      ? _AppColors.accentRed.withOpacity(0.85)
                      : primary.withOpacity(0.25 + level * 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            });
            return SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: bars,
              ),
            );
          },
        );
      },
    );
  }

  // ── Action row (fav + download) ──
  Widget _buildActionRow(bool isDark) {
    final primary = _T.primary(isDark);
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isFav,
            builder: (_, isFav, __) => _miniBtn(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: isFav
                  ? AppLocaleKeys.playerInFavorites.tr
                  : AppLocaleKeys.playerAddToFavorites.tr,
              color: isFav ? _AppColors.accentRed : primary,
              isDark: isDark,
              onTap: () async {
                final rec = _resolveCurrentRecitation();
                if (isFav)
                  await FavoritesManager.removeFavorite(context, rec);
                else
                  await FavoritesManager.addFavorite(context, rec);
                _checkStatus();
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _buildDownloadBtn(primary, isDark)),
      ],
    );
  }

  Widget _buildDownloadBtn(Color primary, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDownloaded,
      builder: (_, downloaded, __) => ValueListenableBuilder<bool>(
        valueListenable: _isDownloading,
        builder: (_, downloading, __) {
          if (downloading) {
            return ValueListenableBuilder<int>(
              valueListenable: _dlProgress,
              builder: (_, prog, __) =>
                  ValueListenableBuilder<int>(
                valueListenable: _dlStatus,
                builder: (_, status, __) {
                  final paused = _isPausedStatus(status);
                  return _miniBtn(
                    icon:
                        paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: paused
                        ? AppLocaleKeys.playerPaused
                            .trParams({'progress': '$prog'})
                        : AppLocaleKeys.playerDownloading
                            .trParams({'progress': '$prog'}),
                    color: paused ? Colors.orange : primary,
                    isDark: isDark,
                    onTap: () async {
                      if (_currentTaskId == null) return;
                      if (paused)
                        await DownloadManager.resumeDownload(_currentTaskId!);
                      else {
                        await DownloadManager.pauseDownload(_currentTaskId!);
                        _dlStatus.value = 6;
                      }
                    },
                  );
                },
              ),
            );
          }
          return _miniBtn(
            icon: downloaded
                ? Icons.check_circle_rounded
                : Icons.download_rounded,
            label: downloaded
                ? AppLocaleKeys.playerDownloaded.tr
                : AppLocaleKeys.playerDownloadSurah.tr,
            color: downloaded ? Colors.green : primary,
            isDark: isDark,
            onTap: () async {
              if (downloaded) {
                _showDeleteDialog(context, isDark);
                return;
              }
              final isGuest = await AuthService.isGuest();
              if (isGuest) {
                if (mounted) showMediaPlayerGuestDialog(context);
                return;
              }
              _isDownloading.value = true;
              _dlProgress.value = 0;
              try {
                final rec = _resolveCurrentRecitation();
                final taskId =
                    await DownloadManager.startDownload(rec, widget.shaykh);
                if (taskId != null) _currentTaskId = taskId;
                if (mounted) {
                  AdService.showInterstitialAd();
                  showGlassSnackBar(
                      context, AppLocaleKeys.playerDownloadStarted.tr);
                  _checkStatus();
                }
              } catch (e) {
                debugPrint("Download Error: $e");
                if (mounted) {
                  _isDownloading.value = false;
                  showGlassSnackBar(
                      context, AppLocaleKeys.playerDownloadStartError.tr,
                      isError: true);
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isDark) {
    final primary = _T.primary(isDark);
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: Get.locale?.languageCode == 'en'
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _T.card(isDark),
          title: Text(AppLocaleKeys.playerDeleteDownloadTitle.tr,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: _T.text(isDark))),
          content: Text(AppLocaleKeys.playerDeleteDownloadMessage.tr,
              style: TextStyle(color: _T.sub(isDark))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocaleKeys.commonCancel.tr,
                    style: TextStyle(color: _T.sub(isDark)))),
            ElevatedButton(
              onPressed: () async {
                final rec = _resolveCurrentRecitation();
                final path =
                    await DownloadManager.getLocalFilePath(rec, widget.shaykh);
                if (path != null) {
                  await DownloadManager.deleteDownload(path);
                  _checkStatus();
                }
                Navigator.pop(context);
                showGlassSnackBar(
                    context, AppLocaleKeys.playerDeleteSuccess.tr);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: Text(AppLocaleKeys.commonDelete.tr,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bookmark controls ──
  Widget _buildBookmarkControls(bool isDark) {
    final primary = _T.primary(isDark);
    return Row(
      children: [
        Expanded(
          child: CustomShowcase(
            globalKey: _keyAddBookmark,
            title: AppLocaleKeys.playerAddBookmark.tr,
            description: AppLocaleKeys.playerAddBookmarkDescription.tr,
            child: _miniBtn(
                icon: Icons.bookmark_add_rounded,
                label: AppLocaleKeys.playerAddBookmark.tr,
                color: primary,
                isDark: isDark,
                onTap: _showAddBookmarkDialog),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomShowcase(
            globalKey: _keyShowBookmarks,
            title: AppLocaleKeys.playerBookmarksSaved.tr,
            description: AppLocaleKeys.playerBookmarksSavedDescription.tr,
            child: _miniBtn(
                icon: Icons.bookmarks_rounded,
                label: AppLocaleKeys.playerBookmarks.tr,
                color: primary,
                isDark: isDark,
                onTap: _showBookmarksList),
          ),
        ),
      ],
    );
  }

  Widget _miniBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _T.surface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _T.text(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  PLAYLIST — Real DraggableScrollableSheet
  // ══════════════════════════════════════════════════════════════════
  void _showPlaylist(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaylistSheet(
        audioPlayer: _audioPlayer,
        allRecitations: widget.allRecitations,
        isDark: isDark,
        primaryColor: _T.primary(isDark),
        cardColor: _T.card(isDark),
        bgColor: _T.bg(isDark),
        textColor: _T.text(isDark),
        subColor: _T.sub(isDark),
        surfaceColor: _T.surface(isDark),
        onNormalizeSearch: MediaPlayerController.normalizeForSearch,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BOOKMARKS — Real DraggableScrollableSheet
  // ══════════════════════════════════════════════════════════════════
  void _showAddBookmarkDialog() async {
    final isGuest = await AuthService.isGuest();
    if (isGuest) {
      if (mounted) showMediaPlayerGuestDialog(context);
      return;
    }
    final pos = _audioPlayer.position;
    final timeStr = _printDuration(pos);
    final ctrl = TextEditingController(
        text: AppLocaleKeys.playerBookmarkAt.trParams({'time': timeStr}));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = _T.primary(isDark);

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: Get.locale?.languageCode == 'en'
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _T.card(isDark),
          title: Text(AppLocaleKeys.playerAddBookmarkTitle.tr,
              style: TextStyle(color: _T.text(isDark))),
          content: TextField(
            controller: ctrl,
            style: TextStyle(color: _T.text(isDark)),
            decoration: InputDecoration(
              hintText: AppLocaleKeys.playerBookmarkNameHint.tr,
              hintStyle: TextStyle(color: _T.sub(isDark)),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocaleKeys.commonCancel.tr,
                    style: TextStyle(color: _T.sub(isDark)))),
            ElevatedButton(
              onPressed: () async {
                final id = _getCurrentRecitationId();
                if (id != null) {
                  await AudioBookmarkService.addBookmark(
                      id, ctrl.text, pos.inMilliseconds);
                  if (mounted) {
                    Navigator.pop(context);
                    showGlassSnackBar(
                        context, AppLocaleKeys.playerBookmarkSavedSuccess.tr);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: Text(AppLocaleKeys.commonSave.tr,
                  style: TextStyle(color: _T.onPrimary(isDark))),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookmarksList() async {
    final isGuest = await AuthService.isGuest();
    if (isGuest) {
      if (mounted) showMediaPlayerGuestDialog(context);
      return;
    }
    final id = _getCurrentRecitationId();
    if (id == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookmarksSheet(
        recitationId: id,
        audioPlayer: _audioPlayer,
        isDark: isDark,
        primaryColor: _T.primary(isDark),
        cardColor: _T.card(isDark),
        bgColor: _T.bg(isDark),
        textColor: _T.text(isDark),
        subColor: _T.sub(isDark),
        printDuration: _printDuration,
      ),
    );
  }

  String _printDuration(Duration d) => MediaPlayerController.printDuration(d);
}

// ══════════════════════════════════════════════════════════════════════
//  PLAYLIST SHEET  — DraggableScrollableSheet  (طالع / نازل حقيقي)
// ══════════════════════════════════════════════════════════════════════
class _PlaylistSheet extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<Recitation> allRecitations;
  final bool isDark;
  final Color primaryColor,
      cardColor,
      bgColor,
      textColor,
      subColor,
      surfaceColor;
  final String Function(String) onNormalizeSearch;

  const _PlaylistSheet({
    required this.audioPlayer,
    required this.allRecitations,
    required this.isDark,
    required this.primaryColor,
    required this.cardColor,
    required this.bgColor,
    required this.textColor,
    required this.subColor,
    required this.surfaceColor,
    required this.onNormalizeSearch,
  });

  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.35, 0.6, 0.95],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
                top: BorderSide(
                    color: widget.primaryColor.withOpacity(0.15), width: 0.8)),
          ),
          child: Directionality(
            textDirection: Get.locale?.languageCode == 'en'
                ? TextDirection.ltr
                : TextDirection.rtl,
            child: Column(children: [
              // Handle
              const SizedBox(height: 10),
              Center(
                  child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                          color: widget.subColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text(AppLocaleKeys.playerPlaylist.tr,
                  style: TextStyle(
                      color: widget.textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: widget.textColor),
                  decoration: InputDecoration(
                    hintText: AppLocaleKeys.playerSearchHint.tr,
                    hintStyle: TextStyle(color: widget.subColor),
                    prefixIcon: Icon(Icons.search, color: widget.primaryColor),
                    filled: true,
                    fillColor: widget.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: widget.primaryColor.withOpacity(0.2))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: widget.primaryColor.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: widget.primaryColor, width: 1.2)),
                  ),
                ),
              ),
              Divider(color: widget.subColor.withOpacity(0.1), height: 20),

              Expanded(
                child: StreamBuilder<SequenceState?>(
                  stream: widget.audioPlayer.sequenceStateStream,
                  builder: (_, snap) {
                    final curIdx = snap.data?.currentIndex ?? 0;
                    final list = widget.allRecitations;
                    if (list.isEmpty)
                      return Center(
                          child: Text("القائمة غير متاحة",
                              style: TextStyle(color: widget.subColor)));

                    final normalQ = widget.onNormalizeSearch(_query);
                    final filtered = normalQ.isEmpty
                        ? list
                        : list.where((r) {
                            return widget
                                .onNormalizeSearch(
                                    '${r.title} ${r.mushafName ?? ''} ${r.reciterName} ${r.id}')
                                .contains(normalQ);
                          }).toList();

                    if (filtered.isEmpty)
                      return Center(
                          child: Text(AppLocaleKeys.commonNoResults.tr,
                              style: TextStyle(color: widget.subColor)));

                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final origIdx = list.indexOf(item);
                        final selected = origIdx == curIdx;
                        return ListTile(
                          leading: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              selected
                                  ? Icons.bar_chart_rounded
                                  : Icons.music_note_rounded,
                              key: ValueKey(selected),
                              color: selected
                                  ? widget.primaryColor
                                  : widget.subColor,
                            ),
                          ),
                          title: Text(item.title,
                              style: TextStyle(
                                color: selected
                                    ? widget.primaryColor
                                    : widget.textColor,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                          onTap: () {
                            widget.audioPlayer
                                .seek(Duration.zero, index: origIdx);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  BOOKMARKS SHEET  — DraggableScrollableSheet  (طالع / نازل حقيقي)
// ══════════════════════════════════════════════════════════════════════
class _BookmarksSheet extends StatefulWidget {
  final String recitationId;
  final AudioPlayer audioPlayer;
  final bool isDark;
  final Color primaryColor, cardColor, bgColor, textColor, subColor;
  final String Function(Duration) printDuration;

  const _BookmarksSheet({
    required this.recitationId,
    required this.audioPlayer,
    required this.isDark,
    required this.primaryColor,
    required this.cardColor,
    required this.bgColor,
    required this.textColor,
    required this.subColor,
    required this.printDuration,
  });

  @override
  State<_BookmarksSheet> createState() => _BookmarksSheetState();
}

class _BookmarksSheetState extends State<_BookmarksSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.3, 0.5, 0.9],
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
                top: BorderSide(
                    color: widget.primaryColor.withOpacity(0.15), width: 0.8)),
          ),
          child: Directionality(
            textDirection: Get.locale?.languageCode == 'en'
                ? TextDirection.ltr
                : TextDirection.rtl,
            child: Column(children: [
              const SizedBox(height: 10),
              Center(
                  child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                          color: widget.subColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text(AppLocaleKeys.playerBookmarksSaved.tr,
                  style: TextStyle(
                      color: widget.textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              Divider(color: widget.subColor.withOpacity(0.1), height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      AudioBookmarkService.getBookmarks(widget.recitationId),
                  builder: (_, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Center(
                          child: Text(AppLocaleKeys.playerNoBookmarks.tr,
                              style: TextStyle(color: widget.subColor)));
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      itemCount: snap.data!.length,
                      itemBuilder: (_, i) {
                        final b = snap.data![i];
                        final pos = Duration(milliseconds: b['position']);
                        return ListTile(
                          leading:
                              Icon(Icons.bookmark, color: _AppColors.accentRed),
                          title: Text(b['name'],
                              style: TextStyle(color: widget.textColor)),
                          subtitle: Text(widget.printDuration(pos),
                              style: TextStyle(
                                  color: widget.subColor, fontSize: 12)),
                          trailing: IconButton(
                            icon:
                                Icon(Icons.delete, color: widget.primaryColor),
                            onPressed: () async {
                              await AudioBookmarkService.removeBookmark(
                                  widget.recitationId, i);
                              setState(() {});
                            },
                          ),
                          onTap: () {
                            widget.audioPlayer.seek(pos);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── PositionData ──
class PositionData {
  final Duration position, bufferedPosition, duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}
