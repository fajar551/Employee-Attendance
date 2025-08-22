import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class DetailCutiScreen extends StatefulWidget {
  final int cutiId;

  const DetailCutiScreen({super.key, required this.cutiId});

  @override
  State<DetailCutiScreen> createState() => _DetailCutiScreenState();
}

class _DetailCutiScreenState extends State<DetailCutiScreen> {
  Map<String, dynamic>? _cutiDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetailCuti();
  }

  Future<void> _loadDetailCuti() async {
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

      final responseData = await ApiService.getDetailCuti(token, widget.cutiId);

      if (responseData['data'] != null) {
        setState(() {
          _cutiDetail = responseData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat detail cuti.';
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

  String _getStatusText(Map<String, dynamic> cuti) {
    if (cuti['validasi_personalia'] == true) {
      return 'Disetujui';
    } else if (cuti['validasi_pimpinan'] == true &&
        cuti['validasi_personalia'] == true) {
      return 'Menunggu Persetujuan Pimpinan & Personalia';
    } else if (cuti['validasi_pimpinan'] == true) {
      return 'Menunggu Persetujuan Personalia';
    } else if (cuti['validasi_personalia'] == true) {
      return 'Menunggu Persetujuan Pimpinan';
    } else {
      return 'Menunggu Persetujuan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return Colors.green;
      case 'Menunggu Persetujuan':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Detail Cuti',
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
            onPressed: _loadDetailCuti,
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
                        onPressed: _loadDetailCuti,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _cutiDetail == null
                  ? const Center(
                      child: Text('Data tidak ditemukan'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDetailCuti,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                children: [
                                  const Text(
                                    'Status Cuti',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                              _getStatusText(_cutiDetail!))
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getStatusText(_cutiDetail!),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(
                                            _getStatusText(_cutiDetail!)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Informasi Detail
                            const Text(
                              'Informasi Detail',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildInfoCard(
                              'Jenis Cuti',
                              _cutiDetail!['nama_status_hadir'] ??
                                  'Tidak ada data',
                              Icons.category,
                            ),

                            _buildInfoCard(
                              'Tanggal Awal',
                              _formatDate(_cutiDetail!['tanggal_awal']),
                              Icons.calendar_today,
                            ),

                            _buildInfoCard(
                              'Tanggal Akhir',
                              _formatDate(_cutiDetail!['tanggal_akhir']),
                              Icons.calendar_today,
                            ),

                            _buildInfoCard(
                              'Jumlah Hari',
                              '${_cutiDetail!['jumlah_hari']} hari',
                              Icons.access_time,
                            ),

                            if (_cutiDetail!['keterangan'] != null)
                              _buildInfoCard(
                                'Keterangan',
                                _cutiDetail!['keterangan'],
                                Icons.description,
                              ),

                            const SizedBox(height: 20),

                            // Status Persetujuan
                            const Text(
                              'Status Persetujuan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // _buildApprovalCard(
                            //   'Validasi Pimpinan',
                            //   _cutiDetail!['validasi_pimpinan'] == true,
                            //   _cutiDetail!['keterangan_tolak_pimpinan'],
                            // ),

                            _buildApprovalCard(
                              'Validasi Personalia',
                              _cutiDetail!['validasi_personalia'] == true,
                              _cutiDetail!['keterangan_tolak_personalia'],
                            ),

                            // _buildApprovalCard(
                            //   'Validasi Pimpinan & Personalia',
                            //   _cutiDetail!['validasi_pimpinan_personalia'] ==
                            //       true,
                            //   _cutiDetail![
                            //       'keterangan_tolak_pimpinan_personalia'],
                            // ),

                            const SizedBox(height: 20),

                            // Informasi Tambahan
                            const Text(
                              'Informasi Tambahan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildInfoCard(
                              'Dibuat Pada',
                              _formatDateTime(_cutiDetail!['created_at']),
                              Icons.schedule,
                            ),

                            _buildInfoCard(
                              'Diperbarui Pada',
                              _formatDateTime(_cutiDetail!['updated_at']),
                              Icons.update,
                            ),

                            if (_cutiDetail!['tanggal_approve'] != null)
                              _buildInfoCard(
                                'Tanggal Disetujui',
                                _formatDateTime(
                                    _cutiDetail!['tanggal_approve']),
                                Icons.check_circle,
                              ),

                            if (_cutiDetail!['tanggal_reject'] != null)
                              _buildInfoCard(
                                'Tanggal Ditolak',
                                _formatDateTime(_cutiDetail!['tanggal_reject']),
                                Icons.cancel,
                              ),

                            if (_cutiDetail!['name_user_acc'] != null)
                              _buildInfoCard(
                                'Disetujui Oleh',
                                _cutiDetail!['name_user_acc'],
                                Icons.person,
                              ),

                            if (_cutiDetail!['dokumen'] != null)
                              _buildDocumentCard(_cutiDetail!['dokumen']),

                            const SizedBox(height: 100), // Space for bottom
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildApprovalCard(
      String title, bool isApproved, String? rejectionReason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isApproved ? Icons.check_circle : Icons.pending,
                color: isApproved ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isApproved ? 'Disetujui' : 'Menunggu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isApproved ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Alasan penolakan: $rejectionReason',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String documentName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dokumen',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      documentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
