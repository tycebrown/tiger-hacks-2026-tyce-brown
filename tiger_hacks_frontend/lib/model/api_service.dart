import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiger_hacks_frontend/model/api_models.dart';
import 'package:tiger_hacks_frontend/model/user.dart';

class ApiService {
  static Uri baseUri = Uri.parse('http://127.0.0.1:8000');
  static final http.Client _client = http.Client();
  static String? _token;

  static bool get isAuthenticated => _token != null;

  static void logout() {
    _token = null;
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    return baseUri.resolve(path).replace(queryParameters: queryParameters);
  }

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': ?_token,
  };

  static Map<String, String> get _authenticatedHeaders {
    if (_token == null) {
      throw StateError('Log in before calling an authenticated endpoint.');
    }
    return _headers;
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.statusCode == 401) _token = null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = response.body;
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['detail'] is String) {
          message = body['detail'] as String;
        }
      } on FormatException {
        // Keep the raw response body when the server did not return JSON.
      }
      throw ApiException(response.statusCode, message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Future<User?> login(String username, String password) async {
    _token = null;
    try {
      final response = await _client.post(
        _uri('/login'),
        headers: _headers,
        body: jsonEncode(
          LoginRequest(username: username, password: password).toJson(),
        ),
      );
      final loginResponse = LoginResponse.fromJson(
        _decodeResponse(response) as Map<String, dynamic>,
      );
      _token = loginResponse.token;
      return loginResponse.user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  static Future<MeasureModel> recordMeasures({
    required int userId,
    required MeasureModelData data,
  }) async {
    final response = await _client.post(
      _uri('/user/$userId/one-time-record-measures'),
      headers: _authenticatedHeaders,
      body: jsonEncode(data.toJson()),
    );
    return MeasureModel.fromJson(
      _decodeResponse(response) as Map<String, dynamic>,
    );
  }

  static Future<List<MeasureModel>> queryMeasures({
    required int userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _client.post(
      _uri('/user/$userId/query', {
        ...MeasureQueryParams(start: start, end: end).toQueryParameters(),
      }),
      headers: _authenticatedHeaders,
    );
    final json = _decodeResponse(response) as List<dynamic>;
    return json
        .map((item) => MeasureModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<SharepointModel> shareUser({
    required int userId,
    required String caretakerUsername,
  }) async {
    final response = await _client.post(
      _uri('/user/$userId/share/${Uri.encodeComponent(caretakerUsername)}'),
      headers: _authenticatedHeaders,
    );
    return SharepointModel.fromJson(
      _decodeResponse(response) as Map<String, dynamic>,
    );
  }

  static Future<List<SharedUserModel>> getCaretakers(int userId) async {
    final response = await _client.get(
      _uri('/user/$userId/caretakers'),
      headers: _authenticatedHeaders,
    );
    final json = _decodeResponse(response) as List<dynamic>;
    return json
        .map((item) => SharedUserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<SharedUserModel>> getPatients(int caretakerId) async {
    final response = await _client.get(
      _uri('/caretaker/$caretakerId/patients'),
      headers: _authenticatedHeaders,
    );
    final json = _decodeResponse(response) as List<dynamic>;
    return json
        .map((item) => SharedUserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<MeasureModel>> queryPersonalMeasures({
    required int caretakerId,
    required int individualId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _client.post(
      _uri('/caretaker/$caretakerId/user/$individualId/query', {
        ...MeasureQueryParams(start: start, end: end).toQueryParameters(),
      }),
      headers: _authenticatedHeaders,
    );
    final json = _decodeResponse(response) as List<dynamic>;
    return json
        .map((item) => MeasureModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
