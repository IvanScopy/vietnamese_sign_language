import 'dart:convert';

import 'package:http/http.dart' as http;

enum DictionaryEntryStatus { draft, needsReview, published, unpublished }

class DictionaryAuthException implements Exception {
  const DictionaryAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DictionaryCategory {
  const DictionaryCategory({
    required this.slug,
    required this.name,
    required this.publishedCount,
  });

  final String slug;
  final String name;
  final int publishedCount;

  factory DictionaryCategory.fromJson(Map<String, dynamic> json) {
    return DictionaryCategory(
      slug: json['slug'] as String,
      name: json['name'] as String,
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'publishedCount': publishedCount,
      };
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.slug,
    required this.term,
    required this.category,
    required this.status,
    required this.thumbnailUrl,
    required this.thumbnailKey,
    required this.videoUrl,
    required this.videoKey,
    required this.playbackSpeeds,
    this.keywords = const [],
    this.updatedAt,
  });

  final String slug;
  final String term;
  final DictionaryCategory category;
  final DictionaryEntryStatus status;
  final String? thumbnailUrl;
  final String? thumbnailKey;
  final String? videoUrl;
  final String? videoKey;
  final List<double> playbackSpeeds;
  final List<String> keywords;
  final DateTime? updatedAt;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      slug: json['slug'] as String,
      term: (json['term'] ?? json['vietnameseText']) as String,
      category: DictionaryCategory.fromJson(json['category'] as Map<String, dynamic>),
      status: _parseStatus(json['status'] as String?),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailKey: json['thumbnailKey'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoKey: json['videoKey'] as String?,
      playbackSpeeds: ((json['playbackSpeeds'] as List<dynamic>?) ?? const [0.5, 0.75, 1])
          .map((value) => (value as num).toDouble())
          .toList(),
      keywords: ((json['keywords'] as List<dynamic>?) ?? const [])
          .map((value) => value.toString())
          .toList(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'term': term,
        'category': category.toJson(),
        'status': status.name.toUpperCase(),
        'thumbnailUrl': thumbnailUrl,
        'thumbnailKey': thumbnailKey,
        'videoUrl': videoUrl,
        'videoKey': videoKey,
        'playbackSpeeds': playbackSpeeds,
        'keywords': keywords,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class DictionarySearchResult {
  const DictionarySearchResult({
    required this.entries,
    required this.categories,
  });

  final List<DictionaryEntry> entries;
  final List<DictionaryCategory> categories;

  Map<String, dynamic> toJson() => {
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'categories': categories.map((category) => category.toJson()).toList(),
      };
}

class DictionaryDetailResult {
  const DictionaryDetailResult({
    required this.entry,
    required this.related,
  });

  final DictionaryEntry entry;
  final List<DictionaryEntry> related;
}

class DictionaryService {
  DictionaryService({
    required this.authToken,
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String authToken;
  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final parsedBase = Uri.parse(baseUrl);
    final filteredQuery = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        filteredQuery[key] = value;
      }
    });

    return parsedBase.replace(
      path: path,
      queryParameters: filteredQuery.isEmpty ? null : filteredQuery,
    );
  }

  Future<DictionarySearchResult> searchSigns({
    String? query,
    String? category,
  }) async {
    final response = await _client.get(
      _uri('/api/dictionary', {
        'search': query,
        'category': category,
      }),
      headers: {
        'authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 401) {
      throw const DictionaryAuthException('Unauthorized');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DictionarySearchResult(
      entries: ((data['entries'] as List<dynamic>?) ?? const [])
          .map((value) => DictionaryEntry.fromJson(value as Map<String, dynamic>))
          .where((entry) => entry.status == DictionaryEntryStatus.published)
          .toList(),
      categories: ((data['categories'] as List<dynamic>?) ?? const [])
          .map((value) => DictionaryCategory.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<DictionaryDetailResult> getSignDetail(String slug) async {
    final response = await _client.get(
      _uri('/api/dictionary/$slug'),
      headers: {
        'authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 401) {
      throw const DictionaryAuthException('Unauthorized');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return DictionaryDetailResult(
      entry: DictionaryEntry.fromJson(data['entry'] as Map<String, dynamic>),
      related: ((data['related'] as List<dynamic>?) ?? const [])
          .map((value) => DictionaryEntry.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }
}

DictionaryEntryStatus _parseStatus(String? value) {
  switch (value) {
    case 'DRAFT':
      return DictionaryEntryStatus.draft;
    case 'NEEDS_REVIEW':
      return DictionaryEntryStatus.needsReview;
    case 'UNPUBLISHED':
      return DictionaryEntryStatus.unpublished;
    case 'PUBLISHED':
    default:
      return DictionaryEntryStatus.published;
  }
}
