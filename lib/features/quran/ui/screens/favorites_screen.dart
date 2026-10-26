import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/translations/app_locale_keys.dart';
import '../../data/favorites_manager.dart';
import '../../data/models/recitation.dart';
import '../../data/models/shaykh.dart';
import 'media_player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Recitation> _favorites = [];
  bool _isLoading = true;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  String _t({required String ar, required String en}) {
    return _isArabic ? ar : en;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await FavoritesManager.loadFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF081713) : const Color(0xFFF7FBF8);
    final bgBottom = isDark ? const Color(0xFF0D231D) : const Color(0xFFE5F1EB);
    final cardColor = isDark ? const Color(0xFF133129) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF);
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor =
        isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6B857A);
    final accent = const Color(0xFF2A8B68);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgBottom,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgBottom],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          _isArabic
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: titleColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocaleKeys.favoritesLabel.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: accent,
                          ),
                        )
                      : _favorites.isEmpty
                          ? _buildEmptyState(titleColor, subColor, accent)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _favorites.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildFavoriteItem(
                                  recitation: _favorites[index],
                                  cardColor: cardColor,
                                  borderColor: borderColor,
                                  titleColor: titleColor,
                                  subColor: subColor,
                                  accent: accent,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteItem({
    required Recitation recitation,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
    required Color accent,
  }) {
    final shaykh = Shaykh(
      id: 'favorite_${recitation.id}',
      name: recitation.reciterName,
      bio: '',
      imageUrl: '',
      category: 'favorites',
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaPlayerScreen(
                      shaykh: shaykh,
                      currentRecitation: recitation,
                      allRecitations: [recitation],
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            accent.withOpacity(0.16),
                            accent.withOpacity(0.28),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: accent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recitation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            recitation.reciterName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await FavoritesManager.removeFavorite(
                            context, recitation);
                        await _loadData();
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD45B5B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color titleColor, Color subColor, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                color: accent,
                size: 46,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _t(
                ar: AppLocaleKeys.noFavoriteRecitations.tr,
                en: 'No favorite recitations yet',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                ar: AppLocaleKeys.addFavoritesHint.tr,
                en: 'You can add recitations to your favorites from the surah list',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subColor,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
