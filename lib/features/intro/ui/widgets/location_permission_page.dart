import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:get/get.dart';
import '../../../../core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/location_service.dart';
import '../../manual_location_screen.dart';
import '../../../../core/translations/app_locale_keys.dart';

class LocationPermissionPage extends StatefulWidget {
  final VoidCallback onNext;
  final double pageOffset;
  final Animation<double> floatAnimation;

  const LocationPermissionPage({
    super.key,
    required this.onNext,
    required this.pageOffset,
    required this.floatAnimation,
  });

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage>
    with TickerProviderStateMixin {
  bool _isLocating = false;
  bool _locationSet = false;
  String _locationMessage = "";

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnimation =
        CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final shouldProceed = await _showLocationDisclosureDialog();
    if (!shouldProceed) {
      setState(() {
        _locationMessage = AppLocaleKeys.grantPermissionLater.tr;
      });
      return;
    }

    setState(() {
      _isLocating = true;
      _locationMessage = AppLocaleKeys.connectingSatellites.tr;
    });

    try {
      final loc = await LocationService.getAndSaveLocation();

      if (loc != null) {
        setState(() {
          _locationSet = true;
          _locationMessage = AppLocaleKeys.locationDeterminedAccurately.tr;
        });
        _successController.forward();

        Future.delayed(const Duration(milliseconds: 1500), widget.onNext);
      } else {
        setState(() {
          _locationMessage = AppLocaleKeys.unableToDetermineLocation.tr;
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = "${"حدث خطأ".tr}: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<bool> _showLocationDisclosureDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E241E) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on,
                  color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocaleKeys.locationPermissionTitle.tr,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يجمع تطبيق "قبس" بيانات الموقع لتمكين الميزات التالية بشكل دقيق للصائم والمصلي:'
                    .tr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildSimpleDisclosureItem(
                icon: Icons.access_time_filled,
                text: 'حساب مواقيت الصلاة الدقيقة لمنطقتك.'.tr,
                color: Colors.cyan,
              ),
              const SizedBox(height: 12),
              _buildSimpleDisclosureItem(
                icon: Icons.explore,
                text: 'تحديد اتجاه القبلة بدقة لحظية.'.tr,
                color: Colors.amber,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12)),
                child: Text(
                  'يتم جمع هذه البيانات حتى عندما يكون التطبيق مغلقاً أو غير قيد الاستخدام لضمان دقة منبه الأذان.\nلن يتم مشاركة موقعك مع أي جهة خارجية.'
                      .tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'ليس الآن'.tr,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'استمرار'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildSimpleDisclosureItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Stack(
      children: [
        Positioned.fill(
          bottom: 90,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Premium Glowing Header Icon
                AnimatedBuilder(
                  animation: widget.floatAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, widget.floatAnimation.value * 1.5),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner Glow
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Glass Orb
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 50,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // Title
                Text(
                  AppLocaleKeys.determineYourLocation.tr.tr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "للحصول على مواقيت صلاة دقيقة جداً واتجاه القبلة الصحيح أينما كنت."
                      .tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Status Box OR Actions
                if (_locationSet)
                  // ✨ Premium Success State
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocaleKeys.locationSetSuccessEx.tr.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locationMessage,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Label if Error / Locating
                      if (_locationMessage.isNotEmpty && !_isLocating)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            _locationMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ),

                      // Premium Action Button
                      GestureDetector(
                        onTap: _isLocating ? null : _determinePosition,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFFD4AF37),
                                      const Color(0xFFB8860B)
                                    ]
                                  : [
                                      const Color(0xFFD4AF37),
                                      const Color(0xFF996515)
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLocating
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 3),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.my_location_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        AppLocaleKeys.accurateAutoDetection.tr.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Secondary Buttons (Manual & Skip) Glassmorphic
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _isLocating
                                  ? null
                                  : () {
                                      Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ManualLocationScreen()))
                                          .then((result) {
                                        if (result != null) {
                                          setState(() {
                                            _locationSet = true;
                                            _locationMessage =
                                                AppLocaleKeys.setManuallyDone.tr.tr;
                                          });
                                          _successController.forward();
                                          Future.delayed(
                                              const Duration(
                                                  milliseconds: 1500),
                                              widget.onNext);
                                        }
                                      });
                                    },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.05),
                              ),
                              icon: Icon(Icons.map_outlined,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  size: 20),
                              label: Text(AppLocaleKeys.manualSearchBtn.tr.tr,
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: _isLocating
                                ? null
                                : () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setBool(
                                        'location_skipped', true);
                                    widget.onNext();
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(AppLocaleKeys.skipBtnText.tr.tr,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
