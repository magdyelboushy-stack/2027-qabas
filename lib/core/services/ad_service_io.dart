import 'package:flutter/material.dart';

// Conditional import: only import google_mobile_ads on mobile
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob service.
/// Manages initialization, banner ads, and interstitial ads.
class AdService {
  // ─── Ad Unit IDs ───
  static String get _nativeAdUnitId =>
      'ca-app-pub-2459293628199607/2559511150'; // Production Native Advanced

  // ─── Initialization ───
  static Future<void> initialize() async {
    // Ads completely disabled across the app by user request
    return;
  }

  // ─── Banner Ad ───
  static BannerAd createBannerAd({
    AdSize adSize = AdSize.banner,
    Function? onLoaded,
    Function? onFailed,
  }) {
    // Disabled
    throw UnimplementedError("Ads are disabled");
  }

  // ─── Interstitial Ad ───
  static Future<void> loadInterstitialAd() async {
    // Disabled
  }

  static void showInterstitialAd() {
    // Disabled
  }

  // ─── Banner Widget ───
  static Widget bannerAdWidget() {
    return const SizedBox.shrink(); // Disabled
  }

  // ─── Native Widget ───
  static Widget nativeAdWidget({double height = 110}) {
    return const SizedBox.shrink(); // Disabled
  }
}

/// Stateful widget that manages a NativeAd lifecycle.
class _NativeAdWidget extends StatefulWidget {
  final double height;
  const _NativeAdWidget({required this.height});

  @override
  State<_NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<_NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _nativeAd = NativeAd(
      adUnitId: AdService._nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Native Ad loaded');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Native Ad failed: ${error.message}');
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

/// Stateful widget that manages a BannerAd lifecycle.
class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = AdService.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isAdLoaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isAdLoaded = false);
      },
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // Invisible until loaded
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
