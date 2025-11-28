import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_response.dart';

/// 统一封装的网络客户端，负责处理成功标识、解析与错误抛出
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.successKey = 'success',
    this.successValue = true,
    this.messageKey = 'message',
    this.dataKey = 'data',
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  final String baseUrl;
  final String successKey;
  final dynamic successValue;
  final String messageKey;
  final String dataKey;
  final http.Client _client;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    T Function(dynamic json)? parser,
  }) {
    return _request(
      method: 'GET',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    T Function(dynamic json)? parser,
  }) {
    return _request(
      method: 'POST',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    T Function(dynamic json)? parser,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> _request<T>({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    T Function(dynamic json)? parser,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: mergedHeaders);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: mergedHeaders,
          body: _encodeBody(body),
        );
        break;
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: mergedHeaders,
          body: _encodeBody(body),
        );
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    final decoded = _decode(response);
    final success = _isSuccess(response.statusCode, decoded);
    final message = _extractMessage(decoded);
    final payload = _extractData(decoded);

    if (!success) {
      throw ApiException(response.statusCode, message ?? '请求失败');
    }

    final parsed = parser != null ? parser(payload) : payload as T;
    return ApiResponse<T>(
      success: success,
      message: message,
      data: parsed,
      raw: decoded,
      statusCode: response.statusCode,
    );
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  bool _isSuccess(int statusCode, dynamic decoded) {
    var success = statusCode >= 200 && statusCode < 300;
    if (decoded is Map && decoded.containsKey(successKey)) {
      final value = decoded[successKey];
      success =
          successValue != null ? value == successValue : value == true;
    }
    return success;
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map && decoded[messageKey] != null) {
      return decoded[messageKey].toString();
    }
    return null;
  }

  dynamic _extractData(dynamic decoded) {
    if (decoded is Map && decoded.containsKey(dataKey)) {
      return decoded[dataKey];
    }
    return decoded;
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }

  void dispose() {
    _client.close();
  }
}

