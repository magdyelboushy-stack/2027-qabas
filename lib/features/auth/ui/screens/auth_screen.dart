import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../../../core/widgets/arabic_text_field.dart';
import '../../../home/ui/screens/home_screen.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static void navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => screen),
      (route) => false,
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true; // true = Login, false = Register
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // Form controls
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _phone = '';
  String _email = '';
  String _password = '';

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

  void _skipAuth() async {
    await AuthService.loginAsGuest();
    if (mounted) AuthScreen.navigateTo(context, const HomeScreen());
  }

  void _handleGoogleSignIn() async {
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.login(_email, _password);
      } else {
        await AuthService.register(
          "$_firstName $_lastName".trim(),
          _email,
          _password,
          _phone,
        );
      }
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
    final isArabic = Get.locale?.languageCode == 'ar';

    // Premium Colors derived from Theme
    final accentColor = isDark
        ? const Color(0xFFD4AF37) // ذهبي
        : const Color(0xFF00695C); // أخضر إسلامي
    final accentLight = isDark
        ? const Color(0xFFF5E6B8)
        : const Color(0xFF4DB6AC);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final mutedTextColor = isDark ? Colors.white60 : const Color(0xFF636E72);
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.85);
    final cardBorderColor = isDark
        ? accentColor.withOpacity(0.15)
        : accentColor.withOpacity(0.12);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by AuthBackground
      body: AuthBackground(
        child: SafeArea(
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      children: [
                        // Skip button on top left/right
                        Align(
                          alignment: isArabic ? Alignment.topLeft : Alignment.topRight,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isArabic
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                color: textColor,
                              ),
                              onPressed: _skipAuth,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Logo
                        _buildLogo(isDark, accentColor),

                        const SizedBox(height: 16),
                        Text(
                          AppLocaleKeys.authSubtitle.tr,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: mutedTextColor,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Toggle Switch (Segmented Control)
                        _buildToggleSwitch(isDark, accentColor, mutedTextColor),

                        const SizedBox(height: 30),

                        // Dynamic Form Card
                        _buildFormCard(
                          isDark: isDark,
                          accentColor: accentColor,
                          accentLight: accentLight,
                          textColor: textColor,
                          mutedTextColor: mutedTextColor,
                          cardColor: cardColor,
                          cardBorderColor: cardBorderColor,
                        ),

                        const SizedBox(height: 24),

                        // OR Divider
                        _buildDivider(isDark, accentColor, mutedTextColor),

                        const SizedBox(height: 24),

                        // Google Sign In
                        _buildGoogleButton(isDark, accentColor, textColor),

                        const SizedBox(height: 30),

                        // Bottom Switch Text
                        GestureDetector(
                          onTap: () => setState(() => _isLogin = !_isLogin),
                          child: RichText(
                            text: TextSpan(
                              text: _isLogin
                                  ? AppLocaleKeys.noAccount.tr
                                  : AppLocaleKeys.haveAccount.tr,
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: mutedTextColor,
                                  fontSize: 15),
                              children: [
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: _isLogin
                                      ? AppLocaleKeys.registerNow.tr
                                      : AppLocaleKeys.loginNow.tr,
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: accentColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
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
      ),
    );
  }

  // ==================== Logo ====================
  Widget _buildLogo(bool isDark, Color accent) {
    return Hero(
      tag: 'auth_logo',
      child: Container(
        width: 110,
        height: 110,
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(isDark ? 0.25 : 0.15),
                    accent.withOpacity(isDark ? 0.08 : 0.05),
                  ],
                ),
                border: Border.all(
                  color: accent.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.mosque_rounded,
                    size: 48,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Segmented Control ====================
  Widget _buildToggleSwitch(bool isDark, Color accentColor, Color mutedColor) {
    final bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: _isLogin ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: _isLogin
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  AppLocaleKeys.login.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: _isLogin ? Colors.white : mutedColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLogin = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: !_isLogin ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: !_isLogin
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  AppLocaleKeys.createAccount.tr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: !_isLogin ? Colors.white : mutedColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Form Card ====================
  Widget _buildFormCard({
    required bool isDark,
    required Color accentColor,
    required Color accentLight,
    required Color textColor,
    required Color mutedTextColor,
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
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_isLogin) ...[
                    // First Name
                    EnhancedArabicTextField(
                      labelText: AppLocaleKeys.firstName.tr,
                      prefixIcon: Icons.person_outline_rounded,
                      isDark: isDark,
                      onSaved: (v) => _firstName = v ?? '',
                      validator: (v) => v!.isEmpty ? AppLocaleKeys.requiredField.tr : null,
                    ),
                    const SizedBox(height: 16),
                    // Last Name
                    EnhancedArabicTextField(
                      labelText: AppLocaleKeys.lastName.tr,
                      prefixIcon: Icons.person_outline_rounded,
                      isDark: isDark,
                      onSaved: (v) => _lastName = v ?? '',
                      validator: (v) => v!.isEmpty ? AppLocaleKeys.requiredField.tr : null,
                    ),
                    const SizedBox(height: 16),
                    // Phone
                    EnhancedArabicTextField(
                      labelText: AppLocaleKeys.phone.tr,
                      prefixIcon: Icons.phone_android_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      allowEnglish: true,
                      onSaved: (v) => _phone = v ?? '',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return AppLocaleKeys.requiredField.tr;
                        if (v.trim().length < 10) return AppLocaleKeys.invalidPhone.tr;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  EnhancedArabicTextField(
                    labelText: AppLocaleKeys.email.tr,
                    prefixIcon: Icons.email_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    allowEnglish: true,
                    onSaved: (v) => _email = v ?? '',
                    validator: (v) => !v!.contains('@') ? AppLocaleKeys.invalidEmail.tr : null,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  EnhancedArabicTextField(
                    labelText: AppLocaleKeys.password.tr,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: true,
                    isDark: isDark,
                    allowEnglish: true,
                    onSaved: (v) => _password = v ?? '',
                    validator: (v) => v!.length < 6 ? AppLocaleKeys.shortPassword.tr : null,
                  ),
                  
                  if (_isLogin) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocaleKeys.forgotPassword.tr,
                            style: TextStyle(
                                fontFamily: 'Cairo',
                                color: mutedTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(AppLocaleKeys.rememberMe.tr,
                                style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: mutedTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v!),
                                activeColor: accentColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 28),

                  // Submit Button
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
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accentColor, accentLight],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _isLogin
                                  ? AppLocaleKeys.login.tr
                                  : AppLocaleKeys.createAccount.tr,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
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
                fontFamily: 'Cairo',
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
                  fontFamily: 'Cairo',
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
}
