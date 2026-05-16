import 'dart:io';

/// Application environment configuration.
///
/// Supports dev, staging, and prod environments with appropriate server URLs.
/// Configuration can be overridden via environment variables:
/// - VSL_SERVER_URL: Override server host
/// - VSL_SERVER_PORT: Override server port
/// - VSL_ENV: Environment (dev, staging, prod)
class AppConfig {
  /// Current application environment
  final String environment;

  /// Recognition service server host
  final String serverUrl;

  /// Recognition service server port
  final int serverPort;

  /// Whether to use mock MediaPipe (for testing without real model)
  final bool useMockMediaPipe;

  /// Whether to use full MediaPipe Holistic (pose + hands) vs hands-only
  /// When true: extracts 75 landmarks (33 pose + 21 left + 21 right) = 225 features
  /// When false: extracts only hand landmarks (42 landmarks) = 126 features
  final bool useHolistic;

  /// Target FPS for landmark detection
  final int targetFps;

  /// Max number of hands to detect
  final int maxNumHands;

  /// Confidence threshold for hand detection
  final double minDetectionConfidence;

  /// LiveKit WebSocket server URL for video calling.
  /// Dev default matches docker-compose LiveKit port (7881 mapped to ws).
  final String liveKitUrl;

  /// Private constructor
  AppConfig._internal({
    required this.environment,
    required this.serverUrl,
    required this.serverPort,
    this.useMockMediaPipe = false,
    this.useHolistic = true,
    this.targetFps = 15,
    this.maxNumHands = 2,
    this.minDetectionConfidence = 0.5,
    required this.liveKitUrl,
  });

  /// Create configuration directly (useful for testing)
  factory AppConfig.create({
    required String environment,
    required String serverUrl,
    required int serverPort,
    bool useMockMediaPipe = false,
    bool useHolistic = true,
    int targetFps = 15,
    int maxNumHands = 2,
    double minDetectionConfidence = 0.5,
    required String liveKitUrl,
  }) {
    return AppConfig._internal(
      environment: environment,
      serverUrl: serverUrl,
      serverPort: serverPort,
      useMockMediaPipe: useMockMediaPipe,
      useHolistic: useHolistic,
      targetFps: targetFps,
      maxNumHands: maxNumHands,
      minDetectionConfidence: minDetectionConfidence,
      liveKitUrl: liveKitUrl,
    );
  }

  /// Load configuration from environment or defaults.
  ///
  /// Priority (highest to lowest):
  /// 1. Environment variables
  /// 2. Environment-specific defaults
  /// 3. Development defaults
  factory AppConfig.load() {
    // Read environment overrides
    final env =
        Platform.environment['VSL_ENV'] ??
        Platform.environment['FLUTTER_APP_ENV'] ??
        'dev';

    final urlOverride =
        Platform.environment['VSL_SERVER_URL'] ??
        Platform.environment['SERVER_URL'];

    final portOverride =
        Platform.environment['VSL_SERVER_PORT'] ??
        Platform.environment['SERVER_PORT'];

    final portInt = portOverride != null ? int.tryParse(portOverride) : null;

    final useMock = Platform.environment['VSL_USE_MOCK'] == 'true';
    final useHolistic = Platform.environment['VSL_USE_HOLISTIC'] != 'false';
    final liveKitUrlOverride = Platform.environment['VSL_LIVEKIT_URL'];

    // Environment-specific defaults
    String defaultUrl;
    int defaultPort;
    String defaultLiveKitUrl;

    switch (env.toLowerCase()) {
      case 'prod':
      case 'production':
        defaultUrl = 'api.vsl-bridge.com';
        defaultPort = 443;
        defaultLiveKitUrl = liveKitUrlOverride ?? 'wss://livekit.vsl-bridge.com';
        break;
      case 'staging':
        defaultUrl = 'staging-api.vsl-bridge.com';
        defaultPort = 443;
        defaultLiveKitUrl = liveKitUrlOverride ?? 'wss://staging-livekit.vsl-bridge.com';
        break;
      case 'dev':
      default:
        // For Android emulator, use special IP 10.0.2.2 to reach host localhost
        // For iOS simulator, use localhost (127.0.0.1)
        // For physical device, use the host's LAN IP
        defaultUrl = urlOverride ?? '10.0.2.2';
        defaultPort = portInt ?? 8000;
        // Dev: ws:// to match docker-compose LiveKit WebSocket port
        defaultLiveKitUrl = liveKitUrlOverride ?? 'ws://${urlOverride ?? '10.0.2.2'}:7880';
        break;
    }

    return AppConfig._internal(
      environment: env,
      serverUrl: urlOverride ?? defaultUrl,
      serverPort: portInt ?? defaultPort,
      useMockMediaPipe: useMock,
      useHolistic: useHolistic,
      liveKitUrl: defaultLiveKitUrl,
    );
  }

  /// Get WebSocket URL for Socket.io connection
  String get websocketUrl {
    if (serverPort == 443) {
      return 'wss://$serverUrl';
    }
    return 'ws://$serverUrl:$serverPort';
  }

  /// Get HTTP URL for REST API calls
  String get httpUrl {
    if (serverPort == 443) {
      return 'https://$serverUrl';
    }
    return 'http://$serverUrl:$serverPort';
  }

  @override
  String toString() {
    return 'AppConfig(environment: $environment, serverUrl: $serverUrl, serverPort: $serverPort, liveKitUrl: $liveKitUrl, useMockMediaPipe: $useMockMediaPipe, useHolistic: $useHolistic)';
  }
}
