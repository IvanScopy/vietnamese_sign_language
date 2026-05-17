import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/models/call_state.dart';

/// Exception thrown when call API requests fail.
class CallApiException implements Exception {
  final String message;
  final int? statusCode;

  CallApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'CallApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Exception thrown when the user is not authenticated.
class AuthException extends CallApiException {
  AuthException(super.message);
}

/// Exception thrown when the callee is busy (409 conflict).
class CallUnavailableException extends CallApiException {
  CallUnavailableException(super.message);
}

/// HTTP client for call lifecycle endpoints.
///
/// All methods include Authorization: Bearer header.
/// Error handling:
/// - 401 → AuthException
/// - 409 → CallUnavailableException
/// - Other errors → CallApiException with status code and message
class CallApiService {
  final String baseUrl;
  final String authToken;
  final http.Client _client;

  CallApiService({
    required this.baseUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Initiate a new video call to the given callee.
  /// POST /api/calls with { calleeId }
  /// Returns CallSession with callId and roomName.
  Future<CallSession> createCall(int calleeId) async {
    final uri = Uri.parse('$baseUrl/api/calls');
    final response = await _client.post(
      uri,
      headers: _authHeaders,
      body: jsonEncode({'calleeId': calleeId}),
    );

    _throwOnError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CallSession.fromJson(data);
  }

  /// Accept an incoming call.
  /// POST /api/calls/{id}/accept
  /// Returns CallSession with roomName and token for LiveKit connection.
  Future<CallSession> acceptCall(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId/accept');
    final response = await _client.post(uri, headers: _authHeaders);

    _throwOnError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CallSession.fromJson(data);
  }

  /// Reject an incoming call.
  /// POST /api/calls/{id}/reject
  Future<void> rejectCall(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId/reject');
    final response = await _client.post(uri, headers: _authHeaders);

    _throwOnError(response);
  }

  /// Cancel an outgoing call.
  /// POST /api/calls/{id}/cancel
  Future<void> cancelCall(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId/cancel');
    final response = await _client.post(uri, headers: _authHeaders);

    _throwOnError(response);
  }

  /// End an active call.
  /// POST /api/calls/{id}/end
  Future<void> endCall(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId/end');
    final response = await _client.post(uri, headers: _authHeaders);

    _throwOnError(response);
  }

  /// Get a fresh LiveKit token for an existing call.
  /// POST /api/calls/{id}/token
  /// Returns the token string.
  Future<String> getToken(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId/token');
    final response = await _client.post(uri, headers: _authHeaders);

    _throwOnError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['token'] as String;
  }

  /// Fetch current call state from backend.
  /// GET /api/calls/{id}
  /// Used to verify call is still RINGING before showing Accept (prevents stale push opens).
  Future<CallSession> getCallState(int callId) async {
    final uri = Uri.parse('$baseUrl/api/calls/$callId');
    final response = await _client.get(uri, headers: _authHeaders);

    _throwOnError(response);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CallSession.fromJson(data);
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['message'] as String? ?? body['error'] as String? ?? 'Unknown error';
    } catch (_) {
      message = 'Request failed with status ${response.statusCode}';
    }

    switch (response.statusCode) {
      case 401:
        throw AuthException('Authentication required: $message');
      case 409:
        throw CallUnavailableException(message);
      default:
        throw CallApiException(message, statusCode: response.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}
