import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../logic/global_audio_manager.dart'; // Import GlobalAudioManager
import '../screens/media_player_screen.dart';
import '../../data/models/shaykh.dart';
import '../../data/models/recitation.dart';
// ✅ استيراد ملف main.dart للوصول لـ navigatorKey
import 'package:mihrab/core/utils/keys.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  bool _hasUsableArtwork(String? uri) {
    if (uri == null || uri.isEmpty || uri == 'null') return false;
    return uri.startsWith('http') && !uri.contains('default_reciter.png');
  }

  @override
  Widget build(BuildContext context) {
    final globalManager = GlobalAudioManager(); // Use global manager
    final player = globalManager.player; // Get global player instance
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final progressBarColor = isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;

    return ValueListenableBuilder<bool>(
      valueListenable: globalManager.isPlayerExpanded,
      builder: (context, isExpanded, child) {
        if (isExpanded) return const SizedBox.shrink();

        // ✅ Check showMiniPlayer flag
        return ValueListenableBuilder<bool>(
          valueListenable: globalManager.showMiniPlayer,
          builder: (context, showIt, child) {
            if (!showIt) return const SizedBox.shrink();

            return StreamBuilder<SequenceState?>(
              stream: player.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) return const SizedBox.shrink();

                final metadata = state!.currentSource!.tag as MediaItem;
                if (metadata.extras == null) return const SizedBox.shrink();
                final artworkUrl = metadata.artUri?.toString();
                final hasArtwork = _hasUsableArtwork(artworkUrl);

                final Recitation recitation = Recitation.fromJson(metadata.extras!['recitation']);

                final currentShaykh = Shaykh(
                  id: '0',
                  name: metadata.album ?? 'الشيخ',
                  bio: '',
                  imageUrl: artworkUrl ?? '',
                  category: '',
                );

                return GestureDetector(
                  onTap: () {
                    // 🚀 FIX: تعيين isPlayerExpanded على true فوراً لإخفاء المشغل المصغر
                    globalManager.isPlayerExpanded.value = true;

                    // ✅ استخدام navigatorKey لفتح الصفحة من أي مكان
                    navigatorKey.currentState!.push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => MediaPlayerScreen(
                          shaykh: currentShaykh,
                          currentRecitation: recitation,
                          allRecitations: const [],
                          isOpeningFromMiniPlayer: true,
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                            child: child, // ✅ تم تصحيح الخطأ هنا
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    height: 64,
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 82),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: hasArtwork
                                      ? CachedNetworkImage(
                                          imageUrl: artworkUrl!,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorWidget: (c, u, e) => Image.asset(
                                            'assets/logo.png',
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/logo.png',
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(metadata.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.bold,  fontSize: 13)),
                                    Text(metadata.album ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subTextColor,  fontSize: 11)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StreamBuilder<PlayerState>(
                                    stream: player.playerStateStream,
                                    builder: (context, snapshot) {
                                      final playing = snapshot.data?.playing ?? false;
                                      return IconButton(
                                        icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: textColor),
                                        onPressed: () => playing ? player.pause() : player.play(),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, size: 20, color: subTextColor),
                                    onPressed: () {
                                      globalManager.isPlayerExpanded.value = false;
                                      globalManager.showMiniPlayer.value = false; // ✅ Hide explicitly on close
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final duration = player.duration ?? Duration.zero;
                            double progress = (duration.inMilliseconds > 0) ? position.inMilliseconds / duration.inMilliseconds : 0.0;
                            return Align(
                              alignment: Alignment.bottomLeft,
                              child: FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(height: 2, decoration: BoxDecoration(color: progressBarColor, borderRadius: BorderRadius.circular(2))),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        );
      },
    );
  }
}
