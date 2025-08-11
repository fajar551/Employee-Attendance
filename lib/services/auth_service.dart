import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final data = await ApiService.login(email, password);

      // Simpan token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['access_token']);

      return data;
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
