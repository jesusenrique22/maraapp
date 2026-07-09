import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _authToken;

  String get baseUrl => AppConfig.apiBaseUrl;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool json = false}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final body = await _request('GET', path, query: query);
    return body as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, String>? query,
  }) async {
    final body = await _request('GET', path, query: query);
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postMap(
    String path,
    Map<String, dynamic> data,
  ) async {
    final body = await _request('POST', path, body: data);
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchMap(
    String path,
    Map<String, dynamic> data,
  ) async {
    final body = await _request('PATCH', path, body: data);
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final body = await _request('DELETE', path);
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadImage({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$baseUrl/admin/upload/image');
    final request = http.MultipartRequest('POST', uri);

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      String message = 'Error al subir imagen (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['message'] is String) {
          message = decoded['message'] as String;
        } else if (decoded['message'] is List) {
          message = (decoded['message'] as List).join(', ');
        }
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('No se pudo subir la imagen');
    }
  }

  /// Escanea receta médica: envía imagen al backend → IA + inventario.
  Future<Map<String, dynamic>> scanPrescription({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse('$baseUrl/ai/prescription/scan');
    final request = http.MultipartRequest('POST', uri);

    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      String message = 'Error al escanear receta (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['message'] is String) {
          message = decoded['message'] as String;
        } else if (decoded['message'] is List) {
          message = (decoded['message'] as List).join(', ');
        }
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('No se pudo escanear la receta');
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    try {
      final response = await switch (method) {
        'GET' => _client.get(uri, headers: _headers()),
        'POST' => _client.post(
            uri,
            headers: _headers(json: true),
            body: body == null ? null : jsonEncode(body),
          ),
        'PATCH' => _client.patch(
            uri,
            headers: _headers(json: true),
            body: body == null ? null : jsonEncode(body),
          ),
        'DELETE' => _client.delete(uri, headers: _headers()),
        _ => throw ApiException('Método no soportado'),
      };

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      }

      String message = 'Error (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['message'] is String) {
          message = decoded['message'] as String;
        } else if (decoded['message'] is List) {
          message = (decoded['message'] as List).join(', ');
        }
      } catch (_) {}

      throw ApiException(message, statusCode: response.statusCode);
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('No se pudo conectar con la API en $baseUrl');
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  ref.keepAlive();
  return ApiClient();
});
