import 'dart:io';
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
          if (Platform.isAndroid) {
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
          info = {'platform': 'unknown'};
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
        String type = 'light';
        if (args.isNotEmpty) {
          type = args[0].toString();
        }

        switch (type) {
          case 'light':
            HapticFeedback.lightImpact();
            break;
          case 'medium':
            HapticFeedback.mediumImpact();
            break;
          case 'heavy':
            HapticFeedback.heavyImpact();
            break;
          case 'selection':
            HapticFeedback.selectionClick();
            break;
          default:
            HapticFeedback.lightImpact();
        }
      },
    );
  }

  /// Setup clipboard handler
  static void setupClipboardHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'copyToClipboard',
      callback: (args) {
        if (args.isNotEmpty) {
          final String text = args[0].toString();
          Clipboard.setData(ClipboardData(text: text));
        }
      },
    );
  }

  /// Setup toast/snackbar handler
  static void setupToastHandler(
      InAppWebViewController controller,
      Function(String, String) onShowToast,
      ) {
    controller.addJavaScriptHandler(
      handlerName: 'showToast',
      callback: (args) {
        if (args.length >= 2) {
          final String message = args[0].toString();
          final String type = args[1].toString(); // 'success', 'error', 'info'
          onShowToast(message, type);
        }
      },
    );
  }

  /// Setup status bar handler
  static void setupStatusBarHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'setStatusBarStyle',
      callback: (args) {
        if (args.isNotEmpty) {
          final String style = args[0].toString();

          SystemUiOverlayStyle overlayStyle;
          switch (style) {
            case 'light':
              overlayStyle = SystemUiOverlayStyle.light;
              break;
            case 'dark':
              overlayStyle = SystemUiOverlayStyle.dark;
              break;
            default:
              overlayStyle = const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              );
          }

          SystemChrome.setSystemUIOverlayStyle(overlayStyle);
        }
      },
    );
  }
}