import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}

class AuthProfile {
  const AuthProfile({
    required this.id,
    required this.email,
    required this.userType,
    required this.name,
    required this.emergencyContacts,
  });

  final int id;
  final String email;
  final String userType;
  final String? name;
  final List<Map<String, dynamic>> emergencyContacts;

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    return AuthProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      userType: json['userType'] as String,
      name: json['name'] as String?,
      emergencyContacts: ((json['emergencyContacts'] as List<dynamic>?) ?? const [])
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList(),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.profile,
  });

  final String accessToken;
  final String refreshToken;
  final AuthProfile profile;
}

class AuthService {
  AuthService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<String?> getStoredAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenStorageKey);
  }

  Future<String?> getStoredRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenStorageKey);
  }

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenStorageKey, accessToken);
    await prefs.setString(refreshTokenStorageKey, refreshToken);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenStorageKey);
    await prefs.remove(refreshTokenStorageKey);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    final response = await _client.post(
      _uri('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'userType': userType,
      }),
    );
    return _sessionFromResponse(response);
  }

  Future<AuthSession> refresh() async {
    final refreshToken = await getStoredRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    final response = await _client.post(
      _uri('/api/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await clearSession();
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException('Request failed', statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['accessToken'] as String;
    final newRefreshToken = body['refreshToken'] as String;
    await _storeTokens(accessToken, newRefreshToken);
    final profile = await getProfile(accessToken: accessToken);
    return AuthSession(
      accessToken: accessToken,
      refreshToken: newRefreshToken,
      profile: profile,
    );
  }

  Future<void> logout() async {
    final refreshToken = await getStoredRefreshToken();
    await _client.post(
      _uri('/api/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    await clearSession();
  }

  Future<AuthProfile> getProfile({String? accessToken}) async {
    final token = accessToken ?? await getStoredAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    final response = await _client.get(
      _uri('/api/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return _profileFromResponse(response);
  }

  Future<AuthProfile> updateProfile({
    String? name,
    String? userType,
  }) async {
    final token = await getStoredAccessToken();
    final response = await _client.put(
      _uri('/api/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'userType': userType,
      }..removeWhere((key, value) => value == null)),
    );
    return _profileFromResponse(response);
  }

  Future<List<Map<String, dynamic>>> listEmergencyContacts() async {
    final token = await getStoredAccessToken();
    final response = await _client.get(
      _uri('/api/user/emergency-contacts'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ((body['contacts'] as List<dynamic>?) ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
  }

  Future<void> saveEmergencyContact({
    int? id,
    required String name,
    required String phone,
  }) async {
    final token = await getStoredAccessToken();
    final response = await _client.patch(
      _uri('/api/user/emergency-contacts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
      }..removeWhere((key, value) => value == null)),
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw AuthException('Could not save emergency contact', statusCode: response.statusCode);
    }
  }

  Future<AuthSession> _sessionFromResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw AuthException('Authentication failed', statusCode: response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = body['accessToken'] as String;
    final refreshToken = body['refreshToken'] as String;
    final profile = AuthProfile.fromJson(body['user'] as Map<String, dynamic>);
    await _storeTokens(accessToken, refreshToken);
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      profile: profile,
    );
  }

  AuthProfile _profileFromResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Your session expired. Log in again to continue.', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw AuthException('Could not load profile', statusCode: response.statusCode);
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthProfile.fromJson(body['user'] as Map<String, dynamic>);
  }
}
