
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool isGoldBorder; // ميزة الإطار الذهبي (للمشايخ)

  const GlassCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.isGoldBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(20);

    // ✅✅ التصميم الذكي:
    // 1. إذا كان داكن: نستخدم الزجاج (BackdropFilter)
    // 2. إذا كان فاتح: نستخدم كارت أبيض عادي (Container) بدون فلتر

    if (!isDark) {
      // --- تصميم الوضع الفاتح (أبيض ونظيف) ---
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white, // أبيض صريح
          borderRadius: radius,
          // ظل ناعم جداً لإبرازه عن الخلفية
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200), // حدود رمادية خفيفة
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: Colors.grey.withOpacity(0.1),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      );
    }

    // --- تصميم الوضع الداكن (الزجاجي الفخم) ---
    // --- تصميم الوضع الداكن (محسن للأداء - بدون ضبابية ثقيلة) ---
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          // ظل خفيف جداً للأداء
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          if (isGoldBorder)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          highlightColor: Colors.white.withOpacity(0.05),
          splashColor: Colors.white.withOpacity(0.05),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // لون خلفية نصف شفاف بدل الضبابية المكلفة
              color: const Color(0xFF1E1E1E).withOpacity(0.7), 
              borderRadius: radius,
              border: Border.all(
                color: isGoldBorder
                    ? const Color(0xFFFFD700).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1), // حدود خفيفة
                width: isGoldBorder ? 1.5 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08), // لمعة خفيفة
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}