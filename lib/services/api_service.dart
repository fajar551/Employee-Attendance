import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('https://hris.qwords.com/backend/public/api/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal terhubung ke server (${response.statusCode})');
    }
  }
}
