import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/translations/app_locale_keys.dart';
import '../../../home/ui/widgets/main_drawer.dart';
import '../../data/adhkar_model.dart';
import '../../data/adhkar_service.dart';
import 'adhkar_details_screen.dart';

class AdhkarCategoriesScreen extends StatefulWidget {
  const AdhkarCategoriesScreen({super.key});

  @override
  State<AdhkarCategoriesScreen> createState() => _AdhkarCategoriesScreenState();
}

class _AdhkarCategoriesScreenState extends State<AdhkarCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<AdhkarCategory>> _adhkarFuture;

  List<AdhkarCategory> _allCategories = [];
  List<AdhkarCategory> _filteredCategories = [];

  bool get _isArabic => Get.locale?.languageCode != 'en';

  @override
  void initState() {
    super.initState();
    _adhkarFuture = _loadData();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<AdhkarCategory>> _loadData() async {
    final data = await AdhkarService.getAdhkar();
    _allCategories = data;
    _filteredCategories = data;
    return data;
  }

  void _filterCategories() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        return category.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.trim().toLowerCase();
    if (name.contains('morning')) return Icons.wb_sunny_rounded;
    if (name.contains('evening')) return Icons.nightlight_round;
    if (name.contains('sleep') || name.contains('sleeping')) return Icons.bed_rounded;
    if (name.contains('waking') || name.contains('wake up')) return Icons.alarm_on_rounded;
    if (name.contains('prayer') || name.contains('mosque')) {
      return Icons.mosque_rounded;
    }
    if (name.contains('ablution') || name.contains('wudu')) return Icons.water_drop_rounded;
    if (name.contains('home') || name.contains('enter'))
      return Icons.home_rounded;
    if (name.contains('toilet') || name.contains('bathroom')) return Icons.wc_rounded;
    if (name.contains('food') || name.contains('eating')) return Icons.restaurant_rounded;
    if (name.contains('travel') || name.contains('journey')) return Icons.flight_takeoff_rounded;
    if (name.contains('hajj') || name.contains('umrah'))
      return Icons.groups_rounded;
    if (name.contains('sick') || name.contains('illness')) {
      return Icons.local_hospital_rounded;
    }
    if (name.contains('death') || name.contains('condolence')) {
      return Icons.sentiment_dissatisfied_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bgTop = const Color(0xFF071814);
    final bgBottom = const Color(0xFF0E241E);
    final titleColor = Colors.white;
    final subColor = Colors.white.withOpacity(0.68);
    final cardColor = const Color(0xFF132D26);
    final borderColor = Colors.white.withOpacity(0.08);
    final accent = const Color(0xFF74D7C0);
    final accentDark = const Color(0xFF2A8B68);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgBottom,
        drawer: const MainDrawer(),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildHeader(titleColor, subColor),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                  child: _buildSearchField(
                    titleColor: titleColor,
                    subColor: subColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    accent: accent,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<AdhkarCategory>>(
                    future: _adhkarFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: accentDark),
                        );
                      }

                      if (_filteredCategories.isEmpty) {
                        return _buildEmptyState(
                            titleColor, subColor, accentDark);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          return _buildCategoryCard(
                            category,
                            titleColor: titleColor,
                            subColor: subColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            accent: accent,
                            accentDark: accentDark,
                          );
                        },
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

  Widget _buildHeader(Color titleColor, Color subColor) {
    return Row(
      children: [
        Builder(
          builder: (context) => _HeaderCircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocaleKeys.hisnAlmuslim.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocaleKeys.dailyAdhkar.tr,
                style: TextStyle(
                  color: subColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField({
    required Color titleColor,
    required Color subColor,
    required Color cardColor,
    required Color borderColor,
    required Color accent,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              hintText: AppLocaleKeys.searchAdhkar.tr,
              hintStyle: TextStyle(color: subColor),
              prefixIcon: Icon(Icons.search_rounded, color: accent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, color: subColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterCategories();
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    AdhkarCategory category, {
    required Color titleColor,
    required Color subColor,
    required Color cardColor,
    required Color borderColor,
    required Color accent,
    required Color accentDark,
  }) {
    final countLabel =
        '${category.items.length} ${AppLocaleKeys.dhikrCountSuffix.tr}';
    final icon = _getCategoryIcon(category.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
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
                  color: accent.withOpacity(0.10),
                  blurRadius: 18,
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
                      builder: (_) => AdhkarDetailsScreen(category: category),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: _isArabic
                        ? [
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: subColor.withOpacity(0.75),
                              size: 16,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    category.category.tr,
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    countLabel,
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            _CategoryIconBubble(
                              icon: icon,
                              accent: accent,
                              accentDark: accentDark,
                            ),
                          ]
                        : [
                            _CategoryIconBubble(
                              icon: icon,
                              accent: accent,
                              accentDark: accentDark,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.category.tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    countLabel,
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: subColor.withOpacity(0.75),
                              size: 16,
                            ),
                          ],
                  ),
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
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.12),
              ),
              child: Icon(Icons.menu_book_rounded, color: accent, size: 46),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocaleKeys.noAdhkarFound.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isArabic
                  ? AppLocaleKeys.tryDifferentSearchWord.tr
                  : 'Try a different keyword to find the dhikr you want',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _CategoryIconBubble extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentDark;

  const _CategoryIconBubble({
    required this.icon,
    required this.accent,
    required this.accentDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF071814), size: 28),
    );
  }
}
