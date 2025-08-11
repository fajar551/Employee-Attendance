import 'package:flutter/material.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true; // State untuk toggle tampilan

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFeatureInfo(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur "$featureName" akan segera tersedia.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _searchFeatures(String query) {
    if (query.isNotEmpty) {
      // Implementasi pencarian fitur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mencari fitur: "$query"'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: Colors.green,
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
                  // Implementasi pencarian fitur
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
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Waktu Kehadiran Section
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
                  hasNotification: true,
                  notificationCount: 2,
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
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFeatureSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: children,
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
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 28,
                      ),
                    ),
                    if (hasNotification)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
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
                const SizedBox(height: 8),
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    if (hasNotification)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
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
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
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
}
