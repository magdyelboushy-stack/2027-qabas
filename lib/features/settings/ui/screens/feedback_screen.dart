import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/api_endpoints.dart';
import '../../../../core/translations/app_locale_keys.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.contactSend),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'message': _feedbackController.text.trim(),
        }),
      );

      if (!mounted) return;

      final success = response.statusCode == 200 || response.statusCode == 201;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              success ? const Color(0xFF1B5E49) : const Color(0xFF8B2E2E),
          content: Text(
            success
                ? AppLocaleKeys.messageSentSuccess.tr
                : AppLocaleKeys.messageSendError.tr,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
      );

      if (success) {
        _nameController.clear();
        _phoneController.clear();
        _feedbackController.clear();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF8B2E2E),
          content: Text(
            AppLocaleKeys.connectionError.tr,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse('https://www.facebook.com/Qabas.App.Official/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF122A24) : Colors.white;
    final border =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD9E9E0);
    final textColor = isDark ? Colors.white : const Color(0xFF18352D);
    final subTextColor =
        isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF6A8479);
    final accent = const Color(0xFF1E6A55);
    final accentSoft = const Color(0xFF66C29C);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF081713) : const Color(0xFFF3F8F4),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [Color(0xFF0A1E1A), Color(0xFF081713)]
                  : const [Color(0xFFF7FBF8), Color(0xFFE7F2EC)],
            ),
          ),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          _isArabic
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: textColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocaleKeys.feedbackTitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF17342D),
                                const Color(0xFF0E221D),
                              ]
                            : [
                                Colors.white,
                                const Color(0xFFF1F8F3),
                              ],
                      ),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2C8A6A), Color(0xFF7AD1A8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentSoft.withOpacity(0.32),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.rate_review_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          AppLocaleKeys.feedbackSubtitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 15,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _buildField(
                    controller: _nameController,
                    label: AppLocaleKeys.nameLabel.tr,
                    icon: Icons.person_outline_rounded,
                    textColor: textColor,
                    border: border,
                    surface: surface,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppLocaleKeys.pleaseEnterName.tr
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _phoneController,
                    label: AppLocaleKeys.phoneOptional.tr,
                    icon: Icons.phone_android_rounded,
                    textColor: textColor,
                    border: border,
                    surface: surface,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _feedbackController,
                    label: AppLocaleKeys.feedbackPlaceholder.tr,
                    icon: Icons.edit_note_rounded,
                    textColor: textColor,
                    border: border,
                    surface: surface,
                    maxLines: 6,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppLocaleKeys.pleaseEnterFeedback.tr
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: _isSubmitting
                        ? AppLocaleKeys.sendingMessage.tr
                        : AppLocaleKeys.sendMessage.tr,
                    icon: FontAwesomeIcons.paperPlane,
                    onTap: _isSubmitting ? null : _submitFeedback,
                    colors: const [Color(0xFF1F7A5E), Color(0xFF6DD1A4)],
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 14),
                  _buildPrimaryButton(
                    label: AppLocaleKeys.contactFacebook.tr,
                    icon: FontAwesomeIcons.facebookF,
                    onTap: _openFacebook,
                    colors: const [Color(0xFF1C8C68), Color(0xFF2E6AF0)],
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required Color border,
    required Color surface,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              hintText: label,
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.48),
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF2C8A6A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required List<Color> colors,
    required Color textColor,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }
}
