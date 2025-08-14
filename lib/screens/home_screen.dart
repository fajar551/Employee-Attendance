import 'dart:convert'; // Added for base64Encode
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _imageFile;
  File? _jamMasukFile;
  File? _jamKeluarFile;
  String? _tanggalAbsenTerakhir;
  final ImagePicker _picker = ImagePicker();
  DateTime? _lastAttendanceTime;
  int? _todayFlag; // null = belum absen, 1 = sudah masuk, 2 = sudah keluar
  List<Map<String, dynamic>> _attendanceHistory = [];
  String? _authToken; // Token untuk API
  Position? _currentPosition; // Posisi saat ini
  bool _isLoading = false; // Loading state
  bool _isLoadingHistory = false; // Loading state untuk history
  Map<String, dynamic>? _userData; // Data user dari login
  final bool _showAllHistory = false;
  bool _showHistorySection = true;

  @override
  void initState() {
    super.initState();
    _lastAttendanceTime = DateTime.now();
    _checkDeveloperMode();
    _loadAttendancePhotos();
    _loadAuthToken(); // Hanya load, tidak auto login
  }

  void _updateTodayFlag() {
    final today = DateTime.now().toString().substring(0, 10); // yyyy-MM-dd
    final todayAbsensi = _attendanceHistory
        .where((item) =>
            item['waktu_absen'] != null &&
            item['waktu_absen'].toString().startsWith(today))
        .toList();

    print('Debug: todayAbsensi: $todayAbsensi');

    if (todayAbsensi.isEmpty) {
      _todayFlag = null;
    } else {
      // Ambil flag terbesar hari ini (1 = masuk, 2 = keluar)
      final flags = todayAbsensi
          .map((e) => (e['flag'] is int)
              ? e['flag']
              : int.tryParse(e['flag'].toString()) ?? 1)
          .toList();
      _todayFlag = flags.fold<int>(1, (prev, el) => el > prev ? el : prev);
    }
    print('Debug: _todayFlag:  [32m [1m [4m$_todayFlag [0m');
  }

  Future<void> _checkDeveloperMode() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      const platform = MethodChannel('developer_mode_check');
      final isDevMode =
          await platform.invokeMethod<bool>('isDeveloperMode') ?? false;
      // Hapus redirect ke login, hanya simpan status developer mode
      print('Debug: Developer mode status: $isDevMode');
    } catch (e) {
      print('Error checking developer mode: $e');
    }
  }

  // Load token dari SharedPreferences atau storage lainnya
  Future<void> _loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    // Token akan diambil dari login yang sebenarnya, tidak di hardcode

    // Load data user juga
    await _loadUserData();
    if (_authToken == null || _userData == null) {
      // Redirect ke login jika tidak ada token/user
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      await _loadAttendanceHistory();
      if (_userData == null || _userData!['name'] == null) {
        await _loadUserDataFromAPI();
      }
    }
  }

  // Function untuk menyimpan token ke SharedPreferences
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    setState(() {
      _authToken = token;
    });
  }

  // Function untuk menyimpan data user ke SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
    setState(() {
      _userData = userData;
    });
  }

  // Function untuk load data user dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    final authToken = prefs.getString('auth_token');
    final userEmail = prefs.getString('user_email');

    print('Debug: Loaded from SharedPreferences:');
    print('Debug: - auth_token: ${authToken != null ? "ADA" : "TIDAK ADA"}');
    print('Debug: - user_email: $userEmail');
    print(
        'Debug: - user_data: ${userDataString != null ? "ADA" : "TIDAK ADA"}');

    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);

        // Normalize data jika menggunakan field 'nama'
        Map<String, dynamic> normalizedUserData =
            Map<String, dynamic>.from(userData);
        if (userData['nama'] != null && userData['name'] == null) {
          normalizedUserData['name'] = userData['nama'];
        }

        setState(() {
          _userData = normalizedUserData;
        });
        print('Debug: Parsed user data: $normalizedUserData');
      } catch (e) {
        print('Debug: Error parsing user data: $e');
      }
    }
  }

  // Function untuk mengambil data history absensi dari API
  Future<void> _loadAttendanceHistory() async {
    if (_authToken == null || _authToken!.isEmpty) {
      print('Debug: Token tidak ada, tidak bisa load history');
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      print('Debug: Loading attendance history...');

      final responseData = await ApiService.getAttendanceHistory(_authToken!);

      print('Debug: History response data: $responseData');

      final data = responseData['data'];

      // Convert API data ke format yang sesuai dengan UI
      List<Map<String, dynamic>> historyList = [];

      // Iterate through each day
      data.forEach((dayName, dayData) {
        final absensiList = dayData['absensi'] as List;

        // Convert each attendance record
        for (var absensi in absensiList) {
          final waktuAbsen = DateTime.parse(absensi['waktu_absen']);

          historyList.add({
            'date': _formatDate(waktuAbsen),
            'time': _formatTime(waktuAbsen),
            'hasLocation': true, // Semua data dari API memiliki lokasi
            'status': 'Telah diproses',
            'imageFile': null, // Foto disimpan di server, tidak di local
            'foto_url': absensi['foto'], // URL foto dari server
            'latitude': absensi['latitude'],
            'longitude': absensi['longitude'],
            'waktu_absen': absensi['waktu_absen'],
            'flag': (absensi['flag'] is int)
                ? absensi['flag']
                : int.tryParse(absensi['flag'].toString()) ?? 1,
          });

          // Debug print untuk foto
          print('Debug: Foto URL: ${absensi['foto']}');
          print(
              'Debug: Full Foto URL: https://hris.qwords.com/backend/public/uploads/absensi/${absensi['foto']}');
        }
      });

      // Sort by date (newest first)
      historyList.sort((a, b) {
        final dateA = DateTime.parse(a['waktu_absen']);
        final dateB = DateTime.parse(b['waktu_absen']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _attendanceHistory = historyList;
      });
      _updateTodayFlag();

      print('Debug: History loaded successfully. Count: ${historyList.length}');
    } catch (e) {
      print('Debug: Error loading history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveAttendancePhoto(bool isMasuk, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    if (isMasuk) {
      await prefs.setString('foto_jam_masuk', imagePath);
    } else {
      await prefs.setString('foto_jam_keluar', imagePath);
    }
    await prefs.setString('tanggal_absen_terakhir', today);
    setState(() {
      if (isMasuk) {
        _jamMasukFile = File(imagePath);
      } else {
        _jamKeluarFile = File(imagePath);
      }
      _tanggalAbsenTerakhir = today;
    });
  }

  Future<void> _loadAttendancePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final lastDate = prefs.getString('tanggal_absen_terakhir');
    if (lastDate != today) {
      // Reset foto jika sudah beda hari
      await prefs.remove('foto_jam_masuk');
      await prefs.remove('foto_jam_keluar');
      await prefs.setString('tanggal_absen_terakhir', today);
      setState(() {
        _jamMasukFile = null;
        _jamKeluarFile = null;
        _tanggalAbsenTerakhir = today;
      });
    } else {
      setState(() {
        _jamMasukFile = prefs.getString('foto_jam_masuk') != null
            ? File(prefs.getString('foto_jam_masuk')!)
            : null;
        _jamKeluarFile = prefs.getString('foto_jam_keluar') != null
            ? File(prefs.getString('foto_jam_keluar')!)
            : null;
        _tanggalAbsenTerakhir = lastDate;
      });
    }
  }

  Future<void> _pickImage() async {
    // Simpan context dan mounted check sebelum async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isMounted = mounted;

    try {
      // Cek developer mode sebelum async gap
      const platform = MethodChannel('developer_mode_check');
      final isDevMode =
          await platform.invokeMethod<bool>('isDeveloperMode') ?? false;

      if (isDevMode && mounted) {
        // Panggil showDialog dengan context yang valid
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Peringatan'),
              content: const Text(
                  'Tidak bisa absen karena Developer Mode/USB Debugging aktif. Silakan matikan Developer Mode.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
        return;
      }

      // Set loading state
      if (isMounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Ambil foto dari kamera
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null && isMounted) {
        // Gunakan file langsung tanpa rotasi EXIF
        final File imageFile = File(pickedFile.path);
        setState(() {
          _imageFile = imageFile;
          _lastAttendanceTime = DateTime.now();
        });

        // Ambil lokasi terlebih dahulu
        await _getLocation();

        // Kirim data ke API
        bool success = await _sendAttendanceToAPI();

        if (success && isMounted) {
          // Cek flag terbaru setelah reload history
          await _loadAttendanceHistory();
          // Cari absensi hari ini setelah update history
          final today = DateTime.now().toString().substring(0, 10);
          final absensiMasuk = _attendanceHistory.firstWhere(
            (item) =>
                item['waktu_absen'].toString().startsWith(today) &&
                item['flag'] == 1,
            orElse: () => {},
          );
          final absensiKeluar = _attendanceHistory.firstWhere(
            (item) =>
                item['waktu_absen'].toString().startsWith(today) &&
                item['flag'] == 2,
            orElse: () => {},
          );

          // Simpan foto ke local sesuai flag yang baru saja direkam
          if (absensiKeluar.isNotEmpty &&
              absensiKeluar['waktu_absen'] != null &&
              absensiKeluar['foto_url'] != null) {
            // Baru saja absen keluar
            await _saveAttendancePhoto(false, imageFile.path);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Jam Keluar berhasil direkam!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (absensiMasuk.isNotEmpty &&
              absensiMasuk['waktu_absen'] != null &&
              absensiMasuk['foto_url'] != null) {
            // Baru saja absen masuk
            await _saveAttendancePhoto(true, imageFile.path);
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Jam Masuk berhasil direkam!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Fallback
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Absensi berhasil direkam!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Tampilkan pesan error yang spesifik
      String errorMessage = 'Terjadi kesalahan saat absensi';

      if (e.toString().contains('diluar jangkauan') ||
          e.toString().contains('jangkauan kantor')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('Gagal mengirim data absensi')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      }

      if (isMounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(
                seconds: 5), // Tampilkan lebih lama untuk pesan error
          ),
        );
      }
    } finally {
      // Reset loading state
      if (isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        'flag': (_todayFlag == null || _todayFlag == 1) ? '1' : '2',
      };

      print('Debug: Sending data to API...');
      print('Debug: Latitude: ${_currentPosition!.latitude}');
      print('Debug: Longitude: ${_currentPosition!.longitude}');
      print('Debug: Waktu Absen: $waktuAbsen');
      print('Debug: Foto length: ${fotoBase64.length}');

      // Kirim request ke API
      final responseData =
          await ApiService.sendAttendance(_authToken!, requestData);

      print('Debug: Response data: $responseData');

      // Berhasil
      print('Absensi berhasil dikirim: $responseData');
      return true;
    } catch (e) {
      print('Error saat mengirim absensi: $e');
      // Re-throw exception agar bisa ditangkap di _pickImage
      rethrow;
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

  // Function untuk membuat inisial dari nama user
  String _getUserInitials() {
    if (_userData == null) {
      return 'U'; // Default jika tidak ada data user
    }

    // Coba ambil dari field 'name' terlebih dahulu, lalu 'nama' sebagai fallback
    String? name = _userData!['name'] ?? _userData!['nama'];

    if (name == null || name.toString().trim().isEmpty) {
      return 'U';
    }

    String nameStr = name.toString().trim();
    if (nameStr.isEmpty) {
      return 'U';
    }

    List<String> nameParts = nameStr.split(' ');
    if (nameParts.length >= 2) {
      // Ambil huruf pertama dari nama depan dan nama belakang
      String firstInitial =
          nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';
      String lastInitial = nameParts[nameParts.length - 1].isNotEmpty
          ? nameParts[nameParts.length - 1][0].toUpperCase()
          : '';
      return '$firstInitial$lastInitial';
    } else if (nameParts.length == 1) {
      // Jika hanya satu kata, ambil 2 huruf pertama
      return nameStr.length >= 2
          ? nameStr.substring(0, 2).toUpperCase()
          : nameStr.toUpperCase();
    }

    return 'U';
  }

  // Function untuk mengambil data user dari API dashboard
  Future<void> _loadUserDataFromAPI() async {
    if (_authToken == null || _authToken!.isEmpty) {
      print('Debug: Token tidak ada, tidak bisa load user data');
      return;
    }

    try {
      print('Debug: Loading user data from API...');

      final responseData = await ApiService.getDashboardData(_authToken!);

      print('Debug: User data response data: $responseData');

      final userData = responseData['data'];

      if (userData != null && userData is Map<String, dynamic>) {
        // Konversi data dari API ke format yang konsisten
        Map<String, dynamic> normalizedUserData = {
          'id': userData['id']?.toString(),
          'email': userData['email'],
          'name': userData['nama'] ??
              userData[
                  'name'], // Gunakan 'nama' dari API atau fallback ke 'name'
        };

        // Pastikan data user memiliki field yang diperlukan
        if (normalizedUserData['name'] != null ||
            normalizedUserData['email'] != null) {
          await _saveUserData(normalizedUserData);
          print(
              'Debug: User data loaded successfully from API: $normalizedUserData');
        } else {
          print('Debug: User data tidak lengkap, menggunakan fallback');
          await _createFallbackUserData();
        }
      } else {
        print(
            'Debug: User data tidak ada dalam response, menggunakan fallback');
        await _createFallbackUserData();
      }
    } catch (e) {
      print('Debug: Error loading user data: $e');
      // Jika gagal load dari API, gunakan fallback
      await _createFallbackUserData();
    }
  }

  // Function untuk membuat data user fallback
  Future<void> _createFallbackUserData() async {
    // Ambil email dari SharedPreferences jika ada
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');

    print('Debug: Creating fallback user data with email: $savedEmail');

    Map<String, dynamic> fallbackData = {
      'name': 'Fajar Habib', // Default name yang lebih spesifik
      'email': savedEmail ??
          'fajar@qwords.com', // Gunakan email yang tersimpan atau default
      'id': '1', // Default ID
    };

    await _saveUserData(fallbackData);
    print('Debug: Created fallback user data: $fallbackData');
  }

  @override
  Widget build(BuildContext context) {
    final isTimeIn = _todayFlag == null || _todayFlag == 2;

    // Ambil absensi hari ini dari history
    final today = DateTime.now().toString().substring(0, 10);
    final absensiMasuk = _attendanceHistory.firstWhere(
      (item) =>
          item['waktu_absen'].toString().startsWith(today) && item['flag'] == 1,
      orElse: () => {},
    );
    final absensiKeluar = _attendanceHistory.firstWhere(
      (item) =>
          item['waktu_absen'].toString().startsWith(today) && item['flag'] == 2,
      orElse: () => {},
    );

    // Untuk foto dan jam masuk
    Widget jamMasukFoto = _jamMasukFile != null
        ? ClipOval(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Image.file(_jamMasukFile!,
                  fit: BoxFit.cover, width: 60, height: 60),
            ),
          )
        : (absensiMasuk.isNotEmpty && absensiMasuk['foto_url'] != null
            ? ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Image.network(
                    'https://hris.qwords.com/backend/public/uploads/absensi/${absensiMasuk['foto_url']}',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Debug: Error loading image: $error');
                      print(
                          'Debug: Attempted URL: https://hris.qwords.com/backend/public/uploads/absensi/${absensiMasuk['foto_url']}');
                      return Text(
                        _getUserInitials(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              )
            : Text(_getUserInitials(),
                style: const TextStyle(fontWeight: FontWeight.bold)));
    String jamMasukWaktu =
        (absensiMasuk.isNotEmpty && absensiMasuk['waktu_absen'] != null)
            ? _formatTime(DateTime.parse(absensiMasuk['waktu_absen']))
            : '--:--';

    // Untuk foto dan jam keluar
    Widget jamKeluarFoto = _jamKeluarFile != null
        ? ClipOval(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Image.file(_jamKeluarFile!,
                  fit: BoxFit.cover, width: 60, height: 60),
            ),
          )
        : (absensiKeluar.isNotEmpty && absensiKeluar['foto_url'] != null
            ? ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Image.network(
                    'https://hris.qwords.com/backend/public/uploads/absensi/${absensiKeluar['foto_url']}',
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Debug: Error loading image: $error');
                      print(
                          'Debug: Attempted URL: https://hris.qwords.com/backend/public/uploads/absensi/${absensiKeluar['foto_url']}');
                      return Text(
                        _getUserInitials(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              )
            : Text(_getUserInitials(),
                style: const TextStyle(fontWeight: FontWeight.bold)));
    String jamKeluarWaktu =
        (absensiKeluar.isNotEmpty && absensiKeluar['waktu_absen'] != null)
            ? _formatTime(DateTime.parse(absensiKeluar['waktu_absen']))
            : '--:--';

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
              padding: const EdgeInsets.all(12),
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
                      children: [
                        Text(
                          _userData?['name'] ??
                              _userData?['nama'] ??
                              'Loading...',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _userData?['email'] ??
                              _userData?['id'] ??
                              'Loading...',
                          style: const TextStyle(color: Colors.grey),
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
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13), // abu-abu transparan
                    blurRadius: 32,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hari ini (${_formatDate(DateTime.now())})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text('Shift: Regular 1 [08:00 - 17:00]',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  // Tambahkan garis bawah setelah shift
                  const Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    child: Divider(
                      height: 2,
                      thickness: 2,
                      color: Color(0xFFE0E0E0),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
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
                                      color: Colors.green.withOpacity(0.10),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.green[50],
                                  child: jamMasukFoto,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Jam Masuk',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87)),
                              Text(
                                jamMasukWaktu,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green),
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
                        // Garis vertikal di tengah
                        Container(
                          width: 2,
                          height: 70,
                          color: const Color(0xFFE0E0E0),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
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
                                      color: Colors.red.withOpacity(0.10),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.red[50],
                                  child: jamKeluarFoto,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text('Jam Keluar',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black87)),
                              Text(
                                jamKeluarWaktu,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.red),
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
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF18222),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 5, // bayangan di button rekam waktu
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 255, 255, 255)),
                            ),
                    ),
                  ),
                  if (!_showHistorySection)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showHistorySection = true;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  color: Color(0xFFF18222),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.expand_more,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_showHistorySection) ...[
                    const Divider(
                        height: 28, thickness: 1, color: Color(0xFFF2F2F2)),
                    // Riwayat Absensi
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Riwayat Absensi',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            // Refresh button
                            IconButton(
                              onPressed: _isLoadingHistory
                                  ? null
                                  : _loadAttendanceHistory,
                              icon: _isLoadingHistory
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildFilterTab('All', true),
                            const SizedBox(width: 8),
                            _buildFilterTab('Offline 3', false),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingHistory)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_attendanceHistory.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: Text(
                                'Belum ada riwayat absensi',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else ...[
                          ...(_showAllHistory
                                  ? _attendanceHistory
                                  : _attendanceHistory.take(5).toList())
                              .map((record) {
                            print(
                                'Debug: Building history item with foto_url:  [32m${record['foto_url']} [0m');
                            return _buildAttendanceHistoryItem(
                              record['date'],
                              record['time'],
                              record['hasLocation'],
                              record['status'],
                              record['imageFile'],
                              record['foto_url'],
                            );
                          }),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _showHistorySection = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sembunyikan Detail',
                                    style: TextStyle(
                                      color: Color(0xFFF18222),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.expand_less,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Menu Favorit Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Menu Favorit',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFavoriteMenuItem(
                              Icons.receipt_long, 'Slip Gaji Saya', [
                            const Color(0xFFFEF6E0),
                            const Color(0xFFFFE0B2)
                          ]),
                          _buildFavoriteMenuItem(
                              Icons.event_note, 'Aktivitas Harian', [
                            const Color(0xFFE0F7FA),
                            const Color(0xFFB2EBF2)
                          ]),
                          _buildFavoriteMenuItem(
                              Icons.chat_bubble_outline, 'Obrolan', [
                            const Color(0xFFEDE7F6),
                            const Color(0xFFD1C4E9)
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info Perusahaan Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Perusahaan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Center(
                        child: Icon(Icons.insert_drive_file,
                            size: 48, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Belum ada informasi',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
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
      String status, File? imageFile, String? fotoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(6),
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
                  : fotoUrl != null
                      ? ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Image.network(
                              'https://hris.qwords.com/backend/public/uploads/absensi/$fotoUrl',
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Debug: Error loading image: $error');
                                print(
                                    'Debug: Attempted URL: https://hris.qwords.com/backend/public/uploads/absensi/$fotoUrl');
                                return Text(
                                  _getUserInitials(),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                      : Text(
                          _getUserInitials(),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
        selectedItemColor: const Color(0xFFF18222),
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // Home tab is selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Fitur'),
          BottomNavigationBarItem(
              icon: Icon(Icons.article), label: 'Postingan'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Ruang Kerja'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacementNamed(context, '/features');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/posts');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/workspace');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
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
            'Keluar',
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
                backgroundColor: const Color(0xFFF18222),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    // Clear semua data user
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('user_email');

    // Navigate back to login screen
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  Widget _buildFavoriteMenuItem(
      IconData icon, String label, List<Color> gradientColors) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.deepOrange, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
