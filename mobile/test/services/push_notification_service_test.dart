import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/push_notification_service.dart';

/// Builds a minimal RemoteMessage for testing notification routing.
///
/// Firebase's RemoteMessage constructor is not easily mockable, so we rely on
/// the injectable [NotificationRouter] seam in [PushNotificationService] rather
/// than constructing real RemoteMessage objects or requiring Firebase.
///
/// These tests verify the routing logic in [PushNotificationService] by
/// injecting a [NotificationRouter] callback and directly invoking
/// [_handleNotificationOpen] through the public [testRoute] helper exposed
/// via the testing seam.
void main() {
  // -------------------------------------------------------------------------
  // The injectable routing seam avoids Firebase runtime for unit tests.
  // We test routing decisions by exercising handleNotificationOpenForTest(),
  // a @visibleForTesting entry point that calls _handleNotificationOpen
  // with a mocked message data map.
  // -------------------------------------------------------------------------

  group('PushNotificationService routing seam', () {
    test('VIDEO_CALL notification routes to /calls/incoming with correct args',
        () {
      String? routedTo;
      Map<String, dynamic>? routedArgs;

      final service = PushNotificationService(
        baseUrl: 'http://localhost',
        authToken: 'test-token',
        onNotificationRoute: (route, args) {
          routedTo = route;
          routedArgs = args;
        },
      );

      service.handleNotificationDataForTest({
        'type': 'VIDEO_CALL',
        'callId': '42',
        'fromUserId': '7',
        'fromUserName': 'Nguyễn Văn B',
      });

      expect(routedTo, equals('/calls/incoming'));
      expect(routedArgs?['callId'], equals('42'));
      expect(routedArgs?['fromUserName'], equals('Nguyễn Văn B'));
    });

    test('SOS notification routes to /sos with correct args', () {
      String? routedTo;
      Map<String, dynamic>? routedArgs;

      final service = PushNotificationService(
        baseUrl: 'http://localhost',
        authToken: 'test-token',
        onNotificationRoute: (route, args) {
          routedTo = route;
          routedArgs = args;
        },
      );

      service.handleNotificationDataForTest({
        'type': 'SOS',
        'alertId': '99',
        'fromUserName': 'Trần Thị C',
        'status': 'sent',
        'locationLabel': 'vị trí hiện tại',
      });

      expect(routedTo, equals('/sos'));
      expect(routedArgs?['alertId'], equals('99'));
      expect(routedArgs?['fromUserName'], equals('Trần Thị C'));
      expect(routedArgs?['status'], equals('sent'));
      expect(routedArgs?['locationLabel'], equals('vị trí hiện tại'));
    });

    test('Unknown notification type does not route anywhere', () {
      String? routedTo;

      final service = PushNotificationService(
        baseUrl: 'http://localhost',
        authToken: 'test-token',
        onNotificationRoute: (route, args) {
          routedTo = route;
        },
      );

      service.handleNotificationDataForTest({
        'type': 'UNKNOWN_TYPE',
        'someData': 'value',
      });

      expect(routedTo, isNull);
    });

    test('Null type does not route anywhere', () {
      String? routedTo;

      final service = PushNotificationService(
        baseUrl: 'http://localhost',
        onNotificationRoute: (route, args) {
          routedTo = route;
        },
      );

      service.handleNotificationDataForTest({
        'someData': 'value',
      });

      expect(routedTo, isNull);
    });

    test('VIDEO_CALL routing still works alongside SOS routing', () {
      final routes = <String>[];

      final service = PushNotificationService(
        baseUrl: 'http://localhost',
        onNotificationRoute: (route, _) => routes.add(route),
      );

      service.handleNotificationDataForTest({'type': 'VIDEO_CALL', 'callId': '1'});
      service.handleNotificationDataForTest({'type': 'SOS', 'alertId': '2'});

      expect(routes, equals(['/calls/incoming', '/sos']));
    });
  });
}
