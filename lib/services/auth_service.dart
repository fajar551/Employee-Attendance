import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static Future<void> login(String email, String password) async {
    final data = await ApiService.login(email, password);
    if ((data['success'] == true || data['status'] == true) ||
        (data['message']?.toString().toLowerCase().contains('success') ??
            false)) {
      // Simpan token ke SharedPreferences
      if (data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['access_token']);
      }
      return;
    } else {
      throw Exception(data['message'] ?? 'Login gagal');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
