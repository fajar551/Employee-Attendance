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
  bool _isHrdUser = false; // State untuk tracking role HRD
  bool _isCheckingHrdRole = true; // Loading state untuk pengecekan role HRD

  // Data semua fitur - inisialisasi langsung
  final List<Map<String, dynamic>> _allFeatures = [
    // Cuti
    {
      'name': 'Permintaan Cuti',
      'icon': Icons.description,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Cuti',
    },
    {
      'name': 'Jatah Cuti',
      'icon': Icons.description,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Cuti',
      'hasNotification': true, // Akan diupdate secara dinamis
      'notificationCount': 2, // Akan diupdate secara dinamis
    },
    {
      'name': 'List Cuti Saya',
      'icon': Icons.calendar_month,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Cuti',
    },
    {
      'name': 'Semua Izin',
      'icon': Icons.list_alt,
      'backgroundColor': Colors.orange[100],
      'iconColor': Colors.orange[700],
      'category': 'Cuti',
      'hrdOnly': true, // Menandakan bahwa fitur ini hanya untuk HRD
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
      _checkHrdRole(); // Cek role HRD
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
    // Filter features berdasarkan role HRD terlebih dahulu
    List<Map<String, dynamic>> availableFeatures =
        _allFeatures.where((feature) {
      if (feature['hrdOnly'] == true) {
        return _isHrdUser;
      }
      return true;
    }).toList();

    // Update data Jatah Cuti dengan data dinamis
    for (int i = 0; i < availableFeatures.length; i++) {
      if (availableFeatures[i]['name'] == 'Jatah Cuti') {
        availableFeatures[i]['hasNotification'] = _sisaCuti > 0;
        availableFeatures[i]['notificationCount'] = _sisaCuti;
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

  // Function untuk mengecek role HRD
  Future<void> _checkHrdRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        final response = await ApiService.getUserHrdAcc(token);
        setState(() {
          _isHrdUser = response['data'] != null;
          _isCheckingHrdRole = false;
        });

        // Re-initialize features setelah role HRD diketahui
        _initializeFeatures();
      } else {
        setState(() {
          _isHrdUser = false;
          _isCheckingHrdRole = false;
        });
        _initializeFeatures();
      }
    } catch (e) {
      setState(() {
        _isHrdUser = false;
        _isCheckingHrdRole = false;
      });
      _initializeFeatures();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFeatures() {
    print('Debug: Initializing features...');

    // Filter features berdasarkan role HRD
    List<Map<String, dynamic>> availableFeatures =
        _allFeatures.where((feature) {
      // Jika fitur hanya untuk HRD, tampilkan hanya jika user adalah HRD
      if (feature['hrdOnly'] == true) {
        return _isHrdUser;
      }
      // Jika bukan fitur HRD-only, tampilkan untuk semua user
      return true;
    }).toList();

    // Tambahkan onTap callback ke setiap fitur
    for (int i = 0; i < availableFeatures.length; i++) {
      availableFeatures[i]['onTap'] =
          () => _showFeatureInfo(availableFeatures[i]['name']);
    }

    // Update data Jatah Cuti dengan data dinamis
    for (int i = 0; i < availableFeatures.length; i++) {
      if (availableFeatures[i]['name'] == 'Jatah Cuti') {
        availableFeatures[i]['hasNotification'] = _sisaCuti > 0;
        availableFeatures[i]['notificationCount'] =
            _isLoadingSisaCuti ? 0 : _sisaCuti;
        break;
      }
    }

    _filteredFeatures = List.from(availableFeatures);
    print('Debug: Features initialized. Total: ${availableFeatures.length}');
    print(
        'Debug: Feature names: ${availableFeatures.map((f) => f['name']).toList()}');
    print('Debug: Is HRD User: $_isHrdUser');
  }

  void _showFeatureInfo(String featureName) {
    if (featureName == 'Permintaan Cuti') {
      Navigator.pushNamed(context, '/izin');
    } else if (featureName == 'List Cuti Saya') {
      Navigator.pushNamed(context, '/list-cuti');
    } else if (featureName == 'Semua Izin') {
      Navigator.pushNamed(context, '/all-izin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fitur "$featureName" akan segera tersedia.'),
          backgroundColor: const Color(0xFFF97316),
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

        // Filter features berdasarkan role HRD terlebih dahulu
        List<Map<String, dynamic>> availableFeatures =
            _allFeatures.where((feature) {
          if (feature['hrdOnly'] == true) {
            return _isHrdUser;
          }
          return true;
        }).toList();

        // Kemudian filter berdasarkan search query
        _filteredFeatures = availableFeatures.where((feature) {
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
        // Filter features berdasarkan role HRD untuk tampilan normal
        _filteredFeatures = _allFeatures.where((feature) {
          if (feature['hrdOnly'] == true) {
            return _isHrdUser;
          }
          return true;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Debug: Build method called');
    print('Debug: _allFeatures length: ${_allFeatures.length}');
    print('Debug: _filteredFeatures length: ${_filteredFeatures.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Cuti',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: const Color(0xFF64748B),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          _isGridView
                              ? Icons.grid_view_rounded
                              : Icons.view_list_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_isGridView
                            ? 'Tampilan Grid aktif'
                            : 'Tampilan List aktif'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF3B82F6),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar dengan desain modern
            Container(
              margin: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _searchFeatures(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari fitur cuti...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF97316),
                        Color(0xFFEA580C),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF97316),
                          Color(0xFFEA580C),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (hasNotification)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626)
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  notificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
                const SizedBox(height: 12),
                Container(
                  width: 100,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.2,
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF97316),
                              Color(0xFFEA580C),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      if (hasNotification)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
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
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF97316),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          currentIndex: 1, // Fitur tab is selected
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 24),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded, size: 24),
              label: 'Cuti',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 24),
              label: 'Profil',
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          },
        ),
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
    // Kelompokkan features berdasarkan kategori
    Map<String, List<Map<String, dynamic>>> groupedFeatures = {};
    for (var feature in _filteredFeatures) {
      String category = feature['category'] as String;
      if (!groupedFeatures.containsKey(category)) {
        groupedFeatures[category] = [];
      }
      groupedFeatures[category]!.add(feature);
    }

    return Column(
      children: [
        // Tampilkan setiap kategori
        ...groupedFeatures.entries.map((entry) {
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

        // Tambahkan informasi cuti di bawah menu
        _buildCutiInfoSection(),

        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  Widget _buildCutiInfoSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Cuti',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Panduan lengkap sistem cuti',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoItem(
            Icons.calendar_today_rounded,
            'Jatah Cuti Tahunan',
            'Anda memiliki hak cuti tahunan sesuai dengan ketentuan perusahaan',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.schedule_rounded,
            'Pengajuan Cuti',
            'Ajukan cuti minimal 3 hari sebelum tanggal cuti yang diinginkan',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.notifications_rounded,
            'Status Pengajuan',
            'Pantau status pengajuan cuti Anda melalui menu "List Cuti Saya"',
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            Icons.help_outline_rounded,
            'Butuh Bantuan?',
            'Hubungi HRD jika ada pertanyaan terkait pengajuan cuti',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
