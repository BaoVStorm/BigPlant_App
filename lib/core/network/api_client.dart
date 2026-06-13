import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/auth_session_manager.dart';

class ApiClient {
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(timeout);
      return await _decodeResponse(response);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out after ${timeout.inSeconds}s',
        statusCode: 408,
      );
    } on SocketException {
      throw ApiException(
        message: 'Network unreachable. Check server and adb reverse mapping.',
        statusCode: 503,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'HTTP client error: $e', statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    try {
      final response = await http
          .post(Uri.parse(url), headers: mergedHeaders, body: jsonEncode(body))
          .timeout(timeout);
      return await _decodeResponse(response);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out after ${timeout.inSeconds}s',
        statusCode: 408,
      );
    } on SocketException {
      throw ApiException(
        message: 'Network unreachable. Check server and adb reverse mapping.',
        statusCode: 503,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'HTTP client error: $e', statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> put(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final mergedHeaders = {'Content-Type': 'application/json', ...?headers};
    try {
      final response = await http
          .put(Uri.parse(url), headers: mergedHeaders, body: jsonEncode(body))
          .timeout(timeout);
      return await _decodeResponse(response);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out after ${timeout.inSeconds}s',
        statusCode: 408,
      );
    } on SocketException {
      throw ApiException(
        message: 'Network unreachable. Check server and adb reverse mapping.',
        statusCode: 503,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'HTTP client error: $e', statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(timeout);
      return await _decodeResponse(response);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out after ${timeout.inSeconds}s',
        statusCode: 408,
      );
    } on SocketException {
      throw ApiException(
        message: 'Network unreachable. Check server and adb reverse mapping.',
        statusCode: 503,
      );
    } on http.ClientException catch (e) {
      throw ApiException(message: 'HTTP client error: $e', statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> _decodeResponse(http.Response response) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'msg': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      await AuthSessionManager.handleUnauthorized();
    }

    final message = body['msg']?.toString() ??
        body['detail']?.toString() ??
        'Request failed';
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
