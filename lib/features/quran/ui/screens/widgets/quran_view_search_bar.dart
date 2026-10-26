import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/translations/app_locale_keys.dart';

class QuranViewSearchBar extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;

  const QuranViewSearchBar({
    super.key,
    required this.isDark,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? const Color(0xFF79D8C4).withOpacity(0.2)
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: AppLocaleKeys.searchSurahHint.tr,
            hintStyle:
                TextStyle(color: isDark ? Colors.white54 : Colors.black45),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? const Color(0xFF79D8C4) : Colors.grey,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: isDark ? Colors.white54 : Colors.black45,
                    onPressed: controller.clear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }
}
