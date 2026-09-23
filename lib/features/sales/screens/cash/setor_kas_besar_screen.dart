import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';

class SetorKasBesarScreen extends StatefulWidget {
  const SetorKasBesarScreen({super.key});

  @override
  State<SetorKasBesarScreen> createState() => _SetorKasBesarScreenState();
}

class _SetorKasBesarScreenState extends State<SetorKasBesarScreen> {
  final nominalCtrl = TextEditingController();
  final ketCtrl = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    nominalCtrl.dispose();
    ketCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Icon(icon, color: AppColors.primary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        actions: [
        ],
        title: const Text(
          'Setor ke Kas Besar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Header Background Gradient
            Container(
              width: double.infinity,
              height: 140,
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catat Setoran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Setor tunai ke rekening perusahaan',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        SizedBox(height: 8),
                        Consumer<SalesProvider>(
                          builder: (context, sales, child) {
                            return Text(
                              'Saldo Tersedia: ${CurrencyFormatter.format(sales.saldoBelumDisetor)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellowAccent,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Positioned.fill(
              top: 90, // Start scrolling over the header
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  120,
                ), // Bottom padding for bottomSheet
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Nominal
                      _buildInputLabel('Nominal Setoran (Rp)', true),
                      TextField(
                        controller: nominalCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                        decoration: _buildInputDecoration(
                          '0',
                          Icons.attach_money_rounded,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Tujuan COA (Read Only)
                      _buildInputLabel('Tujuan Setor', true),
                      TextFormField(
                        initialValue: 'Kas Besar (Utama)',
                        readOnly: true,
                        decoration:
                            _buildInputDecoration(
                              'Kas Besar',
                              Icons.account_balance_wallet_rounded,
                            ).copyWith(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Keterangan
                      _buildInputLabel('Keterangan (Opsional)', false),
                      TextField(
                        controller: ketCtrl,
                        decoration: _buildInputDecoration(
                          'Tambahkan catatan...',
                          Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. Upload Image Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showImageSourceActionSheet,
                          icon: Icon(
                            _imageFile != null
                                ? Icons.check_circle
                                : Icons.upload_file_rounded,
                            color: _imageFile != null
                                ? Colors.green
                                : AppColors.primary,
                          ),
                          label: Text(
                            _imageFile != null
                                ? 'Bukti Berhasil Diunggah'
                                : 'Upload Bukti Penyetoran',
                            style: TextStyle(
                              color: _imageFile != null
                                  ? Colors.green
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: _imageFile != null
                                  ? Colors.green
                                  : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      if (_imageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            'File: ${_imageFile!.path.split('/').last}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      final nominalStr = nominalCtrl.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final nominal = double.tryParse(nominalStr) ?? 0;
                      if (nominal <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nominal harus lebih dari 0'),
                          ),
                        );
                        return;
                      }
                      // Foto bukti sekarang opsional

                      setState(() => _isSubmitting = true);

                      final provider = context.read<SalesProvider>();

                      final formData = FormData.fromMap({
                        'nominal': nominal.toInt(),
                        'catatan': ketCtrl.text,
                        'tanggal': DateTime.now().toIso8601String().split('T')[0],
                        if (_imageFile != null)
                          'foto_bukti': await MultipartFile.fromFile(
                            _imageFile!.path,
                            filename: _imageFile!.path.split('/').last,
                          ),
                      });

                      final success = await provider.submitSetorKasBesar(
                        formData,
                      );

                      if (context.mounted) {
                        setState(() => _isSubmitting = false);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Berhasil menyetor ${CurrencyFormatter.format(nominal)} ke Kas Besar!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Refresh saldo
                          provider.fetchSaldoBelumDisetor();
                          provider.fetchRekapHarian();
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal: ${provider.error}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Kirim Setoran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
