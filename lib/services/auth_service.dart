import 'api_service.dart';

class AuthService {
  static Future<void> login(String email, String password) async {
    final data = await ApiService.login(email, password);
    // Cek field success/status/message
    if ((data['success'] == true || data['status'] == true) ||
        (data['message']?.toString().toLowerCase().contains('success') ??
            false)) {
      return;
    } else {
      throw Exception(data['message'] ?? 'Login gagal');
    }
  }
}
