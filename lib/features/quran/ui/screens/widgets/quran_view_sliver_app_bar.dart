import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/translations/app_locale_keys.dart';
import '../../../../../core/utils/platform.dart';

import '../../../data/models/shaykh.dart';

class QuranViewSliverAppBar extends StatelessWidget {
  final Shaykh shaykh;
  final bool isDark;
  final bool isBatchDownloading;
  final VoidCallback onToggleBatchDownload;
  final String mushafName;

  const QuranViewSliverAppBar({
    super.key,
    required this.shaykh,
    required this.isDark,
    required this.isBatchDownloading,
    required this.onToggleBatchDownload,
    required this.mushafName,
  });

  String _getFixedUrl(String url) {
    if (isAndroid &&
        (url.contains('localhost') || url.contains('127.0.0.1'))) {
      return url
          .replaceFirst(
            RegExp(r'localhost|127\.0\.0\.1'),
            'mihrab-app.alwaysdata.net',
          )
          .replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final fixedImageUrl = _getFixedUrl(shaykh.imageUrl);
    return SliverAppBar(
      key: ValueKey('appbar_${isDark ? "dark" : "light"}'),
      expandedHeight: 450.0,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: Icon(
            isBatchDownloading ? Icons.cancel : Icons.download_for_offline,
          ),
          tooltip: isBatchDownloading
              ? AppLocaleKeys.cancelDownload.tr
              : AppLocaleKeys.downloadAll.tr,
          onPressed: onToggleBatchDownload,
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top < 150;
          final accentColor =
              isDark ? const Color(0xFF79D8C4) : const Color(0xFF0F6A5C);

          return Container(
            color: isDark ? const Color(0xFF0A1F1B) : const Color(0xFFF5F5F5),
            child: FlexibleSpaceBar(
              centerTitle: true,
              title: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCollapsed ? 1.0 : 0.0,
                child: Text(
                  shaykh.name,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: fixedImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(
                      color:
                          isDark ? const Color(0xFF112824) : Colors.grey[200],
                    ),
                    errorWidget: (_, __, ___) => Image.asset(
                      'assets/default_shaykh.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          isDark
                              ? const Color(0xFF0A1F1B).withOpacity(0.8)
                              : const Color(0xFFF5F5F5).withOpacity(0.8),
                          isDark
                              ? const Color(0xFF0A1F1B)
                              : const Color(0xFFF5F5F5),
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          shaykh.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF1E2A4A),
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: accentColor.withOpacity(0.5),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Text(
                            mushafName,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                            ),
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
    );
  }
}
