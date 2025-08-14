import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true; // State untuk toggle tampilan
  int _sisaCuti = 0; // Sisa cuti dari API
  bool _isLoadingSisaCuti = false; // Loading state untuk sisa cuti

  // Data semua fitur - inisialisasi langsung
  final List<Map<String, dynamic>> _allFeatures = [
    // Waktu Kehadiran
    {
      'name': 'Daftar Kehadiran',
      'icon': Icons.person,
      'backgroundColor': Colors.green[100],
      'iconColor': Colors.green[700],
      'category': 'Waktu Kehadiran',
    },
    {
      'name': 'Permintaan Koreksi Kehadiran',
      'icon': Icons.access_time,
      'backgroundColor': Colors.green[100],
      'iconColor': Colors.green[700],
      'category': 'Waktu Kehadiran',
    },
    {
      'name': 'Jadwal Shift',
      'icon': Icons.calendar_today,
      'backgroundColor': Colors.green[100],
      'iconColor': Colors.green[700],
      'category': 'Waktu Kehadiran',
    },
    {
      'name': 'Minta Jadwal Shift',
      'icon': Icons.calendar_view_week,
      'backgroundColor': Colors.green[100],
      'iconColor': Colors.green[700],
      'category': 'Waktu Kehadiran',
    },

    // Cuti
    {
      'name': 'Permintaan Cuti',
      'icon': Icons.description,
      'backgroundColor': Colors.blue[100],
      'iconColor': Colors.blue[700],
      'category': 'Cuti',
    },
    {
      'name': 'Jatah Cuti',
      'icon': Icons.description,
      'backgroundColor': Colors.blue[100],
      'iconColor': Colors.blue[700],
      'category': 'Cuti',
      'hasNotification': true, // Akan diupdate secara dinamis
      'notificationCount': 2, // Akan diupdate secara dinamis
    },
    {
      'name': 'Kalendar Cuti',
      'icon': Icons.calendar_month,
      'backgroundColor': Colors.blue[100],
      'iconColor': Colors.blue[700],
      'category': 'Cuti',
    },

    // Lembur
    {
      'name': 'Laporan Karyawan Lembur',
      'icon': Icons.description,
      'backgroundColor': Colors.purple[100],
      'iconColor': Colors.purple[700],
      'category': 'Lembur',
    },
    {
      'name': 'Laporan Permintaan Lembur',
      'icon': Icons.description,
      'backgroundColor': Colors.purple[100],
      'iconColor': Colors.purple[700],
      'category': 'Lembur',
    },
    {
      'name': 'Laporan Pembatalan Lembur',
      'icon': Icons.description,
      'backgroundColor': Colors.purple[100],
      'iconColor': Colors.purple[700],
      'category': 'Lembur',
    },

    // Perjalanan Bisnis
    {
      'name': 'Permintaan Perjalanan',
      'icon': Icons.work,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Perjalanan Bisnis',
    },
    {
      'name': 'Laporan Perjalanan',
      'icon': Icons.description,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Perjalanan Bisnis',
    },
  ];

  // Inisialisasi _filteredFeatures langsung
  var _filteredFeatures = <Map<String, dynamic>>[];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    print('Debug: initState called');

    // Gunakan addPostFrameCallback untuk memastikan widget sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Debug: Post frame callback executed');
      _initializeFeatures();
      _loadSisaCuti(); // Load sisa cuti dari API
    });

    print('Debug: initState completed');
  }

  // Function untuk mengambil sisa cuti dari API
  Future<void> _loadSisaCuti() async {
    setState(() {
      _isLoadingSisaCuti = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('Debug: Token tidak ditemukan');
        return;
      }

      final responseData = await ApiService.getSisaCuti(token);

      if (responseData['data'] != null) {
        setState(() {
          _sisaCuti = responseData['data'] ?? 0;
        });
        print('Debug: Sisa cuti loaded: $_sisaCuti');

        // Update features setelah data sisa cuti dimuat
        _updateJatahCutiData();
      } else {
        print('Debug: Error loading sisa cuti. Response: $responseData');
      }
    } catch (e) {
      print('Error loading sisa cuti: $e');
    } finally {
      setState(() {
        _isLoadingSisaCuti = false;
      });
    }
  }

  // Function untuk memperbarui data Jatah Cuti
  void _updateJatahCutiData() {
    // Update data Jatah Cuti dengan data dinamis
    for (int i = 0; i < _allFeatures.length; i++) {
      if (_allFeatures[i]['name'] == 'Jatah Cuti') {
        _allFeatures[i]['hasNotification'] = _sisaCuti > 0;
        _allFeatures[i]['notificationCount'] = _sisaCuti;
        break;
      }
    }

    // Update filtered features juga
    for (int i = 0; i < _filteredFeatures.length; i++) {
      if (_filteredFeatures[i]['name'] == 'Jatah Cuti') {
        _filteredFeatures[i]['hasNotification'] = _sisaCuti > 0;
        _filteredFeatures[i]['notificationCount'] = _sisaCuti;
        break;
      }
    }

    setState(() {
      // Trigger rebuild untuk menampilkan data terbaru
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFeatures() {
    print('Debug: Initializing features...');

    // Tambahkan onTap callback ke setiap fitur
    for (int i = 0; i < _allFeatures.length; i++) {
      _allFeatures[i]['onTap'] =
          () => _showFeatureInfo(_allFeatures[i]['name']);
    }

    // Update data Jatah Cuti dengan data dinamis
    for (int i = 0; i < _allFeatures.length; i++) {
      if (_allFeatures[i]['name'] == 'Jatah Cuti') {
        _allFeatures[i]['hasNotification'] = _sisaCuti > 0;
        _allFeatures[i]['notificationCount'] =
            _isLoadingSisaCuti ? 0 : _sisaCuti;
        break;
      }
    }

    _filteredFeatures = List.from(_allFeatures);
    print('Debug: Features initialized. Total: ${_allFeatures.length}');
    print(
        'Debug: Feature names: ${_allFeatures.map((f) => f['name']).toList()}');
  }

  void _showFeatureInfo(String featureName) {
    if (featureName == 'Permintaan Cuti') {
      Navigator.pushNamed(context, '/izin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fitur "$featureName" akan segera tersedia.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _searchFeatures(String query) {
    print('Debug: Searching for: "$query"');
    print('Debug: Total features: ${_allFeatures.length}');
    print(
        'Debug: All feature names: ${_allFeatures.map((f) => f['name']).toList()}');

    if (query.trim().isNotEmpty) {
      setState(() {
        _isSearching = true;
        final searchQuery = query.trim().toLowerCase();

        _filteredFeatures = _allFeatures.where((feature) {
          final name = feature['name'] as String;
          final category = feature['category'] as String;

          final nameMatch = name.toLowerCase().contains(searchQuery);
          final categoryMatch = category.toLowerCase().contains(searchQuery);

          print(
              'Debug: Checking "$name" - nameMatch: $nameMatch, categoryMatch: $categoryMatch');

          return nameMatch || categoryMatch;
        }).toList();
      });

      print('Debug: Found ${_filteredFeatures.length} results');
      print(
          'Debug: Results: ${_filteredFeatures.map((f) => f['name']).toList()}');
    } else {
      setState(() {
        _isSearching = false;
        _filteredFeatures = List.from(_allFeatures);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Debug: Build method called');
    print('Debug: _allFeatures length: ${_allFeatures.length}');
    print('Debug: _filteredFeatures length: ${_filteredFeatures.length}');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Fitur',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView; // Toggle tampilan
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGridView
                      ? 'Tampilan Grid aktif'
                      : 'Tampilan List aktif'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  _searchFeatures(value);
                },
                decoration: InputDecoration(
                  hintText: 'Cari Fitur',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                ),
              ),
            ),

            // Tampilkan hasil pencarian atau tampilan normal
            _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildNormalView(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFeatureSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isGridView
                ? Row(
                    children: children
                        .map((child) => Expanded(child: child))
                        .toList(),
                  )
                : Column(
                    children: children
                        .map((child) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: child,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String label,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
    VoidCallback onTap, {
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _isGridView
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        if (hasNotification)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 100, // Width lebih besar agar kata pertama sejajar
                  height: 32, // Height konsisten untuk semua teks
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                      ),
                      if (hasNotification)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                notificationCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 14,
                  ),
                ),
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
        currentIndex: 1, // Fitur tab is selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Fitur'),
          BottomNavigationBarItem(
              icon: Icon(Icons.article), label: 'Postingan'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Ruang Kerja'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
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

  Widget _buildSearchResults() {
    print('Debug: Building search results');
    print('Debug: Filtered features count: ${_filteredFeatures.length}');
    print('Debug: Search text: "${_searchController.text}"');

    if (_filteredFeatures.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada fitur yang ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci yang berbeda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Kelompokkan hasil berdasarkan kategori
    Map<String, List<Map<String, dynamic>>> groupedResults = {};
    for (var feature in _filteredFeatures) {
      String category = feature['category'] as String;
      if (!groupedResults.containsKey(category)) {
        groupedResults[category] = [];
      }
      groupedResults[category]!.add(feature);
    }

    return Column(
      children: [
        // Header hasil pencarian
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Hasil Pencarian: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '"${_searchController.text}" (${_filteredFeatures.length} item)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Tampilkan hasil berdasarkan kategori
        ...groupedResults.entries.map((entry) {
          String category = entry.key;
          List<Map<String, dynamic>> features = entry.value;

          return _buildFeatureSection(
            category,
            features.map((feature) {
              return _buildFeatureItem(
                feature['name'] as String,
                feature['icon'] as IconData,
                feature['backgroundColor'] as Color,
                feature['iconColor'] as Color,
                feature['onTap'] as VoidCallback,
                hasNotification: feature['hasNotification'] as bool? ?? false,
                notificationCount: feature['notificationCount'] as int? ?? 0,
              );
            }).toList(),
          );
        }),

        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  Widget _buildNormalView() {
    return Column(
      children: [
        _buildFeatureSection(
          'Waktu Kehadiran',
          [
            _buildFeatureItem(
              'Daftar Kehadiran',
              Icons.person,
              Colors.green[100]!,
              Colors.green[700]!,
              () => _showFeatureInfo('Daftar Kehadiran'),
            ),
            _buildFeatureItem(
              'Permintaan Koreksi Kehadiran',
              Icons.access_time,
              Colors.green[100]!,
              Colors.green[700]!,
              () => _showFeatureInfo('Permintaan Koreksi Kehadiran'),
            ),
            _buildFeatureItem(
              'Jadwal Shift',
              Icons.calendar_today,
              Colors.green[100]!,
              Colors.green[700]!,
              () => _showFeatureInfo('Jadwal Shift'),
            ),
            _buildFeatureItem(
              'Minta Jadwal Shift',
              Icons.calendar_view_week,
              Colors.green[100]!,
              Colors.green[700]!,
              () => _showFeatureInfo('Minta Jadwal Shift'),
            ),
          ],
        ),

        // Cuti Section
        _buildFeatureSection(
          'Cuti',
          [
            _buildFeatureItem(
              'Permintaan Cuti',
              Icons.description,
              Colors.blue[100]!,
              Colors.blue[700]!,
              () => _showFeatureInfo('Permintaan Cuti'),
            ),
            _buildFeatureItem(
              'Jatah Cuti',
              Icons.description,
              Colors.blue[100]!,
              Colors.blue[700]!,
              () => _showFeatureInfo('Jatah Cuti'),
              hasNotification:
                  _sisaCuti > 0, // Tampilkan notifikasi jika ada sisa cuti
              notificationCount:
                  _isLoadingSisaCuti ? 0 : _sisaCuti, // Gunakan data dari API
            ),
            _buildFeatureItem(
              'Kalendar Cuti',
              Icons.calendar_month,
              Colors.blue[100]!,
              Colors.blue[700]!,
              () => _showFeatureInfo('Kalendar Cuti'),
            ),
          ],
        ),

        // Lembur Section
        _buildFeatureSection(
          'Lembur',
          [
            _buildFeatureItem(
              'Laporan Karyawan Lembur',
              Icons.description,
              Colors.purple[100]!,
              Colors.purple[700]!,
              () => _showFeatureInfo('Laporan Karyawan Lembur'),
            ),
            _buildFeatureItem(
              'Laporan Permintaan Lembur',
              Icons.description,
              Colors.purple[100]!,
              Colors.purple[700]!,
              () => _showFeatureInfo('Laporan Permintaan Lembur'),
            ),
            _buildFeatureItem(
              'Laporan Pembatalan Lembur',
              Icons.description,
              Colors.purple[100]!,
              Colors.purple[700]!,
              () => _showFeatureInfo('Laporan Pembatalan Lembur'),
            ),
          ],
        ),

        // Perjalanan Bisnis Section
        _buildFeatureSection(
          'Perjalanan Bisnis',
          [
            _buildFeatureItem(
              'Permintaan Perjalanan',
              Icons.work,
              Colors.orange[100]!,
              Colors.orange[700]!,
              () => _showFeatureInfo('Permintaan Perjalanan'),
            ),
            _buildFeatureItem(
              'Laporan Perjalanan',
              Icons.description,
              Colors.orange[100]!,
              Colors.orange[700]!,
              () => _showFeatureInfo('Laporan Perjalanan'),
            ),
          ],
        ),

        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }
}
