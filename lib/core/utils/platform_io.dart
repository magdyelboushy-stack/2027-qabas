import 'dart:io';

bool get isWebPlatform => false;
bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;
