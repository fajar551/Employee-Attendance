import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../utils/validators.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _keepMeLoggedIn = true;
  bool _agreeToPrivacy = false;
  bool _isLoginMode = true; // true = login, false = register
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Add listeners to update button color in real-time
    _nameController.addListener(_updateButtonColor);
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
    _nameController.removeListener(_updateButtonColor);
    _usernameController.removeListener(_updateButtonColor);
    _passwordController.removeListener(_updateButtonColor);
    _nameController.dispose();
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
      final data = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

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
            final response = await http.get(
              Uri.parse(
                  'https://hris.qwords.com/backend/public/api/dashboardAndroid'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );

            if (response.statusCode == 200) {
              final dashboardData = jsonDecode(response.body);
              if (dashboardData['data'] != null) {
                await prefs.setString(
                    'user_data', jsonEncode(dashboardData['data']));
              }
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
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
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
      final data = await AuthService.register(
        _nameController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      // Simpan data user
      final prefs = await SharedPreferences.getInstance();
      if (data['data'] != null) {
        await prefs.setString('user_data', jsonEncode(data['data']));
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
      // Clear form when switching modes
      if (_isLoginMode) {
        _nameController.clear();
      }
    });
  }

  bool _isFormValid() {
    if (_isLoginMode) {
      return _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    } else {
      return _nameController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isLoginMode) _toggleMode();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            _isLoginMode ? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Masuk',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isLoginMode ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLoginMode) _toggleMode();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            !_isLoginMode ? Colors.orange : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Daftar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              !_isLoginMode ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Name Field (only for register)
          if (!_isLoginMode) ...[
            const Text(
              'Nama Lengkap',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama lengkap',
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Email Field
          Text(
            _isLoginMode ? 'Nama Pengguna' : 'Email',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText:
                  _isLoginMode ? 'Masukkan Nama pengguna' : 'Masukkan email',
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
            validator: _isLoginMode
                ? validateEmail
                : (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Email tidak valid';
                    }
                    return null;
                  },
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
            validator: _isLoginMode
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kata sandi tidak boleh kosong';
                    }
                    return null;
                  }
                : validatePassword,
          ),
          const SizedBox(height: 20),

          // Checkboxes and Links
          if (_isLoginMode) ...[
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
          ],

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

          // Login/Register Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed:
                  _isLoading ? null : (_isLoginMode ? _login : _register),
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
                  : Text(
                      _isLoginMode ? 'Masuk' : 'Daftar',
                      style: const TextStyle(
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
              label: Text(
                _isLoginMode ? 'Login Dengan Google' : 'Daftar Dengan Google',
                style: const TextStyle(
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
              child: Text(
                _isLoginMode
                    ? 'Login Dengan Cara Lain'
                    : 'Daftar Dengan Cara Lain',
                style: const TextStyle(
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
