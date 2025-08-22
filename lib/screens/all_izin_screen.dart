import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'detail_cuti_screen.dart';

class AllIzinScreen extends StatefulWidget {
  const AllIzinScreen({super.key});

  @override
  State<AllIzinScreen> createState() => _AllIzinScreenState();
}

class _AllIzinScreenState extends State<AllIzinScreen> {
  List<Map<String, dynamic>> _allIzinList = [];
  List<Map<String, dynamic>> _filteredIzinList = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Semua';
  bool _isHrdUser = false;
  bool _isCheckingHrdRole = true;

  final List<String> _statusOptions = [
    'Semua',
    'Menunggu Persetujuan',
    'Disetujui',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllIzinData();
    _checkHrdRole();
  }

  Future<void> _loadAllIzinData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
          _isLoading = false;
        });
        return;
      }

      final responseData = await ApiService.getAllIzin(token);

      if (responseData['data'] != null) {
        setState(() {
          _allIzinList = List<Map<String, dynamic>>.from(responseData['data']);
          _filteredIzinList = List.from(_allIzinList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat data izin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

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
      } else {
        setState(() {
          _isHrdUser = false;
          _isCheckingHrdRole = false;
        });
      }
    } catch (e) {
      setState(() {
        _isHrdUser = false;
        _isCheckingHrdRole = false;
      });
    }
  }

  Future<void> _approveIzin(int izinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Token tidak ditemukan. Silakan login ulang.')),
        );
        return;
      }

      await ApiService.approveIzin(token, izinId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data setelah approve
      _loadAllIzinData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyetujui izin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectIzin(int izinId) async {
    final TextEditingController keteranganController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tolak Izin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan alasan penolakan:'),
              const SizedBox(height: 16),
              TextField(
                controller: keteranganController,
                decoration: const InputDecoration(
                  hintText: 'Alasan penolakan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (keteranganController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop(keteranganController.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Alasan penolakan harus diisi')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Token tidak ditemukan. Silakan login ulang.')),
          );
          return;
        }

        await ApiService.rejectIzin(token, izinId, result);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin berhasil ditolak'),
            backgroundColor: Colors.orange,
          ),
        );

        // Reload data setelah reject
        _loadAllIzinData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak izin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(Map<String, dynamic> izin) {
    if (izin['validasi_personalia'] == true) {
      return 'Disetujui';
    } else if (izin['keterangan_tolak_personalia'] != null) {
      return 'Ditolak';
    } else {
      return 'Menunggu Persetujuan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Ditolak':
        return Colors.red;
      case 'Menunggu Persetujuan':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _filterIzin() {
    final searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredIzinList = _allIzinList.where((izin) {
        final status = _getStatusText(izin);
        final namaKaryawan =
            (izin['nama_karyawan'] ?? '').toString().toLowerCase();
        final jenisIzin =
            (izin['nama_status_hadir'] ?? '').toString().toLowerCase();
        final keterangan = (izin['keterangan'] ?? '').toString().toLowerCase();

        // Filter berdasarkan status
        bool statusMatch =
            _selectedStatus == 'Semua' || status == _selectedStatus;

        // Filter berdasarkan search query
        bool searchMatch = namaKaryawan.contains(searchQuery) ||
            jenisIzin.contains(searchQuery) ||
            keterangan.contains(searchQuery);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Semua Izin',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadAllIzinData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllIzinData,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // HRD Role Indicator
                    if (_isCheckingHrdRole)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.withOpacity(0.1),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Memeriksa hak akses HRD...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // HRD Badge
                    if (!_isCheckingHrdRole && _isHrdUser)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.green.withOpacity(0.1),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Icon(
                              Icons.admin_panel_settings,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mode HRD - Anda dapat menyetujui/menolak izin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Search and Filter Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search Bar
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => _filterIzin(),
                            decoration: InputDecoration(
                              hintText:
                                  'Cari berdasarkan nama, jenis izin, atau keterangan',
                              prefixIcon:
                                  const Icon(Icons.search, color: Colors.grey),
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
                          const SizedBox(height: 12),
                          // Status Filter
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                items: _statusOptions.map((String status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedStatus = newValue!;
                                    _filterIzin();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Results Count
                    if (_filteredIzinList.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              'Menampilkan ${_filteredIzinList.length} dari ${_allIzinList.length} izin',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Izin List
                    Expanded(
                      child: _filteredIzinList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada izin yang ditemukan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Coba ubah filter atau kata kunci pencarian',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAllIzinData,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredIzinList.length,
                                itemBuilder: (context, index) {
                                  final izin = _filteredIzinList[index];
                                  final status = _getStatusText(izin);
                                  final statusColor = _getStatusColor(status);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailCutiScreen(
                                              cutiId: izin['id'],
                                            ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        izin['nama_karyawan'] ??
                                                            'Tidak ada nama',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        izin['nama_status_hadir'] ??
                                                            'Tidak ada jenis izin',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            if (izin['keterangan'] != null) ...[
                                              Text(
                                                'Keterangan: ${izin['keterangan']}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${izin['tanggal_awal']} - ${izin['tanggal_akhir']}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${izin['jumlah_hari']} hari',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (izin['created_at'] != null)
                                                  Text(
                                                    'Dibuat: ${_formatDate(izin['created_at'])}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            // Tombol Approve/Reject untuk HRD
                                            if (_isHrdUser &&
                                                status ==
                                                    'Menunggu Persetujuan') ...[
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _approveIzin(
                                                              izin['id']),
                                                      icon: const Icon(
                                                          Icons.check,
                                                          size: 18),
                                                      label:
                                                          const Text('Setujui'),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _rejectIzin(
                                                              izin['id']),
                                                      icon: const Icon(
                                                          Icons.close,
                                                          size: 18),
                                                      label:
                                                          const Text('Tolak'),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildBottomNavigation(),
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
          currentIndex: 1, // Cuti tab is selected
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
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/features');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          },
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
