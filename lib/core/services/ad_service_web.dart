import 'package:flutter/material.dart';

class AdService {
  static Future<void> initialize() async {}

  static dynamic createBannerAd({
    dynamic adSize,
    Function? onLoaded,
    Function? onFailed,
  }) {
    throw UnimplementedError('Ads are disabled on web');
  }

  static Future<void> loadInterstitialAd() async {}

  static void showInterstitialAd() {}

  static Widget bannerAdWidget() => const SizedBox.shrink();

  static Widget nativeAdWidget({double height = 110}) =>
      const SizedBox.shrink();
}
