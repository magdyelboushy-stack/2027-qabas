import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../../../core/widgets/arabic_text_field.dart';
import '../../../home/ui/screens/home_screen.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import 'auth_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  String get _genericAuthMessage => Get.locale?.languageCode == 'ar'
      ? AppLocaleKeys.errorTryAgain.tr
      : 'Something went wrong. Please try again.';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      await AuthService.login(_email, _password);
      if (mounted) AuthScreen.navigateTo(context, const HomeScreen());
    } catch (_) {
      if (mounted) {
        showGlassSnackBar(context, _genericAuthMessage, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) AuthScreen.navigateTo(context, const HomeScreen());
    } catch (_) {
      if (mounted) {
        showGlassSnackBar(context, _genericAuthMessage, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    // ألوان متناسقة مع الهوية الدينية
    final accentColor = isDark
        ? const Color(0xFFD4AF37)   // ذهبي
        : const Color(0xFF00695C);   // أخضر إسلامي
    final accentLight = isDark
        ? const Color(0xFFF5E6B8)
        : const Color(0xFF4DB6AC);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF636E72);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.85);
    final cardBorderColor = isDark
        ? accentColor.withOpacity(0.15)
        : accentColor.withOpacity(0.12);

    return Directionality(
      textDirection:
          Get.locale?.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: AuthBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      // ---- شعار التطبيق ----
                      _buildLogo(isDark, accentColor),

                      const SizedBox(height: 20),

                      // ---- اسم التطبيق ----
                      Text(
                        AppLocaleKeys.qabasAppName.tr,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 2,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ---- عنوان فرعي ----
                      Text(
                        AppLocaleKeys.authWelcomeBack.tr,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // ---- زر جوجل ----
                      _buildGoogleButton(isDark, accentColor, textColor),

                      const SizedBox(height: 24),

                      // ---- فاصل "أو" ----
                      _buildDivider(isDark, accentColor, subtitleColor),

                      const SizedBox(height: 24),

                      // ---- كارت النموذج ----
                      _buildFormCard(
                        isDark: isDark,
                        accentColor: accentColor,
                        accentLight: accentLight,
                        textColor: textColor,
                        cardColor: cardColor,
                        cardBorderColor: cardBorderColor,
                      ),

                      const SizedBox(height: 28),

                      // ---- رابط إنشاء حساب ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocaleKeys.noAccount.tr,
                            style: TextStyle(fontSize: 14, color: subtitleColor),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const RegisterScreen(),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 400),
                              ),
                            ),
                            child: Text(
                              AppLocaleKeys.createAccount.tr,
                              style: TextStyle(
                                fontSize: 14,
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: accentColor.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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

  // ==================== Logo ====================
  Widget _buildLogo(bool isDark, Color accent) {
    return Hero(
      tag: 'auth_logo',
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.mosque_rounded,
              size: 48,
              color: accent,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Google Button ====================
  Widget _buildGoogleButton(bool isDark, Color accent, Color textColor) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/google_icon.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.g_mobiledata_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocaleKeys.continueWithGoogle.tr,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Divider ====================
  Widget _buildDivider(bool isDark, Color accent, Color subtitleColor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: accent.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppLocaleKeys.or.tr,
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Form Card ====================
  Widget _buildFormCard({
    required bool isDark,
    required Color accentColor,
    required Color accentLight,
    required Color textColor,
    required Color cardColor,
    required Color cardBorderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // البريد الإلكتروني
                EnhancedArabicTextField(
                  labelText: AppLocaleKeys.email.tr,
                  prefixIcon: Icons.email_outlined,
                  isDark: isDark,
                  onSaved: (v) => _email = v!,
                  keyboardType: TextInputType.emailAddress,
                  allowEnglish: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppLocaleKeys.requiredField.tr;
                    if (!v.contains('@')) return AppLocaleKeys.invalidEmail.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // كلمة المرور
                EnhancedArabicTextField(
                  labelText: AppLocaleKeys.password.tr,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  isDark: isDark,
                  onSaved: (v) => _password = v!,
                  allowEnglish: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppLocaleKeys.requiredField.tr;
                    if (v.length < 6) return AppLocaleKeys.passwordMinLengthError.tr;
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // زر تسجيل الدخول
                _isLoading
                    ? SizedBox(
                        height: 54,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: accentColor,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocaleKeys.loginNow.tr,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
}
