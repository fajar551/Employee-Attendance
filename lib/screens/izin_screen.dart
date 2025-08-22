import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class IzinScreen extends StatefulWidget {
  const IzinScreen({super.key});

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tanggalAwalController = TextEditingController();
  final _tanggalAkhirController = TextEditingController();
  final _keteranganController = TextEditingController();

  String? _selectedStatusHadir;
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isLoadingStatusHadir = false; // Loading state untuk status hadir
  List<Map<String, dynamic>> _statusHadirList = [];

  @override
  void initState() {
    super.initState();
    _loadStatusHadir();
  }

  @override
  void dispose() {
    _tanggalAwalController.dispose();
    _tanggalAkhirController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadStatusHadir() async {
    setState(() {
      _isLoadingStatusHadir = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('Debug: Token tidak ditemukan');
        return;
      }

      final responseData = await ApiService.getStatusHadir(token);

      if (responseData['data'] != null) {
        setState(() {
          _statusHadirList =
              List<Map<String, dynamic>>.from(responseData['data']);
        });
        print('Debug: Status hadir loaded: ${_statusHadirList.length} items');
      } else {
        print('Debug: Error loading status hadir. Response: $responseData');
      }
    } catch (e) {
      print('Error loading status hadir: $e');
    } finally {
      setState(() {
        _isLoadingStatusHadir = false;
      });
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  Future<void> _submitIzin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStatusHadir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tipe izin terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan, silakan login ulang'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare fields
      Map<String, String> fields = {
        'tanggal_awal': _tanggalAwalController.text,
        'tanggal_akhir': _tanggalAkhirController.text,
        'status_hadir_id': _selectedStatusHadir!,
        'keterangan': _keteranganController.text,
      };

      // Prepare files
      List<http.MultipartFile> files = [];
      if (_selectedFile != null) {
        files.add(
          await http.MultipartFile.fromPath(
            'dokumen',
            _selectedFile!.path,
            filename: _fileName,
          ),
        );
      }

      final responseData = await ApiService.submitIzin(token, fields, files);

      if (responseData['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Izin berhasil diajukan'),
            backgroundColor: Colors.orange,
          ),
        );

        // Reset form
        _formKey.currentState!.reset();
        setState(() {
          _selectedFile = null;
          _fileName = null;
          _selectedStatusHadir = null;
        });

        // Redirect ke features screen setelah berhasil
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/features');
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          'Permintaan Izin',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ajukan permintaan izin dengan mengisi form di bawah ini',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tanggal Awal
              const Text(
                'Tanggal Awal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tanggalAwalController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal awal',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: () => _selectDate(context, _tanggalAwalController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal awal harus diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Tanggal Akhir
              const Text(
                'Tanggal Akhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tanggalAkhirController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Pilih tanggal akhir',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onTap: () => _selectDate(context, _tanggalAkhirController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal akhir harus diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Status Hadir
              const Text(
                'Tipe Izin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: _isLoadingStatusHadir
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Memuat tipe izin...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedStatusHadir,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          hintText: 'Pilih tipe izin',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey),
                        dropdownColor: Colors.white,
                        items: _statusHadirList.isEmpty
                            ? [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'Tidak ada data tipe izin',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ]
                            : _statusHadirList.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status['id'].toString(),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      status['nama'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                        onChanged: _statusHadirList.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedStatusHadir = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tipe izin harus dipilih';
                          }
                          return null;
                        },
                        menuMaxHeight: 200,
                        isExpanded: true,
                      ),
              ),

              const SizedBox(height: 16),

              // Keterangan
              const Text(
                'Keterangan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _keteranganController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan keterangan izin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Keterangan harus diisi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Upload Dokumen
              const Text(
                'Dokumen Pendukung (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    if (_selectedFile == null) ...[
                      Icon(
                        Icons.upload_file,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload dokumen pendukung',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, DOC, DOCX, JPG, PNG (Max 2MB)',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.attach_file,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _fileName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(_selectedFile == null
                          ? Icons.upload
                          : Icons.change_circle),
                      label: Text(
                          _selectedFile == null ? 'Pilih File' : 'Ganti File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitIzin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Ajukan Izin',
                            style: TextStyle(
                              fontSize: 16,
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
}
