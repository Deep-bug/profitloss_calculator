import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/calc_models.dart';

class ProfitLossApiService {
  ProfitLossApiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<CalcResult> calculate(CalcRequest request) async {
    final response = await _client.post(
      _uri('/api/calc'),
      headers: _jsonHeaders,
      body: jsonEncode(request.toJson()),
    );
    final data = _decode(response);
    return CalcResult.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CalcRule>> fetchRules() async {
    final response = await _client.get(_uri('/api/rules'));
    final data = _decode(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(CalcRule.fromJson)
          .toList();
    }
    return const [];
  }

  Future<CalcRule> saveRule(CalcRequest request) async {
    final response = await _client.post(
      _uri('/api/rules'),
      headers: _jsonHeaders,
      body: jsonEncode(request.toJson()),
    );
    final data = _decode(response);
    return CalcRule.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRule(String id) async {
    final response = await _client.delete(_uri('/api/rules/$id'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _errorMessage(response.body),
      );
    }
  }

  void dispose() {
    _client.close();
  }

  Map<String, String> get _jsonHeaders =>
      const {'Content-Type': 'application/json'};

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(response.statusCode, _errorMessage(response.body));
  }

  String _errorMessage(String body) {
    if (body.isEmpty) return '服务器响应为空';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
