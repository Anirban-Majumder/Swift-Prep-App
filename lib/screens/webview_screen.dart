import 'dart:async';
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
    if (!mounted) return;
    setState(() {
      _hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        if (!mounted) return;
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
    // FIX: Using onPopInvokedWithResult to address the deprecation warning.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final controller = _webViewController;
        if (controller == null) return;

        final navigator = Navigator.of(context);

        if (await controller.canGoBack()) {
          await controller.goBack();
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: !_hasInternet
              ? NoInternetWidget(onRetry: _checkConnectivity)
              : Column(
            children: [
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF007AFF),
                  ),
                ),
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
                      cacheEnabled: true,
                      clearCache: false,
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      databaseEnabled: true,
                      supportZoom: false,
                      displayZoomControls: false,
                      builtInZoomControls: false,
                      verticalScrollBarEnabled: false,
                      horizontalScrollBarEnabled: false,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsPictureInPictureMediaPlayback: true,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      allowsBackForwardNavigationGestures: true,
                      allowsLinkPreview: false,
                      safeBrowsingEnabled: true,
                      useHybridComposition: true,
                      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      overScrollMode: OverScrollMode.NEVER,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _setupJavaScriptHandlers(controller);
                    },
                    onLoadStart: (controller, url) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = true;
                      });
                    },
                    onLoadStop: (controller, url) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = false;
                      });
                      FlutterNativeSplash.remove();
                      _injectCustomCSS(controller);
                    },
                    onProgressChanged: (controller, progress) {
                      if (!mounted) return;
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onReceivedError: (controller, request, error) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = false;
                      });
                      FlutterNativeSplash.remove();
                      print("WebView Error: ${error.description} for url ${request.url}");
                      _showErrorSnackBar('Failed to load page. Please try again.');
                    },
                    onReceivedHttpError: (controller, request, errorResponse) {
                      if (!mounted) return;
                      setState(() {
                        _isLoading = false;
                      });
                      FlutterNativeSplash.remove();
                      print("HTTP Error: ${errorResponse.statusCode} for url ${request.url}");
                      if (errorResponse.statusCode == 404) {
                        _showErrorSnackBar('Page not found (Error 404)');
                      } else {
                        _showErrorSnackBar('Error loading page: Code ${errorResponse.statusCode}');
                      }
                    },
                    shouldOverrideUrlLoading: (controller, navigationAction) async {
                      final url = navigationAction.request.url.toString();
                      if (_shouldOpenExternally(url)) {
                        await _launchExternalUrl(url);
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                    onConsoleMessage: (controller, consoleMessage) {
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
      ),
    );
  }

  void _setupJavaScriptHandlers(InAppWebViewController controller) {
    JavaScriptHandlers.setupShareHandler(controller, (text) {
      Share.share(text);
    });
    JavaScriptHandlers.setupDeviceInfoHandler(controller);
    JavaScriptHandlers.setupNavigationHandler(controller, (action) {
      _handleNavigation(action);
    });
    JavaScriptHandlers.setupHapticHandler(controller, () {
      HapticFeedback.lightImpact();
    });
  }

  void _injectCustomCSS(InAppWebViewController controller) {
    const String customCSS = '''
      (function() {
        var style = document.createElement('style');
        style.textContent = `
          body {
            -webkit-user-select: none;
            -ms-user-select: none;
            user-select: none;
            -webkit-touch-callout: none;
            -webkit-tap-highlight-color: transparent;
          }
          ::-webkit-scrollbar { display: none; }
          html { scroll-behavior: smooth; }
          body, * { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, "Fira Sans", "Droid Sans", "Helvetica Neue", sans-serif !important; }
          @media (pointer: coarse) { * { outline: none !important; } }
          input, textarea, select { font-size: 16px !important; }
        `;
        document.head.appendChild(style);
      })();
    ''';
    controller.evaluateJavascript(source: customCSS);
  }

  bool _shouldOpenExternally(String url) {
    final externalPatterns = [
      'mailto:', 'tel:', 'sms:', 'whatsapp:',
      'facebook.com', 'twitter.com', 'instagram.com', 'youtube.com',
      'play.google.com', 'apps.apple.com',
    ];
    if (url.startsWith(AppConstants.baseUrl)) {
      return false;
    }
    return externalPatterns.any((pattern) => url.contains(pattern));
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}