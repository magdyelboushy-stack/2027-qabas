import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/translations/app_locale_keys.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  List<dynamic> _names = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/json/Names_Of_Allah.json');
      final List<dynamic> data = json.decode(jsonString);
      if (mounted) {
        setState(() {
          _names = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading names of Allah: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNameDetail(BuildContext context, Map<String, dynamic> nameData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF0D1B2A).withOpacity(0.85) 
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(
              color: isDark 
                  ? const Color(0xFFFFD700).withOpacity(0.2) 
                  : const Color(0xFF8B6B00).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 40),
              
              // Calligraphic Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/images/surah_banner_golden.png'),
                    opacity: 0.1,
                    fit: BoxFit.contain,
                  ),
                ),
                child: Text(
                  nameData['name'],
                  style: TextStyle(
                    fontFamily: 'UthmanTN',
                    fontSize: 64,
                    fontWeight: FontWeight.normal,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B00),
                    shadows: [
                      Shadow(
                        color: (isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B00)).withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Meaning Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3EFE9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B00)).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B00), size: 24),
                    const SizedBox(height: 16),
                    Text(
                      nameData['text'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        height: 1.6,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Share/Action Button (Optional but premium feel)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('إغلاق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFFFFD700) : const Color(0xFF8B6B00),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgGradient = isDark 
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF030E12), Color(0xFF0D1B2A), Color(0xFF1B3A2D)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFBF7), Color(0xFFEFE6D5)],
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. & 2. Background (Optimized with RepaintBoundary)
          RepaintBoundary(
            child: Stack(
              children: [
                Container(decoration: BoxDecoration(gradient: bgGradient)),
                Opacity(
                  opacity: isDark ? 0.05 : 0.03,
                  child: Image.asset(
                    'assets/images/surah_banner_golden.png',
                    repeat: ImageRepeat.repeat,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.none,
                    scale: 0.5,
                    cacheWidth: 200, // Optimize memory for repeated texture
                  ),
                ),
              ],
            ),
          ),
          
          // 3. Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 20),
                  title: Text(
                    AppLocaleKeys.namesOfAllahTitle.tr,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFFFD700) : const Color(0xFF3E2723), // Better contrast for light mode
                      shadows: [
                        if (isDark)
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                  ),
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.mosque_outlined,
                        size: 140,
                        color: (isDark ? const Color(0xFFFFD700) : const Color(0xFF9E7700)).withOpacity(0.08),
                      ),
                      Positioned(
                        bottom: 60,
                        child: Text(
                          AppLocaleKeys.namesOfAllahDesc.tr,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: (isDark ? Colors.white60 : Colors.black45),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, size: 18, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
              
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final name = _names[index];
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 400 + (index % 10 * 50)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: _NameCard(
                            name: name['name'],
                            index: index + 1,
                            onTap: () => _showNameDetail(context, name),
                          ),
                        );
                      },
                      childCount: _names.length,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final String name;
  final int index;
  final VoidCallback onTap;

  const _NameCard({
    required this.name,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gold = const Color(0xFFFFD700);
    final screenWidth = MediaQuery.of(context).size.width;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark 
                ? gold.withOpacity(0.2) 
                : const Color(0xFF8B6B00).withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Index Badge
            Positioned(
              top: 10,
              right: 12,
              child: Text(
                '#$index',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? gold.withOpacity(0.5) : const Color(0xFF8B6B00).withOpacity(0.6),
                ),
              ),
            ),
            
            // Name Text
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanTN',
                    fontSize: screenWidth * 0.065, // Responsive Font Size
                    height: 1.2,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                    shadows: [
                      if (isDark)
                        Shadow(
                          color: gold.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Subtle corner ornament
            Positioned(
              bottom: 8,
              left: 10,
              child: Icon(
                Icons.brightness_low_outlined,
                size: 14,
                color: gold.withOpacity(isDark ? 0.1 : 0.2),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
