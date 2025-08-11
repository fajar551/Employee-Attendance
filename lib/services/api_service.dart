import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://hris.qwords.com/backend/public/api';
  static const String fallbackUrl = 'https://43.252.137.238/backend/public/api';

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      return await _makeRequest('$baseUrl/login', 'POST', body: {
        'email': email,
        'password': password,
      });
    } catch (e) {
      print('Login dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/login', 'POST', body: {
        'email': email,
        'password': password,
      });
    }
  }

  static Future<Map<String, dynamic>> sendAttendance(
      String token, Map<String, dynamic> data) async {
    try {
      return await _makeRequest('$baseUrl/absensiAndroid', 'POST',
          headers: {'Authorization': 'Bearer $token'}, body: data);
    } catch (e) {
      print('Absensi dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/absensiAndroid', 'POST',
          headers: {'Authorization': 'Bearer $token'}, body: data);
    }
  }

  static Future<Map<String, dynamic>> getAttendanceHistory(String token) async {
    try {
      return await _makeRequest('$baseUrl/getAbsensiHistoryAndroid', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('History dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/getAbsensiHistoryAndroid', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getDashboardData(String token) async {
    try {
      return await _makeRequest('$baseUrl/dashboardAndroid', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Dashboard dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/dashboardAndroid', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> _makeRequest(String url, String method,
      {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    try {
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      http.Response response;
      if (method == 'GET') {
        response = await http.get(Uri.parse(url), headers: requestHeaders);
      } else if (method == 'POST') {
        response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        throw Exception('Method tidak didukung: $method');
      }

      print('Debug: $method $url - Status: ${response.statusCode}');
      print('Debug: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Request gagal (${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat request: $e');
    }
  }
}
