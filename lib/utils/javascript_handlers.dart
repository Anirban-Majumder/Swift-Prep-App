import 'dart:io';
import 'package:flutter/foundation.dart'; // Import this for kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:device_info_plus/device_info_plus.dart';

class JavaScriptHandlers {

  /// Setup share handler for web-to-native sharing
  static void setupShareHandler(
      InAppWebViewController controller,
      Function(String) onShare,
      ) {
    controller.addJavaScriptHandler(
      handlerName: 'shareHandler',
      callback: (args) {
        if (args.isNotEmpty) {
          final String textToShare = args[0].toString();
          onShare(textToShare);
        }
      },
    );
  }

  /// Setup device info handler
  static void setupDeviceInfoHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'getDeviceInfo',
      callback: (args) async {
        final deviceInfo = DeviceInfoPlugin();
        Map<String, dynamic> info = {};

        try {
          // Check for web platform first, as Platform.isAndroid/isIOS will crash on web.
          if (kIsWeb) {
            final webInfo = await deviceInfo.webBrowserInfo;
            info = {
              'platform': 'web',
              'browserName': webInfo.browserName.name,
              'appVersion': webInfo.appVersion,
              'userAgent': webInfo.userAgent,
            };
          } else if (Platform.isAndroid) {
            final androidInfo = await deviceInfo.androidInfo;
            info = {
              'platform': 'android',
              'model': androidInfo.model,
              'brand': androidInfo.brand,
              'version': androidInfo.version.release,
              'sdkInt': androidInfo.version.sdkInt,
            };
          } else if (Platform.isIOS) {
            final iosInfo = await deviceInfo.iosInfo;
            info = {
              'platform': 'ios',
              'model': iosInfo.model,
              'name': iosInfo.name,
              'version': iosInfo.systemVersion,
            };
          }
        } catch (e) {
          info = {'platform': 'unknown', 'error': e.toString()};
        }

        return info;
      },
    );
  }

  /// Setup navigation handler
  static void setupNavigationHandler(
      InAppWebViewController controller,
      Function(String) onNavigation,
      ) {
    controller.addJavaScriptHandler(
      handlerName: 'navigationHandler',
      callback: (args) {
        if (args.isNotEmpty) {
          final String action = args[0].toString();
          onNavigation(action);
        }
      },
    );
  }

  /// Setup haptic feedback handler
  static void setupHapticHandler(
      InAppWebViewController controller,
      VoidCallback onHaptic,
      ) {
    controller.addJavaScriptHandler(
      handlerName: 'hapticFeedback',
      callback: (args) {
        // You were already calling HapticFeedback.lightImpact() directly
        // in webview_screen.dart, which is simpler.
        // Let's keep the logic here for when you expand it.
        onHaptic();
      },
    );
  }
}