import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/ad_service.dart';
import '../../../../core/services/download_manager.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/utils/platform.dart';
import '../../../quran/data/models/recitation.dart';
import '../../../quran/data/models/shaykh.dart';
import '../../../quran/ui/screens/media_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Map<String, dynamic>> _allDownloads = [];
  List<Map<String, dynamic>> _filteredDownloads = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedReciter;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadData();
    AdService.showInterstitialAd();
  }

  Future<void> _loadData() async {
    final data = await DownloadManager.getAllDownloads();
    if (!mounted) return;
    setState(() {
      _allDownloads = data;
      _isLoading = false;
    });
    _filterData();
  }

  void _filterData() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _filteredDownloads = _allDownloads.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final reciter = (item['reciterName'] ?? '').toString();
        final matchesSearch = title.contains(query);
        final matchesReciter =
            _selectedReciter == null || reciter == _selectedReciter;
        return matchesSearch && matchesReciter;
      }).toList();
    });
  }

  List<String> get _reciters {
    final reciters = _allDownloads
        .map((e) => e['reciterName'] as String? ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    reciters.sort();
    return reciters;
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await _showDeleteConfirmDialog();
    if (!confirm) return;
    await DownloadManager.deleteDownload(item['filePath']);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF8B2E2E),
        content: Text(AppLocaleKeys.deletedSuccess.tr),
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF17352E);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor:
                isDark ? const Color(0xFF16312B) : const Color(0xFFF9FCFA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              AppLocaleKeys.deleteRecitation.tr,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              AppLocaleKeys.areYouSure.tr,
              style: TextStyle(color: textColor.withOpacity(0.75)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocaleKeys.commonCancel.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB33A3A),
                ),
                child: Text(AppLocaleKeys.commonDelete.tr),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _playItem(Map<String, dynamic> item) {
    final shaykh = Shaykh(
      id: item['shaykhId'] ?? '0',
      name: item['reciterName'] ?? (_isArabic ? 'قارئ' : 'Reciter'),
      bio: '',
      imageUrl: item['imageUrl'] ?? '',
      category: '',
    );

    final recitation = Recitation(
      id: item['id'] ?? '0',
      title: item['title'] ?? (_isArabic ? 'تلاوة' : 'Recitation'),
      audioUrl: item['filePath'],
      reciterName: shaykh.name,
    );

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
  }

  String _fixUrl(String url) {
    if (isAndroid && url.contains('localhost')) {
      return url
          .replaceFirst('localhost', 'mihrab-app.alwaysdata.net')
          .replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF081713) : const Color(0xFFF8FCF9);
    final bgBottom = isDark ? const Color(0xFF0E241E) : const Color(0xFFE5F1EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor =
        isDark ? Colors.white.withOpacity(0.68) : const Color(0xFF698379);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD8E8E0);
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: _buildHeader(titleColor),
                ),
                if (!_isLoading && _allDownloads.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: Column(
                      children: [
                        _buildSearchField(
                            titleColor, subColor, cardColor, borderColor),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 42,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildFilterChip(
                                label: AppLocaleKeys.allFilter.tr,
                                selected: _selectedReciter == null,
                                onTap: () {
                                  _selectedReciter = null;
                                  _filterData();
                                },
                                accent: accent,
                                cardColor: cardColor,
                                titleColor: titleColor,
                              ),
                              ..._reciters.map(
                                (reciter) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 8,
                                  ),
                                  child: _buildFilterChip(
                                    label: reciter,
                                    selected: _selectedReciter == reciter,
                                    onTap: () {
                                      _selectedReciter =
                                          _selectedReciter == reciter
                                              ? null
                                              : reciter;
                                      _filterData();
                                    },
                                    accent: accent,
                                    cardColor: cardColor,
                                    titleColor: titleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: accent),
                        )
                      : _filteredDownloads.isEmpty
                          ? _buildEmptyState(titleColor, subColor, accent)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                              itemCount: _filteredDownloads.length,
                              itemBuilder: (context, index) {
                                return _buildItem(
                                  _filteredDownloads[index],
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

  Widget _buildHeader(Color titleColor) {
    final arrow = IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        _isArabic
            ? Icons.arrow_back_ios_new_rounded
            : Icons.arrow_forward_ios_rounded,
        color: titleColor,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _isArabic
          ? [
              arrow,
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppLocaleKeys.downloadsTitle.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ]
          : [
              const SizedBox(width: 48),
              Expanded(
                child: Text(
                  AppLocaleKeys.downloadsTitle.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              arrow,
            ],
    );
  }

  Widget _buildSearchField(
    Color titleColor,
    Color subColor,
    Color cardColor,
    Color borderColor,
  ) {
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
            onChanged: (value) {
              _searchQuery = value;
              _filterData();
            },
            style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              hintText: AppLocaleKeys.searchBySurahName.tr,
              hintStyle: TextStyle(color: subColor),
              prefixIcon: Icon(Icons.search_rounded, color: subColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color accent,
    required Color cardColor,
    required Color titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? accent : cardColor,
          border: Border.all(
            color: selected ? accent : titleColor.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : titleColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    Map<String, dynamic> item, {
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
    required Color accent,
  }) {
    final imageUrl = _fixUrl(item['imageUrl'] ?? '');

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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              onTap: () => _playItem(item),
              leading: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: CircleAvatar(
                  backgroundColor: accent.withOpacity(0.08),
                  backgroundImage: imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imageUrl)
                      : const AssetImage('assets/default_shaykh.png')
                          as ImageProvider,
                ),
              ),
              title: Text(
                item['title'] ?? (_isArabic ? 'تلاوة' : 'Recitation'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item['reciterName'] ?? (_isArabic ? 'قارئ' : 'Reciter'),
                  style: TextStyle(
                    color: subColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFD45B5B),
                ),
                onPressed: () => _deleteItem(item),
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
              child: Icon(Icons.download_done_rounded, color: accent, size: 46),
            ),
            const SizedBox(height: 18),
            Text(
              AppLocaleKeys.noDownloadedRecitations.tr,
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
                  ? 'حمّل التلاوات من المشغل لتظهر لك هنا'
                  : 'Download recitations from the player to see them here',
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
