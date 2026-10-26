import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../home/ui/screens/home_screen.dart';
import '../../data/models/mushaf_category.dart';
import '../../data/models/shaykh.dart';
import 'mushaf_selection_screen.dart';
import 'quran_view_screen.dart';

class ShaykhsScreen extends StatefulWidget {
  final String initialCategory;

  const ShaykhsScreen({
    super.key,
    this.initialCategory = 'all',
  });

  @override
  State<ShaykhsScreen> createState() => _ShaykhsScreenState();
}

class _ShaykhsScreenState extends State<ShaykhsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Shaykh> _allShaykhs = [];
  Map<String, List<Shaykh>> _groupedShaykhs = {};
  List<String> _sortedKeys = [];
  bool _isLoading = true;
  late String _selectedCategory;

  bool get _isArabic => Get.locale?.languageCode == 'ar';
  bool get _isEnglish => Get.locale?.languageCode == 'en';

  String _t({required String ar, required String en}) => _isEnglish ? en : ar;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetchedShaykhs = await ApiService.getShaykhs();
      final customShaykh = Shaykh(
        id: 'saad_hamouda_manual',
        name: 'سعد حمودة',
        bio: _t(ar: 'دروس دينية ومواعظ', en: 'Religious lessons and reminders'),
        imageUrl:
            'https://mihrab-app.alwaysdata.net/uploads/images/default_reciter.png',
        category: 'hawamdia',
        availableMushafs: [
          MushafCategory(id: '33', name: _t(ar: 'تفسير', en: 'Tafsir')),
          MushafCategory(
            id: '101',
            name: _t(ar: 'خواطر إيمانية', en: 'Faith reflections'),
            isSeries: true,
          ),
        ],
      );

      final existingIndex =
          fetchedShaykhs.indexWhere((s) => s.name.contains('سعد حمودة'));

      if (existingIndex != -1) {
        final existing = fetchedShaykhs[existingIndex];
        final hasTafsir =
            existing.availableMushafs.any((m) => m.name.contains('تفسير'));
        if (!hasTafsir) {
          fetchedShaykhs[existingIndex] = Shaykh(
            id: existing.id,
            name: existing.name,
            bio: existing.bio,
            imageUrl: existing.imageUrl,
            category: existing.category,
            availableMushafs: [
              ...existing.availableMushafs,
              MushafCategory(id: '33', name: _t(ar: 'تفسير', en: 'Tafsir')),
            ],
          );
        }
      } else {
        fetchedShaykhs.add(customShaykh);
      }

      if (!mounted) return;
      setState(() {
        _allShaykhs = fetchedShaykhs;
        _isLoading = false;
      });
      _groupAndFilterShaykhs();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8B2E2E),
          content: Text(
            _t(
              ar: 'حدث خطأ أثناء تحميل القراء',
              en: 'Failed to load reciters',
            ),
          ),
          action: SnackBarAction(
            label: _t(ar: 'إعادة', en: 'Retry'),
            textColor: Colors.white,
            onPressed: _loadData,
          ),
        ),
      );
    }
  }

  void _groupAndFilterShaykhs() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allShaykhs.where((s) {
      final matchesName = s.name.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'all' ||
          s.category == _selectedCategory ||
          (_selectedCategory == 'lessons' && s.name.contains('سعد حمودة'));
      return matchesName && matchesCategory;
    }).toList()
      ..sort(
        (a, b) => _normalizeForSorting(a.name).compareTo(
          _normalizeForSorting(b.name),
        ),
      );

    final groups = <String, List<Shaykh>>{};
    for (final shaykh in filtered) {
      final name = shaykh.name.trim();
      if (name.isEmpty) continue;
      final key = _normalizeChar(name[0].toUpperCase());
      groups.putIfAbsent(key, () => []).add(shaykh);
    }

    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'م') return -1;
        if (b == 'م') return 1;
        return a.compareTo(b);
      });

    setState(() {
      _groupedShaykhs = groups;
      _sortedKeys = sortedKeys;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  String _normalizeChar(String char) {
    if (['أ', 'إ', 'آ', 'ٱ'].contains(char)) return 'ا';
    return char;
  }

  String _normalizeForSorting(String text) {
    return text
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll(RegExp('[ة]'), 'ه')
        .replaceAll(RegExp('[ى]'), 'ي');
  }

  void _onSearchChanged() => _groupAndFilterShaykhs();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;
    final bgTop = isDark ? const Color(0xFF071814) : const Color(0xFFF7FBF8);
    final bgBottom = isDark ? const Color(0xFF0E241E) : const Color(0xFFE4F0EA);
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor =
        isDark ? Colors.white.withOpacity(0.68) : const Color(0xFF6A8479);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD7E8DF);
    final accent = const Color(0xFF74D7C0);
    final accentDark = const Color(0xFF2A8B68);

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildHeader(titleColor),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildFilterChip(
                        label: _t(ar: 'الكل', en: 'All'),
                        value: 'all',
                        titleColor: titleColor,
                        cardColor: cardColor,
                        accent: accent,
                        accentDark: accentDark,
                      ),
                      _buildFilterChip(
                        label: _t(ar: 'دروس دينية', en: 'Lessons'),
                        value: 'lessons',
                        titleColor: titleColor,
                        cardColor: cardColor,
                        accent: accent,
                        accentDark: accentDark,
                      ),
                      _buildFilterChip(
                        label: _t(ar: 'شيوخ الجيزة', en: 'Giza Voices'),
                        value: 'hawamdia',
                        titleColor: titleColor,
                        cardColor: cardColor,
                        accent: accent,
                        accentDark: accentDark,
                      ),
                      _buildFilterChip(
                        label: _t(ar: 'ترتيل', en: 'Tartil'),
                        value: 'tartil',
                        titleColor: titleColor,
                        cardColor: cardColor,
                        accent: accent,
                        accentDark: accentDark,
                      ),
                      _buildFilterChip(
                        label: _t(ar: 'تجويد', en: 'Tajweed'),
                        value: 'tajweed',
                        titleColor: titleColor,
                        cardColor: cardColor,
                        accent: accent,
                        accentDark: accentDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: _buildSearchBar(
                      titleColor, subColor, cardColor, borderColor),
                ),
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 6,
                          itemBuilder: (_, __) => _buildSkeleton(
                            cardColor: cardColor,
                            borderColor: borderColor,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          color: accentDark,
                          child: _sortedKeys.isEmpty
                              ? ListView(
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.55,
                                      child: Center(
                                        child: Text(
                                          _t(
                                            ar: 'لا توجد نتائج',
                                            en: 'No results found',
                                          ),
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _sortedKeys.length,
                                  itemBuilder: (context, index) {
                                    final letter = _sortedKeys[index];
                                    final items = _groupedShaykhs[letter]!;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildLetterHeader(
                                          letter,
                                          accentDark,
                                          titleColor,
                                        ),
                                        ...items.map(
                                          (shaykh) => _buildShaykhListItem(
                                            shaykh,
                                            cardColor: cardColor,
                                            borderColor: borderColor,
                                            titleColor: titleColor,
                                            subColor: subColor,
                                            accent: accentDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    );
                                  },
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
    final arrow = IconButton(
      icon: Icon(
        _isArabic
            ? Icons.arrow_back_ios_new_rounded
            : Icons.arrow_forward_ios_rounded,
        color: titleColor,
      ),
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _isArabic
          ? [
              arrow,
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _t(ar: 'قراء القرآن الكريم', en: 'Holy Quran Reciters'),
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
                  _t(ar: 'قراء القرآن الكريم', en: 'Holy Quran Reciters'),
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

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color titleColor,
    required Color cardColor,
    required Color accent,
    required Color accentDark,
  }) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = value);
          _groupAndFilterShaykhs();
        },
        selectedColor: accentDark,
        backgroundColor: cardColor,
        side: BorderSide(
          color: isSelected ? accentDark : titleColor.withOpacity(0.08),
        ),
        checkmarkColor: accent,
      ),
    );
  }

  Widget _buildSearchBar(
    Color titleColor,
    Color subColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintText: _t(ar: 'ابحث عن قارئ...', en: 'Search for a reciter...'),
          hintStyle: TextStyle(color: subColor),
          prefixIcon: Icon(Icons.search_rounded, color: subColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, color: subColor),
                  onPressed: () {
                    _searchController.clear();
                    _groupAndFilterShaykhs();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLetterHeader(String letter, Color accent, Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.16),
              border: Border.all(color: accent.withOpacity(0.35)),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: titleColor.withOpacity(0.12)),
          ),
        ],
      ),
    );
  }

  Widget _buildShaykhListItem(
    Shaykh shaykh, {
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToReciterView(shaykh),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: CircleAvatar(
                    radius: 29,
                    backgroundColor: accent.withOpacity(0.08),
                    backgroundImage:
                        CachedNetworkImageProvider(shaykh.imageUrl),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shaykh.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(shaykh.category),
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (shaykh.availableMushafs.length == 1)
                  _buildMushafBadge(shaykh.availableMushafs.first.name, accent)
                else if (shaykh.availableMushafs.length > 1)
                  _buildMushafBadge(
                    _t(
                      ar: '${shaykh.availableMushafs.length} تصفح',
                      en: '${shaykh.availableMushafs.length} Browse',
                    ),
                    accent,
                  ),
                const SizedBox(width: 8),
                Icon(
                  _isArabic
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: subColor.withOpacity(0.7),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMushafBadge(String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSkeleton({
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 84,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
    );
  }

  void _navigateToReciterView(Shaykh shaykh) {
    if (shaykh.availableMushafs.length > 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MushafSelectionScreen(shaykh: shaykh),
        ),
      );
      return;
    }

    final mushafId = shaykh.availableMushafs.isNotEmpty
        ? shaykh.availableMushafs.first.id
        : null;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranViewScreen(
          shaykh: shaykh,
          mushafId: mushafId,
        ),
      ),
    );
  }

  String _getCategoryName(String cat) {
    if (cat == 'hawamdia') {
      return _t(ar: 'شيوخ الجيزة', en: 'Giza voices');
    }
    if (cat == 'lessons') {
      return _t(ar: 'دروس دينية', en: 'Religious lessons');
    }
    if (cat == 'tartil') {
      return _t(ar: 'مرتل', en: 'Tartil');
    }
    if (cat == 'tajweed') {
      return _t(ar: 'مجود', en: 'Tajweed');
    }
    return _t(ar: 'قارئ', en: 'Reciter');
  }
}
