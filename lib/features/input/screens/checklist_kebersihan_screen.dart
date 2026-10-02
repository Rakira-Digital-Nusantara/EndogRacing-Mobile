import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

import '../../../core/constants/app_colors.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/success_screen.dart';

class ChecklistKebersihanScreen extends StatefulWidget {
  const ChecklistKebersihanScreen({super.key});

  @override
  State<ChecklistKebersihanScreen> createState() => _ChecklistKebersihanScreenState();
}

class _ChecklistKebersihanScreenState extends State<ChecklistKebersihanScreen> {
  List<Map<String, dynamic>> _checklists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchChecklists();
    });
  }

  Future<void> _fetchChecklists() async {
    setState(() => _isLoading = true);
    final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";
    final tanggal = DateTime.now().toIso8601String().split('T')[0];

    try {
      final response = await DioClient().dio.get('/checklist?kdg_code=$kandangCode&tanggal=$tanggal');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        if (mounted) {
          setState(() {
            _checklists = data.map((e) {
              final isSelesai = e['status'] == 'Selesai';
              return {
                'chk_code': e['chk_code'],
                'kbrshn_code': e['kbrshn_code'],
                'title': e['kbrshn_nama'],
                'subtitle': e['kbrshn_desc'],
                'icon': Icons.cleaning_services_outlined, // generic icon
                'isChecked': isSelesai,
                'photoPath': e['foto_bukti'],
                'isExpanded': false,
                'isUploading': false,
              };
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch checklist error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data checklist: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _completedCount => _checklists.where((item) => item['isChecked'] == true).length;

  Future<void> _takePhoto(int index, ImageSource source) async {
    final item = _checklists[index];
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (photo != null) {
        if (mounted) {
          setState(() {
            item['isUploading'] = true;
          });
        }

        // 1. Watermark Image
        final bytes = await File(photo.path).readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        
        if (decodedImage != null) {
          final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
          final watermarkText = 'Timestamp: $timeStr';
          
          img.drawString(
            decodedImage, 
            watermarkText, 
            font: img.arial48, 
            x: 20, 
            y: 20, 
            color: img.ColorRgb8(255, 0, 0) // Merah
          );
          
          int quality = 85;
          List<int> watermarkedBytes = img.encodeJpg(decodedImage, quality: quality);
          
          // Kompresi agar ukuran maksimal 1MB (1024 KB)
          while (watermarkedBytes.length > 1024 * 1024 && quality > 15) {
            quality -= 15;
            watermarkedBytes = img.encodeJpg(decodedImage, quality: quality);
          }
          
          await File(photo.path).writeAsBytes(watermarkedBytes);
        }

        // 2. Direct Upload per item
        if (!mounted) return;
        final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? "KDG-001";
        final tanggal = DateTime.now().toIso8601String().split('T')[0];
        
        final formData = FormData.fromMap({
          "kdg_code": kandangCode,
          "kbrshn_code": item['kbrshn_code'],
          "tanggal": tanggal,
          "foto_bukti": await MultipartFile.fromFile(photo.path, filename: 'bukti_${item['kbrshn_code']}.jpg'),
        });

        final response = await DioClient().dio.post('/checklist/submit', data: formData);
        
        if (mounted) {
          if (response.statusCode == 200 || response.statusCode == 201) {
            setState(() {
              item['isChecked'] = true;
              item['photoPath'] = photo.path;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto berhasil disimpan'), backgroundColor: Colors.green),
            );
          } else {
             throw Exception('Gagal menyimpan foto ke server');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          item['isUploading'] = false;
        });
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _checklists[index]['isChecked'] = false;
      _checklists[index]['photoPath'] = null;
    });
  }

  void _showImageSourceActionSheet(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(index, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto(index, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Checklist Kebersihan',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _checklists.isEmpty
        ? const Center(child: Text("Belum ada tugas kebersihan"))
        : SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checklist Harian',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kandang 1 - Sesi Pagi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_completedCount/${_checklists.length}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534), // Dark Green
                          ),
                        ),
                        const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A), // Green
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedCount / _checklists.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF166534)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Divider
          Container(
            height: 8,
            color: const Color(0xFFF8FAFC),
          ),
          
          // List Section
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _checklists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _checklists[index];
                final isChecked = item['isChecked'] as bool;
                
                final isExpanded = item['isExpanded'] as bool? ?? false;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFFF0FDF4) : const Color(0xFFEEF2F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChecked ? const Color(0xFFBBF7D0) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            item['isExpanded'] = !isExpanded;
                          });
                        },
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isChecked ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'],
                                color: isChecked ? const Color(0xFF166534) : const Color(0xFF475569),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Texts
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isChecked ? const Color(0xFF166534) : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isChecked ? const Color(0xFF16A34A) : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Checkbox circle
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChecked ? const Color(0xFF16A34A) : Colors.grey.shade400,
                                  width: 2,
                                ),
                                color: isChecked ? const Color(0xFF16A34A) : Colors.white,
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : (isExpanded ? const Icon(Icons.keyboard_arrow_up, size: 18, color: Colors.grey) : const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Expanded Content
                      if (isExpanded) ...[
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 16),
                        if (item['photoPath'] == null && !(item['isUploading'] ?? false))
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showImageSourceActionSheet(index),
                              icon: const Icon(Icons.camera_alt_outlined, size: 20),
                              label: const Text('Ambil Bukti Foto (Wajib)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else if (item['isUploading'] ?? false)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item['photoPath'].toString().startsWith('http') 
                                ? Image.network(
                                    item['photoPath'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(item['photoPath']),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Foto berhasil disimpan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF166534),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextButton.icon(
                                      onPressed: () => _removePhoto(index),
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      label: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }
  
  Widget _buildSubmitButton() {
    final bool isAllChecked = _completedCount == _checklists.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: AppButton(
          onPressed: () {
            if (isAllChecked) {
              showDialog(
                context: context,
                builder: (context) => SuccessDialog(
                  title: 'Laporan Kebersihan Terkirim',
                  subtitle: 'Semua tugas kebersihan hari ini telah terselesaikan.',
                  time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
                  primaryButtonText: 'Kembali ke Input',
                  onPrimaryPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Masih ada tugas yang belum dilaporkan fotonya!'),
                  backgroundColor: Colors.red,
                )
              );
            }
          },
          backgroundColor: isAllChecked ? AppColors.primary : const Color(0xFF94A3B8), // Jika selesai semua biru, jika belum abu2
          text: 'Simpan Data',
          trailingIcon: Icons.check_circle,
        ),
      ),
    );
  }
}
