import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran_utils;
import '../../../../core/translations/app_locale_keys.dart';
import '../../logic/quran_audio_provider.dart';

class AdvancedRepeatSheet extends StatefulWidget {
  final int surahNumber;
  final int initialStartAyah;
  final bool isDark;

  const AdvancedRepeatSheet({
    super.key,
    required this.surahNumber,
    required this.initialStartAyah,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int initialStartAyah,
    required bool isDark,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdvancedRepeatSheet(
        surahNumber: surahNumber,
        initialStartAyah: initialStartAyah,
        isDark: isDark,
      ),
    );
  }

  @override
  State<AdvancedRepeatSheet> createState() => _AdvancedRepeatSheetState();
}

class _AdvancedRepeatSheetState extends State<AdvancedRepeatSheet> {
  late int _startAyah;
  late int _endAyah;
  int _ayahRepeat = 1;
  int _blockRepeat = 1;

  late int _totalVerses;

  @override
  void initState() {
    super.initState();
    _totalVerses = quran_utils.getVerseCount(widget.surahNumber);
    _startAyah = widget.initialStartAyah;
    _endAyah = widget.initialStartAyah;
  }

  Color get _accentColor => widget.isDark ? const Color(0xFF8BC34A) : const Color(0xFF2E7D32);
  Color get _surfaceColor => widget.isDark ? const Color(0xFF1A2E1A) : Colors.white;
  Color get _bgColor => widget.isDark ? const Color(0xFF121A12) : const Color(0xFFF8F4E8);
  Color get _goldColor => widget.isDark ? const Color(0xFFD4A437) : const Color(0xFFB8860B);
  Color get _textColor => widget.isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: _goldColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(Icons.repeat_rounded, color: _goldColor, size: 24),
              const SizedBox(width: 8),
              Text(
                AppLocaleKeys.advancedRepeatTitle.tr,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _goldColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── نطاق الآيات ──
          _buildSectionTitle(Icons.library_books_rounded, AppLocaleKeys.rangeSection.tr),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _goldColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildAyahSelector(
                    label: AppLocaleKeys.fromAyah.tr,
                    value: _startAyah,
                    items: List.generate(_totalVerses, (i) => i + 1),
                    onChanged: (val) {
                      setState(() {
                        _startAyah = val!;
                        if (_endAyah < _startAyah) _endAyah = _startAyah;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAyahSelector(
                    label: AppLocaleKeys.toAyah.tr,
                    value: _endAyah,
                    items: List.generate(_totalVerses - _startAyah + 1, (i) => _startAyah + i),
                    onChanged: (val) {
                      setState(() => _endAyah = val!);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── إعدادات التكرار ──
          _buildSectionTitle(Icons.settings_rounded, AppLocaleKeys.repeatSettingsSection.tr),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _goldColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildRepeatCounter(
                  label: AppLocaleKeys.ayahRepeatLabel.tr,
                  value: _ayahRepeat,
                  onChanged: (val) => setState(() => _ayahRepeat = val),
                  allowInfinite: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildRepeatCounter(
                  label: AppLocaleKeys.blockRepeatLabel.tr,
                  value: _blockRepeat,
                  onChanged: (val) => setState(() => _blockRepeat = val),
                  allowInfinite: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── زر البدء ──
          ElevatedButton(
            onPressed: () {
              final audioProvider = Provider.of<QuranAudioProvider>(context, listen: false);
              audioProvider.playAdvancedRepeat(
                startSurah: widget.surahNumber,
                startAyah: _startAyah,
                endSurah: widget.surahNumber,
                endAyah: _endAyah,
                ayahRepeatCount: _ayahRepeat,
                blockRepeatCount: _blockRepeat,
              );
              Navigator.pop(context); // Close advanced repeat sheet
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Text(
              AppLocaleKeys.startRecitation.tr,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAyahSelector({
    required String label,
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: _textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _accentColor.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: _surfaceColor,
              icon: Icon(Icons.keyboard_arrow_down, color: _accentColor),
              items: items.map((e) {
                return DropdownMenuItem<int>(
                  value: e,
                  child: Text(
                    '$e',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    bool allowInfinite = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        Row(
          children: [
            _counterButton(
              icon: Icons.remove_rounded,
              onTap: value > 1 || (allowInfinite && value == -1) ? () {
                if (value == -1) {
                  onChanged(10);
                } else {
                  onChanged(value - 1);
                }
              } : null,
            ),
            Container(
              width: 50,
              alignment: Alignment.center,
              child: Text(
                value == -1 ? '∞' : '$value',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ),
            _counterButton(
              icon: Icons.add_rounded,
              onTap: () {
                if (value == -1) return;
                if (value >= 10 && allowInfinite) {
                  onChanged(-1);
                } else {
                  onChanged(value + 1);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _counterButton({required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? _accentColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? _accentColor.withOpacity(0.2) : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? _accentColor : Colors.grey,
        ),
      ),
    );
  }
}
