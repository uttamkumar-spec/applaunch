import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';

/// Thin JSON/HTTP wrapper around the Flask backend that attaches the
/// current Supabase session's access token as a bearer header, so the
/// backend can verify the caller via Supabase's JWT.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${Env.apiBaseUrl}$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final session = Env.isSupabaseConfigured
        ? Supabase.instance.client.auth.currentSession
        : null;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client
        .get(_uri(path, query), headers: _headers)
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body, Duration? timeout}) async {
    final res = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(timeout ?? const Duration(seconds: 15));
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await _client
        .put(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 8));
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
