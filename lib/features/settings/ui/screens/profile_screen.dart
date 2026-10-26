import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/ad_service.dart';
import '../../../../core/translations/app_locale_keys.dart';
import '../../../../core/ui/widgets/glass_snackbar.dart';
import '../../../auth/data/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  String _t({required String ar, required String en}) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (!mounted || user == null) return;
    setState(() {
      _userData = user;
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImage = pickedFile;
      _selectedImageBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _userData == null) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.updateProfile(
        id: _userData!['id'].toString(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        imageFile: _selectedImage,
      );

      if (!mounted) return;
      showGlassSnackBar(context, AppLocaleKeys.profileUpdatedSuccess.tr);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        _t(
          ar: 'حدث خطأ أثناء حفظ البيانات',
          en: 'Failed to save profile data',
        ),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgTop = isDark ? const Color(0xFF081713) : const Color(0xFFF7FBF8);
    final bgBottom = isDark ? const Color(0xFF0D231D) : const Color(0xFFE7F2EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF17352E);
    final subColor =
        isDark ? Colors.white.withOpacity(0.68) : const Color(0xFF6A8479);
    final cardColor = isDark ? const Color(0xFF132D26) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFD9E9E0);
    final accent = const Color(0xFF2A8B68);
    final accentSoft = const Color(0xFF74D7C0);

    String? currentPhotoUrl = _userData?['image_url'];
    if (currentPhotoUrl != null && currentPhotoUrl.contains('localhost')) {
      currentPhotoUrl = currentPhotoUrl
          .replaceAll('localhost', 'mihrab-app.alwaysdata.net')
          .replaceAll('http://', 'https://');
    }

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
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: titleColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocaleKeys.profileTitle.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2C8A6A),
                                        Color(0xFF7AD1A8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentSoft.withOpacity(0.35),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor: cardColor,
                                    backgroundImage: _selectedImageBytes != null
                                        ? MemoryImage(_selectedImageBytes!)
                                        : (currentPhotoUrl != null &&
                                                currentPhotoUrl.isNotEmpty)
                                            ? NetworkImage(currentPhotoUrl)
                                                as ImageProvider
                                            : null,
                                    child: (_selectedImageBytes == null &&
                                            (currentPhotoUrl == null ||
                                                currentPhotoUrl.isEmpty))
                                        ? Icon(
                                            Icons.person_rounded,
                                            size: 56,
                                            color: accent,
                                          )
                                        : null,
                                  ),
                                ),
                                PositionedDirectional(
                                  bottom: 2,
                                  end: 2,
                                  child: InkWell(
                                    onTap: _pickImage,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _userData?['name'] ?? AppLocaleKeys.drawerUser.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _userData?['email'] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AdService.nativeAdWidget(),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _nameController,
                    label: AppLocaleKeys.nameLabel.tr,
                    icon: Icons.person_outline_rounded,
                    titleColor: titleColor,
                    subColor: subColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _phoneController,
                    label: AppLocaleKeys.phone.tr,
                    icon: Icons.phone_android_rounded,
                    titleColor: titleColor,
                    subColor: subColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller:
                        TextEditingController(text: _userData?['email'] ?? ''),
                    label: AppLocaleKeys.email.tr,
                    icon: Icons.email_outlined,
                    titleColor: titleColor,
                    subColor: subColor,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    enabled: false,
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F7A5E), Color(0xFF6DD1A4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isLoading ? null : _saveProfile,
                        child: SizedBox(
                          height: 58,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    AppLocaleKeys.saveChanges.tr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color titleColor,
    required Color subColor,
    required Color cardColor,
    required Color borderColor,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            textAlign: _isArabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              hintText: label,
              hintStyle: TextStyle(color: subColor),
              prefixIcon: Icon(icon, color: const Color(0xFF2C8A6A)),
            ),
            validator: enabled
                ? (value) => value == null || value.trim().isEmpty
                    ? AppLocaleKeys.requiredField.tr
                    : null
                : null,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
