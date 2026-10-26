import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../data/models/quran_reciter_model.dart';

/// ويدجت اختيار القارئ
class ReciterSelector extends StatelessWidget {
  final bool isDark;
  final String selectedReciterId;
  final List<QuranReciterModel> reciters;
  final ValueChanged<String> onReciterChanged;

  const ReciterSelector({
    super.key,
    required this.isDark,
    required this.selectedReciterId,
    required this.reciters,
    required this.onReciterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final cardColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // الحصول على اسم القارئ الحالي لعرضه
    final currentReciter = reciters.firstWhere(
      (r) => r.id == selectedReciterId,
      orElse: () => reciters.isNotEmpty ? reciters.first : QuranReciterModel(id: '', reciterName: AppLocaleKeys.unknownReciter.tr, translatedName: AppLocaleKeys.unknownReciter.tr),
    );

    return InkWell(
      onTap: () => _showRecitersBottomSheet(context, accentColor, textColor),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.record_voice_over, size: 20, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocaleKeys.currentReciter.tr,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    currentReciter.arabicName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: accentColor),
          ],
        ),
      ),
    );
  }

  void _showRecitersBottomSheet(BuildContext context, Color accentColor, Color textColor) {
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    // التقسيمات
    final allReciters = reciters;
    final murattal = reciters.where((r) => r.categoryName == 'مرتل' || r.categoryName == 'Murattal').toList();
    final mujawwad = reciters.where((r) => r.categoryName == 'مجود' || r.categoryName == 'Mujawwad').toList();
    final muallim = reciters.where((r) => r.categoryName == 'معلم' || r.categoryName == 'Muallim').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر القارئ',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: textColor.withOpacity(0.5),
                  labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: AppLocaleKeys.allFilter.tr),
                    Tab(text: AppLocaleKeys.reciterTypeMurattal.tr),
                    Tab(text: AppLocaleKeys.reciterTypeMujawwad.tr),
                    Tab(text: AppLocaleKeys.reciterTypeMuallim.tr),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRecitersList(allReciters, accentColor, textColor, context),
                      _buildRecitersList(murattal, accentColor, textColor, context),
                      _buildRecitersList(mujawwad, accentColor, textColor, context),
                      _buildRecitersList(muallim, accentColor, textColor, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecitersList(List<QuranReciterModel> list, Color accentColor, Color textColor, BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد قراء في هذا القسم',
          style: TextStyle(color: textColor.withOpacity(0.5), fontFamily: 'Cairo'),
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final reciter = list[index];
        final isSelected = reciter.id == selectedReciterId;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected ? accentColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            child: Icon(
              isSelected ? Icons.check : Icons.person_outline,
              color: isSelected ? accentColor : textColor.withOpacity(0.7),
            ),
          ),
          title: Text(
            reciter.arabicName,
            style: TextStyle(
              color: isSelected ? accentColor : textColor,
              fontFamily: 'Cairo',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            reciter.categoryName,
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
          onTap: () {
            onReciterChanged(reciter.id);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
