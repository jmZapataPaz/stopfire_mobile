import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:stopfire_mobile/core/config/app_config.dart';

class AppHttpClient {
  final http.Client _client;
  AppHttpClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, dynamic> _redactedBody(Map<String, dynamic> body) {
    if (AppConfig.httpLogSensitive) return body;
    final copy = <String, dynamic>{};
    for (final e in body.entries) {
      final k = e.key.toLowerCase();
      if (k.contains('pass') || k.contains('contra')) {
        copy[e.key] = '***';
      } else if (k.contains('token')) {
        copy[e.key] = '***';
      } else {
        copy[e.key] = e.value;
      }
    }
    return copy;
  }

  Map<String, String> _redactedHeaders(Map<String, String> headers) {
    if (AppConfig.httpLogSensitive) return headers;
    final copy = <String, String>{};
    for (final e in headers.entries) {
      final k = e.key.toLowerCase();
      if (k == 'authorization') {
        copy[e.key] = 'Bearer ***';
      } else {
        copy[e.key] = e.value;
      }
    }
    return copy;
  }

  Future<Map<String, dynamic>> postJson(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP -> POST $url');
      debugPrint('HTTP -> Headers: ${_redactedHeaders(mergedHeaders)}');
      debugPrint('HTTP -> Body: ${_redactedBody(body)}');
    }

    final resp = await _client.post(
      Uri.parse(url),
      headers: mergedHeaders,
      body: jsonEncode(body),
    );

    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP <- Status: ${resp.statusCode}');
      debugPrint('HTTP <- Resp headers: ${_redactedHeaders(resp.headers)}');
      debugPrint('HTTP <- Body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {};
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'raw': decoded.toString()};
      } catch (_) {
        return {'raw': resp.body};
      }
    }

    final failure = HttpFailure('HTTP ${resp.statusCode}: ${resp.body}');
    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP !! Error: $failure');
    }
    throw failure;
  }

  Future<dynamic> getJson(
    String url, {
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = {
      'Accept': 'application/json',
      if (headers != null) ...headers,
    };

    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP -> GET $url');
      debugPrint('HTTP -> Headers: ${_redactedHeaders(mergedHeaders)}');
    }

    final resp = await _client.get(
      Uri.parse(url),
      headers: mergedHeaders,
    );

    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP <- Status: ${resp.statusCode}');
      debugPrint('HTTP <- Resp headers: ${_redactedHeaders(resp.headers)}');
      debugPrint('HTTP <- Body: ${resp.body}');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return {};
      try {
        return jsonDecode(resp.body);
      } catch (_) {
        return {'raw': resp.body};
      }
    }

    final failure = HttpFailure('HTTP ${resp.statusCode}: ${resp.body}');
    if (AppConfig.httpVerboseLogging) {
      debugPrint('HTTP !! Error: $failure');
    }
    throw failure;
  }

  void close() => _client.close();
}

class HttpFailure implements Exception {
  final String message;
  HttpFailure(this.message);
  @override
  String toString() => message;
}