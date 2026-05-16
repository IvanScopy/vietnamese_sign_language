import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/sos_api_service.dart';

// Helper to build a mock http.Response
http.Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), statusCode, headers: {
    'content-type': 'application/json',
  });
}

void main() {
  const testToken = 'test-bearer-token-123';
  const baseUrl = 'http://test.example.com';

  group('SosApiService', () {
    group('createAlert', () {
      test('includes Bearer Authorization header in request', () async {
        String? capturedAuth;
        final client = MockClient((request) async {
          capturedAuth = request.headers['authorization'];
          return _jsonResponse(200, {
            'id': 1,
            'status': 'sending',
            'contactsCount': 2,
            'attempts': [],
            'fallbackTargets': [],
          });
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        await service.createAlert();

        expect(capturedAuth, equals('Bearer $testToken'));
      });

      test('parses SosAlertResponse correctly from JSON', () async {
        final client = MockClient((request) async {
          return _jsonResponse(200, {
            'id': 42,
            'status': 'sent',
            'smsBody': 'Tôi cần giúp đỡ! Vị trí: ...',
            'contactsCount': 3,
            'attempts': [
              {
                'id': 1,
                'channel': 'sms',
                'status': 'delivered',
                'recipientName': 'Mẹ',
                'recipientPhoneE164': '+84901234567',
              }
            ],
            'fallbackTargets': [
              {'name': 'Ba', 'phoneE164': '+84907654321'},
            ],
          });
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        final result = await service.createAlert(
          latitude: 10.7769,
          longitude: 106.7009,
          locationAccuracyMeters: 15.0,
          locationLabel: 'current',
        );

        expect(result.id, equals(42));
        expect(result.status, equals(SosAggregateStatus.sent));
        expect(result.smsBody, equals('Tôi cần giúp đỡ! Vị trí: ...'));
        expect(result.contactsCount, equals(3));
        expect(result.attempts.length, equals(1));
        expect(result.attempts.first.channel, equals('sms'));
        expect(result.attempts.first.recipientName, equals('Mẹ'));
        expect(result.fallbackTargets.length, equals(1));
        expect(result.fallbackTargets.first.name, equals('Ba'));
      });

      test('throws SosAuthException on 401 response', () async {
        final client = MockClient(
          (request) async => http.Response('{"error":"Unauthorized"}', 401),
        );

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );

        expect(
          () => service.createAlert(),
          throwsA(isA<SosAuthException>()),
        );
      });

      test('sends location fields when provided', () async {
        Map<String, dynamic>? capturedBody;
        final client = MockClient((request) async {
          capturedBody =
              jsonDecode(request.body) as Map<String, dynamic>;
          return _jsonResponse(200, {
            'id': 5,
            'status': 'sending',
            'contactsCount': 1,
            'attempts': [],
            'fallbackTargets': [],
          });
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        await service.createAlert(
          latitude: 10.7769,
          longitude: 106.7009,
          locationAccuracyMeters: 25.5,
          locationLabel: 'current',
          locationCapturedAt: '2026-05-16T10:00:00Z',
          idempotencyKey: 'idem-key-abc',
        );

        expect(capturedBody?['latitude'], closeTo(10.7769, 0.0001));
        expect(capturedBody?['longitude'], closeTo(106.7009, 0.0001));
        expect(capturedBody?['locationAccuracyMeters'], closeTo(25.5, 0.01));
        expect(capturedBody?['locationLabel'], equals('current'));
        expect(
            capturedBody?['locationCapturedAt'], equals('2026-05-16T10:00:00Z'));
        expect(capturedBody?['idempotencyKey'], equals('idem-key-abc'));
      });

      test('maps partial_failed status correctly', () async {
        final client = MockClient((request) async {
          return _jsonResponse(200, {
            'id': 7,
            'status': 'partial_failed',
            'contactsCount': 2,
            'attempts': [],
            'fallbackTargets': [],
          });
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        final result = await service.createAlert();
        expect(result.status, equals(SosAggregateStatus.partialFailed));
      });
    });

    group('recordFallback', () {
      test('native_sms_opened fallback type is not treated as confirmed sent',
          () async {
        String? capturedFallbackType;
        int? capturedAlertId;

        final client = MockClient((request) async {
          capturedAlertId = int.tryParse(
            RegExp(r'/alerts/(\d+)/fallback').firstMatch(request.url.path)?.group(1) ?? '',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          capturedFallbackType = body['fallbackType'] as String?;
          return http.Response('{}', 204);
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );

        // Should complete without throwing
        await service.recordFallback(
          99,
          fallbackType: 'native_sms_opened',
          attemptIds: [1, 2],
        );

        expect(capturedAlertId, equals(99));
        expect(capturedFallbackType, equals('native_sms_opened'));
        // native_sms_opened records intent, not confirmed delivery — no SosAlertResponse returned
      });

      test('sends fallbackType and attemptIds in request body', () async {
        Map<String, dynamic>? capturedBody;
        final client = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 204);
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        await service.recordFallback(
          10,
          fallbackType: 'native_sms_opened',
          attemptIds: [3, 4, 5],
        );

        expect(capturedBody?['fallbackType'], equals('native_sms_opened'));
        expect(capturedBody?['attemptIds'], equals([3, 4, 5]));
      });
    });

    group('updateLocation', () {
      test('sends correct body with location label', () async {
        Map<String, dynamic>? capturedBody;
        Uri? capturedUri;

        final client = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          capturedUri = request.url;
          return http.Response('{}', 200);
        });

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );
        await service.updateLocation(
          55,
          latitude: 21.0285,
          longitude: 105.8542,
          locationAccuracyMeters: 8.0,
          locationLabel: 'approximate',
          locationCapturedAt: '2026-05-16T12:00:00Z',
        );

        expect(capturedUri?.path, equals('/api/sos/alerts/55/location'));
        expect(capturedBody?['latitude'], closeTo(21.0285, 0.0001));
        expect(capturedBody?['longitude'], closeTo(105.8542, 0.0001));
        expect(capturedBody?['locationLabel'], equals('approximate'));
        expect(capturedBody?['locationAccuracyMeters'], closeTo(8.0, 0.01));
        expect(
            capturedBody?['locationCapturedAt'], equals('2026-05-16T12:00:00Z'));
      });

      test('throws SosAuthException on 401', () async {
        final client = MockClient(
          (request) async => http.Response('{"error":"Unauthorized"}', 401),
        );

        final service = SosApiService(
          authToken: testToken,
          client: client,
          baseUrl: baseUrl,
        );

        expect(
          () => service.updateLocation(
            1,
            latitude: 0,
            longitude: 0,
            locationLabel: 'current',
          ),
          throwsA(isA<SosAuthException>()),
        );
      });
    });
  });
}
