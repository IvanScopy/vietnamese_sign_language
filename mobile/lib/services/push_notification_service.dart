import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Injectable routing seam — allows testing notification routing without
/// a real Navigator or Firebase runtime.
typedef NotificationRouter = void Function(
    String route, Map<String, dynamic>? arguments);

/// Service for Firebase Cloud Messaging push notifications.
///
/// Handles:
/// - Firebase initialization
/// - FCM token registration with backend
/// - Notification-open routing to incoming call screen (VIDEO_CALL)
/// - Notification-open routing to SOS status view (SOS)
///
/// Gracefully handles missing Firebase config: logs warning and continues.
/// Foreground Socket.io signaling still works without FCM.
///
/// [onNotificationRoute] is an injectable seam for testing routing without
/// Firebase or a real Navigator.
class PushNotificationService {
  final String baseUrl;
  final String? authToken;

  /// Optional override for notification routing — used in tests.
  /// When null, the default Navigator-based routing is used.
  final NotificationRouter? onNotificationRoute;

  FirebaseMessaging? _messaging;
  String? _fcmToken;

  PushNotificationService({
    required this.baseUrl,
    this.authToken,
    this.onNotificationRoute,
  });

  /// Initialize Firebase and set up notification handlers.
  ///
  /// [navigatorKey] - GlobalKey used for navigation when notification is opened.
  /// If Firebase is not configured, logs a warning and returns gracefully.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      // Initialize Firebase (may throw if google-services.json is missing)
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint(
        '[PushNotification] Firebase not configured — push notifications disabled. '
        'Foreground Socket.io signaling still works. Error: $e',
      );
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      _fcmToken = await _messaging!.getToken();
      debugPrint('[PushNotification] FCM token: ${_fcmToken?.substring(0, 20)}...');

      // Register token with backend
      if (_fcmToken != null && authToken != null) {
        await _registerTokenWithBackend(_fcmToken!);
      }

      // Handle notification when app is opened from terminated state
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(initialMessage, navigatorKey);
      }

      // Handle notification when app is in background and user taps it
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationOpen(message, navigatorKey);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[PushNotification] Foreground message: ${message.notification?.title}');
      });

      // Handle token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        debugPrint('[PushNotification] Token refreshed');
        _fcmToken = newToken;
        if (authToken != null) {
          _registerTokenWithBackend(newToken);
        }
      });
    } catch (e) {
      debugPrint('[PushNotification] FCM initialization error: $e');
    }
  }

  /// Get the current FCM token.
  Future<String?> getToken() async {
    if (_fcmToken != null) return _fcmToken;
    if (_messaging == null) return null;
    _fcmToken = await _messaging!.getToken();
    return _fcmToken;
  }

  /// Register FCM token with the backend.
  /// POST /api/notifications/register-token
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/register-token');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[PushNotification] Token registered with backend');
      } else {
        debugPrint(
          '[PushNotification] Token registration failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[PushNotification] Token registration error: $e');
    }
  }

  /// Handle notification open — delegate to [_routeNotificationData].
  void _handleNotificationOpen(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    _routeNotificationData(message.data, navigatorKey);
  }

  /// Route by notification data map.
  ///
  /// Supported types:
  /// - `VIDEO_CALL` → `/calls/incoming` with callId, fromUserId, fromUserName
  /// - `SOS` → `/sos` with alertId, fromUserName, status, locationLabel
  ///
  /// Unknown types are ignored (logged only).
  void _routeNotificationData(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    final type = data['type'] as String?;

    if (type == 'VIDEO_CALL') {
      debugPrint('[PushNotification] VIDEO_CALL notification opened');
      _navigate(
        route: '/calls/incoming',
        arguments: {
          'callId': data['callId'],
          'fromUserId': data['fromUserId'],
          'fromUserName': data['fromUserName'],
        },
        navigatorKey: navigatorKey,
      );
      return;
    }

    if (type == 'SOS') {
      debugPrint('[PushNotification] SOS notification opened');
      // SOS foreground notification — log stable status (no flashing per D-16).
      // Route to /sos with alert context so the screen shows status information.
      _navigate(
        route: '/sos',
        arguments: {
          'alertId': data['alertId'],
          'fromUserName': data['fromUserName'],
          'status': data['status'],
          'locationLabel': data['locationLabel'],
        },
        navigatorKey: navigatorKey,
      );
      return;
    }

    // Unknown type — log and ignore
    if (type != null) {
      debugPrint('[PushNotification] Unknown notification type: $type');
    }
  }

  /// Test-only entry point — exercises notification routing logic without
  /// requiring a real [RemoteMessage] or Firebase runtime.
  ///
  /// [data] should mirror the `RemoteMessage.data` map for the notification
  /// type under test. The injectable [onNotificationRoute] callback receives
  /// the resolved route and arguments.
  // ignore: invalid_use_of_visible_for_testing_member
  void handleNotificationDataForTest(Map<String, dynamic> data) {
    _routeNotificationData(data, null);
  }

  /// Navigate using the injectable seam (for tests) or the real Navigator.
  void _navigate({
    required String route,
    required Map<String, dynamic> arguments,
    required GlobalKey<NavigatorState>? navigatorKey,
  }) {
    // Use injectable seam first (for testing)
    if (onNotificationRoute != null) {
      onNotificationRoute!(route, arguments);
      return;
    }
    // Default: use real Navigator
    if (navigatorKey == null) return;
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  void dispose() {
    _messaging = null;
    _fcmToken = null;
  }
}
