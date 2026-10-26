import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mihrab/core/translations/app_locale_keys.dart';

import '../../../../core/services/ad_service.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../../../features/auth/ui/screens/register_screen.dart';
import '../../data/models/shaykh.dart';
import '../../logic/quran_view_controller.dart';
import 'mushaf_selection_screen.dart';
import 'widgets/quran_view_header_section.dart';
import 'widgets/quran_view_search_bar.dart';
import 'widgets/quran_view_sliver_app_bar.dart';
import 'widgets/recitation_card_with_favorite.dart';

class QuranViewScreen extends StatefulWidget {
  final Shaykh shaykh;
  final String? mushafId;
  final String? mushafName;

  const QuranViewScreen({
    super.key,
    required this.shaykh,
    this.mushafId,
    this.mushafName,
  });

  @override
  State<QuranViewScreen> createState() => _QuranViewScreenState();
}

class _QuranViewScreenState extends State<QuranViewScreen> {
  final QuranViewController _controller = QuranViewController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchRecitations();
    _controller.startStatusCheck(_safeSetState);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _safeSetState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchRecitations() async {
    await _controller.fetchRecitations(
      shaykh: widget.shaykh,
      mushafId: widget.mushafId,
    );
    if (!mounted) return;
    _safeSetState();

    final shaykhForSelection = _controller.buildMushafSelectionShaykh(
      shaykh: widget.shaykh,
      mushafId: widget.mushafId,
    );
    if (shaykhForSelection != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MushafSelectionScreen(shaykh: shaykhForSelection),
          ),
        );
      });
    }
  }

  void _onSearchChanged() {
    _controller.applySearch(_searchController.text);
    _safeSetState();
  }

  Future<void> _cancelBatchDownload() async {
    await _controller.cancelBatchDownload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocaleKeys.cancelingDownloads.tr),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _toggleBatchDownload() async {
    final isGuest = await AuthService.isGuest();
    if (isGuest) {
      if (mounted) _showGuestDialog();
      return;
    }
    await _showDownloadConfirmation();
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocaleKeys.guestAlertTitle.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocaleKeys.guestAlertMessage.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocaleKeys.commonCancel.tr, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocaleKeys.registerNow.tr,
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDownloadConfirmation() async {
    final hasInternet = await _controller.hasInternetConnection();
    if (!hasInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocaleKeys.noInternetConnection.tr),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final estimate = await _controller.buildDownloadEstimate(
      shaykh: widget.shaykh,
      mushafId: widget.mushafId,
    );
    if (estimate.toDownload == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocaleKeys.allSurahDownloaded.tr)),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            AppLocaleKeys.downloadConfirmation.tr,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppLocaleKeys.willDownloadSurah.tr} ${estimate.toDownload}'),
              const SizedBox(height: 8),
              Text(
                '${AppLocaleKeys.size.tr} ${estimate.isApproximate ? 'التقريبي' : ''}: ${estimate.formattedSize}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              if (estimate.isApproximate)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '(الحجم تقديري - قد يختلف قليلاً)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocaleKeys.commonCancel.tr, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFD4AF37)
                    : const Color(0xFFB8860B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                AppLocaleKeys.download.tr,
                style:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _controller.downloadAllRecitations(
        shaykh: widget.shaykh,
        onChanged: _safeSetState,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocaleKeys.startDownload.tr,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      );
    }
  }

  String get _currentMushafName => _controller.getCurrentMushafName(
        shaykh: widget.shaykh,
        mushafId: widget.mushafId,
        mushafName: widget.mushafName,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0A1F1B) : const Color(0xFFF5F5F5),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchRecitations,
            color: isDark
                ? const Color(0xFF79D8C4)
                : Theme.of(context).primaryColor,
            backgroundColor: isDark ? const Color(0xFF112824) : Colors.white,
            child: CustomScrollView(
              slivers: [
                QuranViewSliverAppBar(
                  shaykh: widget.shaykh,
                  isDark: isDark,
                  isBatchDownloading: _controller.isBatchDownloading,
                  onToggleBatchDownload: _controller.isBatchDownloading
                      ? _cancelBatchDownload
                      : _toggleBatchDownload,
                  mushafName: _currentMushafName,
                ),
                SliverToBoxAdapter(
                  child: QuranViewSearchBar(
                    isDark: isDark,
                    controller: _searchController,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AdService.nativeAdWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: QuranViewHeaderSection(
                    isDark: isDark,
                    isLoading: _controller.isLoading,
                    hasRecitations: _controller.recitations.isNotEmpty,
                    isBatchDownloading: _controller.isBatchDownloading,
                    downloadedCount: _controller.downloadedCount,
                    totalToDownload: _controller.totalToDownload,
                    mushafName: _currentMushafName,
                    onToggleBatchDownload: _controller.isBatchDownloading
                        ? _cancelBatchDownload
                        : _toggleBatchDownload,
                  ),
                ),
                _buildContent(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_controller.isLoading) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.cyanAccent : Colors.blue,
          ),
        ),
      );
    }
    if (_controller.error.isNotEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(isDark),
      );
    }
    if (_controller.recitations.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(isDark),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => RecitationCardWithFavorite(
            recitation: _controller.filteredRecitations[index],
            index: index,
            allRecitations: _controller.filteredRecitations,
            shaykh: widget.shaykh,
            isDark: isDark,
          ),
          childCount: _controller.filteredRecitations.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isSearchActive = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchActive ? Icons.search_off_rounded : Icons.mic_off_outlined,
            size: 80,
            color: isDark ? Colors.white38 : Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearchActive
                ? 'لا توجد نتائج بحث'
                : 'لا توجد تلاوات متاحة حالياً',
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 80,
            color: Colors.redAccent.withOpacity(isDark ? 1 : 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في الاتصال',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
            ),
          ),
          TextButton(
            onPressed: _fetchRecitations,
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(color: isDark ? Colors.cyanAccent : Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
