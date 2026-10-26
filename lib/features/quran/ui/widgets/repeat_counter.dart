import 'package:flutter/material.dart';

/// ويدجت عداد التكرار للآية
class RepeatCounter extends StatelessWidget {
  final bool isDark;
  final int count;
  final ValueChanged<int> onChanged;

  const RepeatCounter({
    super.key,
    required this.isDark,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? Colors.cyanAccent : const Color(0xFF8B6F47);
    final cardColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(
            'التكرار:',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // زر ناقص
          _roundButton(
            icon: Icons.remove,
            color: accentColor,
            onTap: count > 1 ? () => onChanged(count - 1) : null,
          ),

          const SizedBox(width: 12),

          // العدد
          GestureDetector(
            onTap: () => _showNumberPicker(context, accentColor, textColor),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count >= 100 ? '∞' : '$count',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // زر زائد
          _roundButton(
            icon: Icons.add,
            color: accentColor,
            onTap: count < 100 ? () => onChanged(count + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? color : Colors.grey,
        ),
      ),
    );
  }

  void _showNumberPicker(BuildContext context, Color accentColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) {
        int tempCount = count;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'اختر عدد التكرارات',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: tempCount.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: accentColor,
                    label: '$tempCount',
                    onChanged: (value) {
                      setDialogState(() => tempCount = value.toInt());
                    },
                  ),
                  Text(
                    '$tempCount مرة',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // خيارات سريعة
                  Wrap(
                    spacing: 8,
                    children: [3, 5, 7, 10, 20, 50].map((num) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => tempCount = num);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: tempCount == num
                                ? accentColor
                                : accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$num',
                            style: TextStyle(
                              color: tempCount == num ? Colors.white : accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(tempCount);
                    Navigator.pop(context);
                  },
                  child: Text('تم', style: TextStyle(color: accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
