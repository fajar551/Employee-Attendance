import 'dart:convert'; // Added for base64Encode
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // Added for http
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastAttendanceTime;
  final bool _isTimeIn = true; // true = jam masuk, false = jam keluar
  List<Map<String, dynamic>> _attendanceHistory = [];
  String? _authToken; // Token untuk API
  Position? _currentPosition; // Posisi saat ini
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _lastAttendanceTime = DateTime.now();
    _loadAuthToken(); // Load token dari storage
    _autoLogin(); // Auto login jika token tidak ada
    // Data dummy untuk riwayat absensi
    _attendanceHistory = [
      {
        'date': 'Sel, 22 Jul 2025',
        'time': '08:51',
        'hasLocation': true,
        'status': 'Telah diproses',
        'imageFile': null, // Data lama tidak punya foto
      },
      {
        'date': 'Sen, 21 Jul 2025',
        'time': '18:02',
        'hasLocation': true,
        'status': 'Telah diproses',
        'imageFile': null,
      },
      {
        'date': 'Sen, 21 Jul 2025',
        'time': '08:50',
        'hasLocation': true,
        'status': 'Telah diproses',
        'imageFile': null,
      },
      {
        'date': 'Jul 15, 2025',
        'time': '18:04',
        'hasLocation': false,
        'status': 'Offline',
        'imageFile': null,
      },
      {
        'date': 'Jul 14, 2025',
        'time': '10:05',
        'hasLocation': false,
        'status': 'Offline',
        'imageFile': null,
      },
    ];
  }

  // Load token dari SharedPreferences atau storage lainnya
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    // Token akan diambil dari login yang sebenarnya, tidak di hardcode
  }

  // Function untuk menyimpan token ke SharedPreferences
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    setState(() {
      _authToken = token;
    });
  }

  // Function untuk clear token
  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    setState(() {
      _authToken = null;
    });
  }

  // Function untuk login dan mendapatkan token
  Future<bool> _loginAndGetToken(String email, String password) async {
    try {
      print('Debug: Attempting login with email: $email');

      final response = await http.post(
        Uri.parse('https://absensi.qwords.com/backend/public/api/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Debug: Login response status: ${response.statusCode}');
      print('Debug: Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Debug: Response data: $responseData');

        // Cek field access_token (bukan token)
        if (responseData['access_token'] != null) {
          await _saveAuthToken(responseData['access_token']);
          print(
              'Debug: Access token saved successfully: ${responseData['access_token']}');
          return true;
        } else {
          print('Debug: No access_token in response');
          return false;
        }
      } else {
        print('Debug: Login failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Debug: Error saat login: $e');
      return false;
    }
  }

  // Auto login jika token tidak ada
  Future<void> _autoLogin() async {
    await Future.delayed(const Duration(seconds: 2)); // Tunggu sebentar
    if (_authToken == null || _authToken!.isEmpty) {
      print('Debug: Auto login karena token kosong...');
      bool success = await _loginAndGetToken("admin@gmail.com", "admin123");
      if (success) {
        print('Debug: Auto login berhasil');
      } else {
        print('Debug: Auto login gagal');
      }
    } else {
      print('Debug: Token sudah ada, tidak perlu auto login');
    }
  }

  Future<void> _pickImage() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Set loading state
      setState(() {
        _isLoading = true;
      });

      // Ambil foto dari kamera
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _lastAttendanceTime = DateTime.now();
        });

        // Ambil lokasi terlebih dahulu
        await _getLocation();

        // Kirim data ke API
        bool success = await _sendAttendanceToAPI();

        if (success) {
          // Tambahkan data absensi baru ke riwayat
          _addAttendanceRecord();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                  '${_isTimeIn ? "Jam Masuk" : "Jam Keluar"} berhasil direkam!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Gagal mengirim data absensi. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addAttendanceRecord() {
    final now = DateTime.now();
    final newRecord = {
      'date': _formatDate(now),
      'time': _formatTime(now),
      'hasLocation': true,
      'status': 'Telah diproses',
      'imageFile': _imageFile, // Tambahkan foto ke data
    };

    setState(() {
      _attendanceHistory.insert(0, newRecord); // Tambahkan di awal list
    });
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = pos;
      });
      await _getAddressFromCoordinates(pos);
    } catch (e) {
      // Handle error silently or show snackbar if needed
    }
  }

  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        // Address obtained but not used in UI
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Function untuk mengirim data absensi ke API
  Future<bool> _sendAttendanceToAPI() async {
    if (_authToken == null || _currentPosition == null || _imageFile == null) {
      print(
          'Debug: Token: $_authToken, Position: $_currentPosition, Image: $_imageFile');
      return false;
    }

    try {
      // Convert foto ke base64
      List<int> imageBytes = await _imageFile!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      String fotoBase64 = "data:image/png;base64,$base64Image";

      // Format waktu absen
      String waktuAbsen = DateTime.now().toString().substring(0, 19);

      // Data yang akan dikirim ke API
      Map<String, dynamic> requestData = {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'foto': fotoBase64,
        'waktu_absen': waktuAbsen,
      };

      print('Debug: Sending data to API...');
      print('Debug: Latitude: ${_currentPosition!.latitude}');
      print('Debug: Longitude: ${_currentPosition!.longitude}');
      print('Debug: Waktu Absen: $waktuAbsen');
      print('Debug: Foto length: ${fotoBase64.length}');

      // Kirim request ke API
      final response = await http.post(
        Uri.parse('https://absensi.qwords.com/backend/public/api/absensi'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Debug: Response status: ${response.statusCode}');
      print('Debug: Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Berhasil
        print('Absensi berhasil dikirim: ${response.body}');
        return true;
      } else {
        // Gagal
        print(
            'Gagal mengirim absensi. Status: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saat mengirim absensi: $e');
      return false;
    }
  }

  // Function untuk test API tanpa foto
  Future<bool> _testAPI() async {
    try {
      // Ambil lokasi terlebih dahulu
      await _getLocation();

      if (_currentPosition == null) {
        print('Debug: Tidak bisa mendapatkan lokasi');
        return false;
      }

      // Data test tanpa foto
      Map<String, dynamic> testData = {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'foto':
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', // 1x1 pixel transparent PNG
        'waktu_absen': DateTime.now().toString().substring(0, 19),
      };

      print('Debug: Testing API with data: $testData');

      final response = await http.post(
        Uri.parse('https://absensi.qwords.com/backend/public/api/absensi'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(testData),
      );

      print('Debug: Test response status: ${response.statusCode}');
      print('Debug: Test response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Debug: Test API error: $e');
      return false;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    List<String> days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PT Qwords Company Intern...',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _showLogoutDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                    child:
                        const Icon(Icons.person, size: 30, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Fajar Habib Zaelani',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Full Stack Developer',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Attendance Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hari ini (${_formatDate(DateTime.now())})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Shift: Regular 1 [08:00 - 17:00]'),
                  const SizedBox(height: 16),

                  // Time In/Out Section
                  Row(
                    children: [
                      // Time In
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                child: _imageFile != null && _isTimeIn
                                    ? ClipOval(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: Image.file(_imageFile!,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60),
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        size: 30, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Jam Masuk',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              _lastAttendanceTime != null &&
                                      _isTimeIn &&
                                      _imageFile != null
                                  ? _formatTime(_lastAttendanceTime!)
                                  : '--:--',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on,
                                    size: 12, color: Colors.green[600]),
                                const SizedBox(width: 4),
                                const Text('Lokasi',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Time Out
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                child: _imageFile != null && !_isTimeIn
                                    ? ClipOval(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: Image.file(_imageFile!,
                                              fit: BoxFit.cover,
                                              width: 60,
                                              height: 60),
                                        ),
                                      )
                                    : const Text('FH',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Jam Keluar',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              _lastAttendanceTime != null &&
                                      !_isTimeIn &&
                                      _imageFile != null
                                  ? _formatTime(_lastAttendanceTime!)
                                  : '--:--',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on,
                                    size: 12, color: Colors.red[600]),
                                const SizedBox(width: 4),
                                const Text('Lokasi',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Record Time Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Mengirim...',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            )
                          : const Text(
                              'Rekam Waktu',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Test API Button (untuk debugging)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });

                              bool success = await _testAPI();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Test API berhasil!'
                                      : 'Test API gagal!'),
                                  backgroundColor:
                                      success ? Colors.green : Colors.red,
                                ),
                              );

                              setState(() {
                                _isLoading = false;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Test API',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Test Login Button (untuk debugging)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        bool success = await _loginAndGetToken("admin@gmail.com", "admin123");
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Login berhasil! Token: $_authToken' : 'Login gagal!'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Test Login',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Clear Token Button (untuk debugging)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        await _clearAuthToken();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Token berhasil dihapus!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Clear Token',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Attendance History
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Absensi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Filter Tabs
                  Row(
                    children: [
                      _buildFilterTab('All', true),
                      const SizedBox(width: 8),
                      _buildFilterTab('Offline 3', false),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Attendance History List
                  ..._attendanceHistory
                      .map((record) => _buildAttendanceHistoryItem(
                            record['date'],
                            record['time'],
                            record['hasLocation'],
                            record['status'],
                            record['imageFile'], // Pass foto ke widget
                          ))
                      .toList(),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFilterTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange[100] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.orange[700] : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (title == 'Offline 3') ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '3',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceHistoryItem(String date, String time, bool hasLocation,
      String status, File? imageFile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Foto absensi dengan shadow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: imageFile != null
                  ? ClipOval(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          width: 40,
                          height: 40,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.grey, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Text(time),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: hasLocation ? Colors.green[600] : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Offline' ? Colors.red[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'Offline')
                  Icon(Icons.error, size: 12, color: Colors.red[600]),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: status == 'Offline'
                        ? Colors.red[600]
                        : Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Fitur'),
          BottomNavigationBarItem(
              icon: Icon(Icons.article), label: 'Postingan'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Ruang Kerja'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    _clearAuthToken(); // Clear token sebelum keluar
    // Navigate back to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
