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

  static Future<Map<String, dynamic>> getSisaCuti(String token) async {
    try {
      return await _makeRequest('$baseUrl/izin/getSisaCuti', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Sisa cuti dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getSisaCuti', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getListCuti(String token) async {
    try {
      return await _makeRequest('$baseUrl/izin', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('List cuti dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getDetailCuti(
      String token, int id) async {
    try {
      return await _makeRequest('$baseUrl/izin/$id', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Detail cuti dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/$id', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getAllIzin(String token) async {
    try {
      return await _makeRequest('$baseUrl/allIzin', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('All izin dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/allIzin', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getStatusHadir(String token) async {
    try {
      return await _makeRequest('$baseUrl/izin/getDataStatusHadir', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Status hadir dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getDataStatusHadir', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> submitIzin(String token,
      Map<String, String> fields, List<http.MultipartFile> files) async {
    try {
      return await _makeMultipartRequest('$baseUrl/izin', 'POST',
          headers: {'Authorization': 'Bearer $token'},
          fields: fields,
          files: files);
    } catch (e) {
      print('Submit izin dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeMultipartRequest('$fallbackUrl/izin', 'POST',
          headers: {'Authorization': 'Bearer $token'},
          fields: fields,
          files: files);
    }
  }

  static Future<Map<String, dynamic>> getUserHrdAcc(String token) async {
    try {
      return await _makeRequest('$baseUrl/izin/getUserHrdAcc', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Get user HRD dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getUserHrdAcc', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> approveIzin(
      String token, int izinId) async {
    try {
      return await _makeRequest('$baseUrl/izin/approve/$izinId', 'POST',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Approve izin dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/approve/$izinId', 'POST',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> rejectIzin(
      String token, int izinId, String keterangan) async {
    try {
      return await _makeRequest('$baseUrl/izin/reject/$izinId', 'POST',
          headers: {'Authorization': 'Bearer $token'},
          body: {'keterangan': keterangan});
    } catch (e) {
      print('Reject izin dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/reject/$izinId', 'POST',
          headers: {'Authorization': 'Bearer $token'},
          body: {'keterangan': keterangan});
    }
  }

  static Future<Map<String, dynamic>> getRole(String token) async {
    try {
      return await _makeRequest('$baseUrl/role', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print('Get role dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getRole', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getProfileKaryawan(String token) async {
    try {
      return await _makeRequest('$baseUrl/izin/getProfileKaryawan', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print(
          'Get profile karyawan dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getProfileKaryawan', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getAllKaryawan(String token) async {
    try {
      return await _makeRequest('$baseUrl/getAllKaryawan', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print(
          'Get all karyawan dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/izin/getAllKaryawan', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    }
  }

  static Future<Map<String, dynamic>> getKaryawanById(
      String token, int id) async {
    try {
      return await _makeRequest('$baseUrl/getKaryawanById/$id', 'GET',
          headers: {'Authorization': 'Bearer $token'});
    } catch (e) {
      print(
          'Get karyawan by ID dengan domain gagal, mencoba dengan IP address: $e');
      return await _makeRequest('$fallbackUrl/getKaryawanById/$id', 'GET',
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

  static Future<Map<String, dynamic>> _makeMultipartRequest(
      String url, String method,
      {Map<String, String>? headers,
      Map<String, String>? fields,
      List<http.MultipartFile>? files}) async {
    try {
      final requestHeaders = {
        'Content-Type': 'multipart/form-data',
        ...?headers,
      };

      final request = http.MultipartRequest(method, Uri.parse(url));
      request.headers.addAll(requestHeaders);

      if (fields != null) {
        for (final key in fields.keys) {
          request.fields[key] = fields[key]!;
        }
      }

      if (files != null) {
        for (final file in files) {
          request.files.add(file);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
