import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../auth/data/auth_service.dart';
import '../../../../auth/ui/screens/register_screen.dart';
import '../../../../../core/translations/app_locale_keys.dart';
import '../../../data/favorites_manager.dart';
import '../../../data/models/recitation.dart';
import '../../../data/models/shaykh.dart';
import '../../../logic/global_audio_manager.dart';
import '../../../../../core/services/download_manager.dart';
import '../media_player_screen.dart';

class RecitationCardWithFavorite extends StatefulWidget {
  final Recitation recitation;
  final int index;
  final List<Recitation> allRecitations;
  final Shaykh shaykh;
  final bool isDark;

  const RecitationCardWithFavorite({
    super.key,
    required this.recitation,
    required this.index,
    required this.allRecitations,
    required this.shaykh,
    required this.isDark,
  });

  @override
  State<RecitationCardWithFavorite> createState() =>
      _RecitationCardWithFavoriteState();
}

class _RecitationCardWithFavoriteState
    extends State<RecitationCardWithFavorite> {
  bool _isFavorite = false;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  int _progress = 0;
  int _status = 0;
  String? _currentTaskId;
  StreamSubscription? _downloadSubscription;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _checkDownloadStatus();
    _initDownloadListener();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _initDownloadListener() {
    _downloadSubscription = DownloadManager.updates.listen((update) {
      if (_currentTaskId == update.taskId ||
          update.url == widget.recitation.audioUrl) {
        _currentTaskId ??= update.taskId;
        if (mounted) {
          setState(() {
            _progress = update.progress;
            _status = _statusValue(update.status);
            if (_isCompleteStatus(update.status)) {
              _isDownloaded = true;
              _isDownloading = false;
              _currentTaskId = null;
            } else if (_isFailedStatus(update.status)) {
              _isDownloading = false;
              _currentTaskId = null;
            } else {
              _isDownloading = true;
            }
          });
        }
      }
    });

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isDownloading && !_isDownloaded) {
        _checkDownloadStatus();
      }
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await FavoritesManager.isFavorite(widget.recitation);
    if (mounted) setState(() => _isFavorite = status);
  }

  Future<void> _checkDownloadStatus() async {
    final downloaded =
        await DownloadManager.isDownloaded(widget.recitation, widget.shaykh);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        if (downloaded) {
          _isDownloading = false;
        } else {
          _reconnectToTask();
        }
      });
    }
  }

  int _statusValue(dynamic status) {
    if (status is int) return status;
    try {
      return status.index as int;
    } catch (_) {
      return 0;
    }
  }

  bool _isCompleteStatus(dynamic status) => _statusValue(status) == 3;

  bool _isFailedStatus(dynamic status) {
    final value = _statusValue(status);
    return value == 4 || value == 5;
  }

  bool _isActiveStatus(dynamic status) {
    final value = _statusValue(status);
    return value == 1 || value == 2 || value == 6;
  }

  Future<void> _reconnectToTask() async {
    final task = await DownloadManager.getTaskByUrl(widget.recitation.audioUrl);
    if (task != null && _isActiveStatus(task.status) && mounted) {
      setState(() {
        _currentTaskId = task.taskId;
        _isDownloading = true;
        _progress = task.progress;
        _status = _statusValue(task.status);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await FavoritesManager.removeFavorite(context, widget.recitation);
    } else {
      await FavoritesManager.addFavorite(context, widget.recitation);
    }
    _checkFavoriteStatus();
  }

  Future<void> _startDownload() async {
    final isGuest = await AuthService.isGuest();
    if (isGuest) {
      if (mounted) _showGuestDialog();
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد اتصال بالإنترنت.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    try {
      final taskId =
          await DownloadManager.startDownload(widget.recitation, widget.shaykh);
      if (taskId != null && mounted) {
        setState(() => _currentTaskId = taskId);
      }
    } catch (_) {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocaleKeys.guestAlertTitle.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocaleKeys.guestAlertMessage.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocaleKeys.commonCancel.tr, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDark
                    ? const Color(0xFF79D8C4)
                    : const Color(0xFF0F6A5C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocaleKeys.registerNow.tr,
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(String durationStr) {
    if (durationStr.contains(':')) {
      final parts = durationStr.split(':');
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        if (hours > 0) {
          return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        }
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
      return durationStr;
    }
    final totalSeconds = int.tryParse(durationStr);
    if (totalSeconds == null) return durationStr;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        widget.isDark ? Colors.white.withOpacity(0.03) : Colors.white;
    final borderColor = widget.isDark
        ? const Color(0xFF79D8C4).withOpacity(0.2)
        : Colors.grey.withOpacity(0.2);
    final textColor =
        widget.isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final accentColor =
        widget.isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C);

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              GlobalAudioManager().isPlayerExpanded.value = true;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MediaPlayerScreen(
                    allRecitations: widget.allRecitations,
                    shaykh: widget.shaykh,
                    currentRecitation: widget.recitation,
                  ),
                ),
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 38,
                        color: accentColor.withOpacity(0.15),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Center(
                          child: Text(
                            (widget.index + 1).toString(),
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recitation.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.recitation.duration != null &&
                                widget.recitation.duration!
                                    .trim()
                                    .isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.2),
                                    width: 0.6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: accentColor.withOpacity(0.8),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(
                                          widget.recitation.duration!.trim()),
                                      style: TextStyle(
                                        color: accentColor.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (widget.recitation.mushafName != null)
                              Expanded(
                                child: Text(
                                  widget.recitation.mushafName!,
                                  style: TextStyle(
                                    color: accentColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildDownloadButton(),
                  IconButton(
                    icon: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavorite
                          ? Colors.redAccent
                          : accentColor.withOpacity(0.4),
                      size: 22,
                    ),
                    onPressed: _toggleFavorite,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    final goldColor =
        widget.isDark ? const Color(0xFFD4AF37) : const Color(0xFFB8860B);
    if (_isDownloading) {
      final isPaused = _status == 6;
      return InkWell(
        onTap: () async {
          if (_currentTaskId == null) return;
          if (isPaused) {
            await DownloadManager.resumeDownload(_currentTaskId!);
          } else {
            await DownloadManager.pauseDownload(_currentTaskId!);
            if (mounted) setState(() => _status = 6);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_progress%',
                style: TextStyle(
                  color: isPaused ? Colors.orange : goldColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 16,
                color: isPaused ? Colors.orange : goldColor,
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPaused ? Colors.orange : goldColor,
                  value: _progress > 0 ? _progress / 100 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_isDownloaded) {
      return Icon(Icons.check_circle_rounded,
          color: goldColor.withOpacity(0.8), size: 22);
    }
    return IconButton(
      icon: Icon(Icons.download_rounded,
          color: goldColor.withOpacity(0.4), size: 22),
      onPressed: _startDownload,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
    );
  }
}
