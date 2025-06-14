import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/no_internet_widget.dart';
import '../utils/constants.dart';
import '../utils/javascript_handlers.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasInternet = true;
  double _progress = 0.0;
  String _currentUrl = AppConstants.baseUrl;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        setState(() {
          _hasInternet = result != ConnectivityResult.none;
        });

        if (_hasInternet && _webViewController != null) {
          _webViewController!.reload();
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: !_hasInternet
            ? NoInternetWidget(onRetry: _checkConnectivity)
            : Column(
          children: [
            // Progress Bar
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF007AFF),
                ),
              ),

            // WebView
            Expanded(
              child: NotificationListener<OverscrollIndicatorNotification>(
                onNotification: (overscroll) {
                  overscroll.disallowIndicator();
                  return true;
                },
                child: InAppWebView(
                  key: _webViewKey,
                  initialUrlRequest: URLRequest(
                    url: WebUri(AppConstants.baseUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    // Performance Settings
                    cacheEnabled: true,
                    clearCache: false,
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    databaseEnabled: true,

                    // UI Settings
                    supportZoom: false,
                    displayZoomControls: false,
                    builtInZoomControls: false,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,

                    // Security Settings
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsPictureInPictureMediaPlayback: true,

                    // Mobile Specific
                    useWideViewPort: true,
                    loadWithOverviewMode: true,

                    // iOS Specific
                    allowsBackForwardNavigationGestures: true,
                    allowsLinkPreview: false,

                    // Android Specific
                    safeBrowsingEnabled: true,
                    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

                    // Disable overscroll glow
                    overScrollMode: OverScrollMode.OVER_SCROLL_NEVER,
                  ),

                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _setupJavaScriptHandlers(controller);
                  },

                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _currentUrl = url.toString();
                    });
                  },

                  onLoadStop: (controller, url) {
                    setState(() {
                      _isLoading = false;
                    });

                    // Remove splash screen when WebView loads
                    FlutterNativeSplash.remove();

                    // Inject custom CSS for seamless experience
                    _injectCustomCSS(controller);
                  },

                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },

                  onReceivedError: (controller, request, error) {
                    // Handle errors gracefully
                    _showErrorSnackBar('Failed to load page');
                  },

                  onReceivedHttpError: (controller, request, errorResponse) {
                    if (errorResponse.statusCode == 404) {
                      _showErrorSnackBar('Page not found');
                    }
                  },

                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url.toString();

                    // Handle external URLs
                    if (_shouldOpenExternally(url)) {
                      await _launchExternalUrl(url);
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },

                  onConsoleMessage: (controller, consoleMessage) {
                    // Log console messages for debugging
                    if (AppConstants.isDebugMode) {
                      print('Console: ${consoleMessage.message}');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    // Share Handler
    JavaScriptHandlers.setupShareHandler(controller, (text) {
      Share.share(text);
    });

    // Device Info Handler
    JavaScriptHandlers.setupDeviceInfoHandler(controller);

    // Navigation Handler
    JavaScriptHandlers.setupNavigationHandler(controller, (action) {
      _handleNavigation(action);
    });

    // Haptic Feedback Handler
    JavaScriptHandlers.setupHapticHandler(controller, () {
      HapticFeedback.lightImpact();
    });
  }

  void _injectCustomCSS(InAppWebViewController controller) {
    const String customCSS = '''
      (function() {
        var style = document.createElement('style');
        style.textContent = `
          /* Disable text selection */
          body {
            -webkit-user-select: none;
            -ms-user-select: none;
            user-select: none;
            -webkit-touch-callout: none;
            -webkit-tap-highlight-color: transparent;
          }
          
          /* Hide scrollbars */
          ::-webkit-scrollbar {
            display: none;
          }
          
          /* Smooth scrolling */
          html {
            scroll-behavior: smooth;
          }
          
          /* Native font stack */
          body, * {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, 
                         Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", 
                         "Helvetica Neue", sans-serif !important;
          }
          
          /* Remove focus outlines on touch devices */
          @media (pointer: coarse) {
            * {
              outline: none !important;
            }
          }
          
          /* Disable zoom on input focus */
          input, textarea, select {
            font-size: 16px !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''';

    controller.evaluateJavascript(source: customCSS);
  }

  bool _shouldOpenExternally(String url) {
    // Define patterns for external URLs
    final externalPatterns = [
      'mailto:',
      'tel:',
      'sms:',
      'whatsapp:',
      'facebook.com',
      'twitter.com',
      'instagram.com',
      'youtube.com',
      'play.google.com',
      'apps.apple.com',
    ];

    return externalPatterns.any((pattern) => url.contains(pattern));
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showErrorSnackBar('Could not open link');
    }
  }

  void _handleNavigation(String action) {
    switch (action) {
      case 'back':
        _webViewController?.goBack();
        break;
      case 'forward':
        _webViewController?.goForward();
        break;
      case 'refresh':
        _webViewController?.reload();
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}