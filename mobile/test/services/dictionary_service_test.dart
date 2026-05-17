import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/dictionary_service.dart';

http.Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return http.Response(jsonEncode(body), statusCode, headers: {
    'content-type': 'application/json',
  });
}

void main() {
  const token = 'dictionary-token';
  const baseUrl = 'http://test.example.com';

  group('DictionaryService', () {
    test('includes Bearer Authorization header on list requests', () async {
      String? capturedAuth;
      final client = MockClient((request) async {
        capturedAuth = request.headers['authorization'];
        return _jsonResponse(200, {
          'entries': <Map<String, dynamic>>[],
          'categories': <Map<String, dynamic>>[],
        });
      });

      final service = DictionaryService(
        authToken: token,
        client: client,
        baseUrl: baseUrl,
      );

      await service.searchSigns(query: 'gia đình');

      expect(capturedAuth, equals('Bearer $token'));
    });

    test('calls /api/dictionary with Vietnamese query and category filters', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _jsonResponse(200, {
          'entries': <Map<String, dynamic>>[],
          'categories': <Map<String, dynamic>>[],
        });
      });

      final service = DictionaryService(
        authToken: token,
        client: client,
        baseUrl: baseUrl,
      );

      await service.searchSigns(query: 'Gia Dinh', category: 'family');

      expect(capturedUri?.path, equals('/api/dictionary'));
      expect(capturedUri?.queryParameters['search'], equals('Gia Dinh'));
      expect(capturedUri?.queryParameters['category'], equals('family'));
    });

    test('parses published dictionary list entries without exposing drafts', () async {
      final client = MockClient((request) async {
        return _jsonResponse(200, {
          'entries': [
            {
              'slug': 'gia-dinh',
              'term': 'gia đình',
              'category': {'slug': 'family', 'name': 'Family'},
              'status': 'PUBLISHED',
              'thumbnailUrl': 'https://cdn.example.com/gia-dinh.jpg',
              'thumbnailKey': null,
              'videoUrl': 'https://cdn.example.com/gia-dinh.mp4',
              'videoKey': null,
              'playbackSpeeds': [0.5, 0.75, 1],
            },
          ],
          'categories': [
            {'slug': 'family', 'name': 'Family', 'publishedCount': 1},
          ],
        });
      });

      final service = DictionaryService(
        authToken: token,
        client: client,
        baseUrl: baseUrl,
      );

      final result = await service.searchSigns(query: 'dinh');

      expect(result.entries, hasLength(1));
      expect(result.entries.first.slug, equals('gia-dinh'));
      expect(result.entries.first.status, equals(DictionaryEntryStatus.published));
      expect(result.entries.first.thumbnailUrl, contains('.jpg'));
      expect(result.entries.first.thumbnailKey, isNull);
      expect(result.entries.first.videoUrl, contains('.mp4'));
      expect(result.entries.first.videoKey, isNull);
      expect(result.entries.first.playbackSpeeds, equals([0.5, 0.75, 1]));
      expect(jsonEncode(result.toJson()), isNot(contains('DRAFT')));
    });

    test('parses /api/dictionary/{slug} detail video metadata', () async {
      Uri? capturedUri;
      final client = MockClient((request) async {
        capturedUri = request.url;
        return _jsonResponse(200, {
          'entry': {
            'slug': 'xin-chao',
            'term': 'xin chào',
            'category': {'slug': 'greetings', 'name': 'Greetings'},
            'status': 'PUBLISHED',
            'thumbnailUrl': null,
            'thumbnailKey': 'thumbs/xin-chao.jpg',
            'videoUrl': null,
            'videoKey': 'videos/xin-chao.mp4',
            'keywords': ['xin chao', 'chao'],
            'updatedAt': '2026-05-17T00:00:00Z',
            'playbackSpeeds': [0.5, 0.75, 1],
          },
          'related': <Map<String, dynamic>>[],
        });
      });

      final service = DictionaryService(
        authToken: token,
        client: client,
        baseUrl: baseUrl,
      );

      final detail = await service.getSignDetail('xin-chao');

      expect(capturedUri?.path, equals('/api/dictionary/xin-chao'));
      expect(detail.entry.thumbnailKey, equals('thumbs/xin-chao.jpg'));
      expect(detail.entry.videoKey, equals('videos/xin-chao.mp4'));
      expect(detail.entry.keywords, contains('xin chao'));
      expect(detail.entry.playbackSpeeds, contains(0.75));
    });

    test('maps 401 responses to DictionaryAuthException', () async {
      final client = MockClient(
        (request) async => http.Response('{"error":"Unauthorized"}', 401),
      );

      final service = DictionaryService(
        authToken: token,
        client: client,
        baseUrl: baseUrl,
      );

      expect(
        () => service.searchSigns(query: 'gia đình'),
        throwsA(isA<DictionaryAuthException>()),
      );
    });
  });
}
