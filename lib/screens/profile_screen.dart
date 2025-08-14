import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _quickLoginEnabled = false;
  bool _lightModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan waktu dan status bar
              _buildHeader(),

              // Profil user
              _buildUserProfile(),

              // Section pengaturan akun
              _buildAccountSection(),

              // Section pengaturan aplikasi
              _buildSettingsSection(),

              // Logout dan versi
              _buildLogoutSection(),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Judul halaman
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Profil',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 24,
                ),
                onPressed: () => _showSnackBar('Pencarian'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey[600],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hai, Fajar Habib Zaelani',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full Stack Developer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileItem(
            icon: Icons.person_outline,
            title: 'Profil Saya',
            onTap: () => _showSnackBar('Profil Saya'),
          ),
          _buildProfileItem(
            icon: Icons.settings,
            title: 'Pengaturan Personal',
            onTap: () => _showSnackBar('Pengaturan Personal'),
          ),
          _buildProfileItem(
            icon: Icons.business,
            title: 'PT Qwords Company International',
            onTap: () => _showSnackBar('PT Qwords Company International'),
          ),
          _buildProfileItem(
            icon: Icons.switch_account,
            title: 'Ganti Akun',
            subtitle: 'fajar.habib@genioinfinity.com',
            showArrow: true,
            onTap: () => _showSnackBar('Ganti Akun'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileItem(
            icon: Icons.qr_code_scanner,
            title: 'Masuk Cepat',
            showToggle: true,
            toggleValue: _quickLoginEnabled,
            onToggleChanged: (value) {
              setState(() {
                _quickLoginEnabled = value;
              });
            },
          ),
          _buildProfileItem(
            icon: Icons.wb_sunny,
            title: 'Mode terang',
            showToggle: true,
            toggleValue: _lightModeEnabled,
            onToggleChanged: (value) {
              setState(() {
                _lightModeEnabled = value;
              });
            },
          ),
          _buildProfileItem(
            icon: Icons.language,
            title: 'Bahasa',
            showLanguageIndicator: true,
            onTap: () => _showSnackBar('Bahasa'),
          ),
          _buildProfileItem(
            icon: Icons.lock,
            title: 'Kebijakan Privasi',
            onTap: () => _showSnackBar('Kebijakan Privasi'),
          ),
          _buildProfileItem(
            icon: Icons.headphones,
            title: 'Bantuan & Dukungan',
            onTap: () => _showSnackBar('Bantuan & Dukungan'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildProfileItem(
            icon: Icons.logout,
            title: 'Keluar',
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(),
          ),
          const SizedBox(height: 16),
          // Versi aplikasi
          Center(
            child: Text(
              'v 1.65.0 - 1.65.3',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showArrow = false,
    bool showToggle = false,
    bool showLanguageIndicator = false,
    bool? toggleValue,
    Function(bool)? onToggleChanged,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: textColor ?? Colors.grey[700],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor ?? Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showLanguageIndicator)
                  Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(1),
                                bottomLeft: Radius.circular(1),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(1),
                                bottomRight: Radius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (showToggle)
                  Switch(
                    value: toggleValue ?? false,
                    onChanged: onToggleChanged,
                    activeColor: Colors.blue,
                  )
                else if (showArrow)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
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
        currentIndex: 4, // Profile tab is selected
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
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/features');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/posts');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/workspace');
          }
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message akan segera tersedia'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Clear semua data user
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                await prefs.remove('user_data');
                await prefs.remove('user_email');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anda telah keluar'),
                    backgroundColor: Colors.red,
                  ),
                );

                // Redirect ke login screen
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
