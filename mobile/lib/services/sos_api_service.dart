import 'dart:convert';
import 'package:http/http.dart' as http;

enum SosAggregateStatus { sending, sent, partialFailed, nativeFallback, failed }

class SosAttemptSummary {
  final int id;
  final String channel;
  final String status;
  final String? recipientName;
  final String? recipientPhoneE164;

  SosAttemptSummary({
    required this.id,
    required this.channel,
    required this.status,
    this.recipientName,
    this.recipientPhoneE164,
  });

  factory SosAttemptSummary.fromJson(Map<String, dynamic> json) =>
      SosAttemptSummary(
        id: json['id'] as int,
        channel: json['channel'] as String,
        status: json['status'] as String,
        recipientName: json['recipientName'] as String?,
        recipientPhoneE164: json['recipientPhoneE164'] as String?,
      );
}

class SosFallbackTarget {
  final String name;
  final String phoneE164;

  SosFallbackTarget({required this.name, required this.phoneE164});

  factory SosFallbackTarget.fromJson(Map<String, dynamic> json) =>
      SosFallbackTarget(
        name: json['name'] as String,
        phoneE164: json['phoneE164'] as String,
      );
}

class SosAlertResponse {
  final int id;
  final SosAggregateStatus status;
  final String? smsBody;
  final int contactsCount;
  final List<SosAttemptSummary> attempts;
  final List<SosFallbackTarget> fallbackTargets;

  SosAlertResponse({
    required this.id,
    required this.status,
    this.smsBody,
    required this.contactsCount,
    required this.attempts,
    required this.fallbackTargets,
  });

  factory SosAlertResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'sending';
    final status = switch (statusStr.toLowerCase()) {
      'sent' => SosAggregateStatus.sent,
      'partial_failed' || 'partial-failed' => SosAggregateStatus.partialFailed,
      'native_fallback' || 'native-fallback' =>
        SosAggregateStatus.nativeFallback,
      'failed' => SosAggregateStatus.failed,
      _ => SosAggregateStatus.sending,
    };
    return SosAlertResponse(
      id: json['id'] as int,
      status: status,
      smsBody: json['smsBody'] as String?,
      contactsCount: (json['contactsCount'] as int?) ?? 0,
      attempts: (json['attempts'] as List<dynamic>? ?? [])
          .map((e) => SosAttemptSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      fallbackTargets: (json['fallbackTargets'] as List<dynamic>? ?? [])
          .map((e) => SosFallbackTarget.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SosApiException implements Exception {
  final int statusCode;
  final String message;

  SosApiException(this.statusCode, this.message);

  @override
  String toString() => 'SosApiException($statusCode): $message';
}

class SosAuthException extends SosApiException {
  SosAuthException() : super(401, 'Unauthorized');
}

/// HTTP client for SOS emergency alert endpoints.
///
/// All methods include Authorization: Bearer header.
/// Error handling:
/// - 401 → SosAuthException
/// - Other 4xx/5xx → SosApiException with status code and message
class SosApiService {
  /// Default base URL for development (Android emulator host).
  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

  final http.Client _client;
  final String _authToken;
  final String _baseUrl;

  SosApiService({
    required String authToken,
    http.Client? client,
    String? baseUrl,
  }) : _authToken = authToken,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? _defaultBaseUrl;

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_authToken',
    'Content-Type': 'application/json',
  };

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) throw SosAuthException();
    if (response.statusCode >= 400) {
      String msg = 'Request failed';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        msg =
            body['error'] as String? ?? body['message'] as String? ?? msg;
      } catch (_) {}
      throw SosApiException(response.statusCode, msg);
    }
  }

  /// Create an SOS alert, optionally including GPS location.
  ///
  /// POST /api/sos/alerts
  /// Returns [SosAlertResponse] with delivery status and fallback targets.
  Future<SosAlertResponse> createAlert({
    double? latitude,
    double? longitude,
    double? locationAccuracyMeters,
    String? locationLabel,
    String? locationCapturedAt,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (locationAccuracyMeters != null) {
      body['locationAccuracyMeters'] = locationAccuracyMeters;
    }
    if (locationLabel != null) body['locationLabel'] = locationLabel;
    if (locationCapturedAt != null) {
      body['locationCapturedAt'] = locationCapturedAt;
    }
    if (idempotencyKey != null) body['idempotencyKey'] = idempotencyKey;

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/sos/alerts'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _throwOnError(response);
    return SosAlertResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Update GPS location on an existing SOS alert.
  ///
  /// PATCH /api/sos/alerts/{id}/location
  Future<void> updateLocation(
    int alertId, {
    required double latitude,
    required double longitude,
    double? locationAccuracyMeters,
    required String locationLabel,
    String? locationCapturedAt,
  }) async {
    final body = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'locationLabel': locationLabel,
    };
    if (locationAccuracyMeters != null) {
      body['locationAccuracyMeters'] = locationAccuracyMeters;
    }
    if (locationCapturedAt != null) {
      body['locationCapturedAt'] = locationCapturedAt;
    }

    final response = await _client.patch(
      Uri.parse('$_baseUrl/api/sos/alerts/$alertId/location'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _throwOnError(response);
  }

  /// Record that the user opened a native SMS fallback.
  ///
  /// POST /api/sos/alerts/{id}/fallback
  Future<void> recordFallback(
    int alertId, {
    required String fallbackType,
    List<int>? attemptIds,
  }) async {
    final body = <String, dynamic>{'fallbackType': fallbackType};
    if (attemptIds != null) body['attemptIds'] = attemptIds;

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/sos/alerts/$alertId/fallback'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _throwOnError(response);
  }

  void dispose() {
    _client.close();
  }
}
