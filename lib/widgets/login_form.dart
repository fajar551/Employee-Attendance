import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _keepMeLoggedIn = true;
  bool _agreeToPrivacy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Add listeners to update button color in real-time
    _usernameController.addListener(_updateButtonColor);
    _passwordController.addListener(_updateButtonColor);
  }

  void _updateButtonColor() {
    setState(() {
      // This will trigger rebuild and update button color
    });
  }

  @override
  void dispose() {
    _usernameController.removeListener(_updateButtonColor);
    _passwordController.removeListener(_updateButtonColor);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToPrivacy) {
      setState(() {
        _errorMessage = 'Anda harus menyetujui Kebijakan Privasi';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
          'Debug: Mencoba login dengan email: ${_usernameController.text.trim()}');

      final data = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      print('Debug: Login berhasil, data: $data');

      // Simpan data user
      final prefs = await SharedPreferences.getInstance();

      // Jika data user ada dalam response, simpan
      if (data['data'] != null) {
        await prefs.setString('user_data', jsonEncode(data['data']));
      } else {
        // Jika tidak ada data user dalam response, ambil dari API dashboard
        try {
          final token = data['access_token'];
          if (token != null) {
            print('Debug: Mengambil data user dari dashboard...');
            final dashboardData = await ApiService.getDashboardData(token);

            if (dashboardData['data'] != null) {
              await prefs.setString(
                  'user_data', jsonEncode(dashboardData['data']));
            }
          }
        } catch (e) {
          print('Error fetching user data: $e');
        }
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Debug: Error login: $e');
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Handle specific network errors
      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('No address associated with hostname')) {
        errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      } else if (errorMessage.contains('401') || errorMessage.contains('403')) {
        errorMessage = 'Email atau kata sandi salah.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isFormValid() {
    return _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          const Text(
            'Nama Pengguna',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Masukkan Nama pengguna',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: validateEmail,
          ),
          const SizedBox(height: 20),

          // Password Field
          const Text(
            'Kata Sandi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Masukkan Kata Sandi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kata sandi tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Checkboxes and Links
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepMeLoggedIn,
                      onChanged: (value) {
                        setState(() {
                          _keepMeLoggedIn = value ?? false;
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                    const Text(
                      'Biarkan saya tetap masuk',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Lupa Kata Sandi?',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Checkbox(
                value: _agreeToPrivacy,
                onChanged: (value) {
                  setState(() {
                    _agreeToPrivacy = value ?? false;
                  });
                },
                activeColor: Colors.orange,
              ),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                          text:
                              'Saya menyetujui dan menerima kebijakan privasi'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ),

          if (_errorMessage != null) const SizedBox(height: 16),

          // Login Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isFormValid() ? Colors.orange : Colors.grey[300],
                foregroundColor: _isFormValid() ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Separator
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Atau',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 24),

          // Google Login Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.g_mobiledata,
                  size: 24, color: Colors.orange),
              label: const Text(
                'Login Dengan Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Other Login Methods Button
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Login Dengan Cara Lain',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
