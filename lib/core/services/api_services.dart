import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hasbni/core/constants/api_constants.dart';
import 'package:hasbni/core/services/network_service.dart'; // Import NetworkService

class ApiService {
  final _storage = const FlutterSecureStorage();
  final _network = NetworkService();

  // Timeout duration: If server doesn't reply in 5 seconds, go offline.
  static const Duration _timeout = Duration(seconds: 10);
 static bool isOfflineMode = false; 
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// The "Smart" Request Handler
  Future<dynamic> _performRequest(Future<http.Response> Function() request) async {
    // --- 1. CHECK GLOBAL OFFLINE MODE ---
    if (isOfflineMode) {
      print("⚠️ Global Offline Mode active. Skipping network request.");
      throw SocketException('Offline Mode'); 
    }

    // 2. Check Device Connectivity (Wifi/Data enabled?)
    bool connected = await _network.isConnected;
    if (!connected) {
      throw SocketException('No Internet'); 
    }

    try {
      final response = await request().timeout(_timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw SocketException('Server Timeout');
    } on SocketException {
      throw SocketException('Server Unreachable');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print('GET: $uri');
    return _performRequest(() async {
      return await http.get(uri, headers: await _getHeaders());
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print('POST: $uri');
    return _performRequest(() async {
      return await http.post(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _performRequest(() async {
      return await http.put(
        uri,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    });
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _performRequest(() async {
      return await http.delete(uri, headers: await _getHeaders());
    });
  }

  dynamic _handleResponse(http.Response response) {
    print('Status: ${response.statusCode}');
    // print('Body: ${response.body}'); // Uncomment for debugging

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return true;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'حدث خطأ غير معروف (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body['errors'] != null && body['errors'] is Map) {
          final Map<String, dynamic> errors = body['errors'];
          String validationMsgs = '';
          errors.forEach((key, value) {
            if (value is List) validationMsgs += '${value.join('\n')}\n';
          });
          if (validationMsgs.isNotEmpty) errorMessage = validationMsgs.trim();
        } else if (body['message'] != null) {
          errorMessage = body['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
