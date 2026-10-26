import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'platform.dart';

class DesktopUtils {
  static bool get isWeb => kIsWeb || isWebPlatform;

  static bool get isDesktop {
    if (isWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isMobile {
    if (isWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Returns a constrained width for desktop layouts to prevent stretching.
  /// On mobile, it returns double.infinity (full width).
  static double get maxContentWidth => 1200.0;

  /// Wraps the child in a Center and ConstrainedBox for desktop friendliness.
  static Widget createResponsiveContainer(
      {required Widget child, double? maxWidth}) {
    if (!isDesktop) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? maxContentWidth),
        child: child,
      ),
    );
  }
}
