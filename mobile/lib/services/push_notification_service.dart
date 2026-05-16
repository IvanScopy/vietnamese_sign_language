import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for Firebase Cloud Messaging push notifications.
///
/// Handles:
/// - Firebase initialization
/// - FCM token registration with backend
/// - Notification-open routing to incoming call screen
///
/// Gracefully handles missing Firebase config: logs warning and continues.
/// Foreground Socket.io signaling still works without FCM.
class PushNotificationService {
  final String baseUrl;
  final String? authToken;
  FirebaseMessaging? _messaging;
  String? _fcmToken;

  PushNotificationService({
    required this.baseUrl,
    this.authToken,
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

  /// Handle notification open — route to incoming call screen for VIDEO_CALL type.
  void _handleNotificationOpen(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final data = message.data;
    final type = data['type'] as String?;

    if (type == 'VIDEO_CALL') {
      debugPrint('[PushNotification] VIDEO_CALL notification opened');
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamed(
          '/calls/incoming',
          arguments: {
            'callId': data['callId'],
            'fromUserId': data['fromUserId'],
            'fromUserName': data['fromUserName'],
          },
        );
      }
    }
  }

  void dispose() {
    _messaging = null;
    _fcmToken = null;
  }
}
