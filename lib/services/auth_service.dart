class AuthService {
  static Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == '1' && password == '123') {
      // Login berhasil
      return;
    } else {
      throw Exception('Email atau password salah');
    }
  }
}
