class AppConstants {
  // Base URL for the web app
  static const String baseUrl = 'https://swift-prep.xyz';

  // App Information
  static const String appName = 'Swift Prep';
  static const String appVersion = '1.0.0';

  // Debug Mode
  static const bool isDebugMode = true; // Set to false for production

  // Timeout Settings
  static const int connectionTimeout = 30; // seconds
  static const int requestTimeout = 30; // seconds

  // Cache Settings
  static const int cacheMaxAge = 7; // days
  static const int offlineCacheMaxAge = 30; // days

  // Animation Durations
  static const int splashDuration = 2000; // milliseconds
  static const int pageTransitionDuration = 300; // milliseconds

  // Error Messages
  static const String noInternetError = 'No internet connection available';
  static const String serverError = 'Server error occurred';
  static const String timeoutError = 'Request timeout';
  static const String unknownError = 'An unknown error occurred';

  // JavaScript Bridge Event Names
  static const String shareEvent = 'shareHandler';
  static const String deviceInfoEvent = 'getDeviceInfo';
  static const String navigationEvent = 'navigationHandler';
  static const String hapticEvent = 'hapticFeedback';
  static const String clipboardEvent = 'copyToClipboard';
  static const String toastEvent = 'showToast';
  static const String statusBarEvent = 'setStatusBarStyle';

  // Permission Messages
  static const String cameraPermissionMessage = 'Camera access is required for this feature';
  static const String storagePermissionMessage = 'Storage access is required to save files';
  static const String locationPermissionMessage = 'Location access is required for this feature';
}