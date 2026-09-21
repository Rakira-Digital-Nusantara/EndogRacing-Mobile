import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/features/customers/providers/customer_provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';

class CustomerInputScreen extends StatefulWidget {
  final Map<String, dynamic>? customer;
  const CustomerInputScreen({super.key, this.customer});

  @override
  State<CustomerInputScreen> createState() => _CustomerInputScreenState();
}

class _CustomerInputScreenState extends State<CustomerInputScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!['customer_name']?.toString() ?? widget.customer!['name']?.toString() ?? '';
      _addressCtrl.text = widget.customer!['address']?.toString() ?? widget.customer!['alamat']?.toString() ?? '';
      _phoneCtrl.text = widget.customer!['phone']?.toString() ?? widget.customer!['no_hp']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _simpanCustomer() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Nama pelanggan wajib diisi!'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final isEditMode = widget.customer != null;
    bool success = false;
    String errorMsg = '';
    
    if (isEditMode) {
      final payload = {
        "customer_name": _nameCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "address": _addressCtrl.text.trim(),
      };
      final provider = context.read<CustomerProvider>();
      final code = widget.customer!['customer_code']?.toString() ?? widget.customer!['code']?.toString() ?? '';
      success = await provider.updateCustomer(code, payload);
      errorMsg = provider.error;
    } else {
      final payload = {
        "name": _nameCtrl.text.trim(),
        "no_hp": _phoneCtrl.text.trim(),
        "alamat": _addressCtrl.text.trim(),
      };
      final provider = context.read<SalesProvider>();
      success = await provider.submitCustomer(payload);
      errorMsg = provider.error;
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(isEditMode ? 'Data berhasil diperbarui!' : 'Berhasil menambahkan ${_nameCtrl.text}!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg.isNotEmpty ? errorMsg : 'Gagal memproses data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.customer != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Customer' : 'Tambah Customer Baru', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Pelanggan Baru',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Masukkan informasi pelanggan dengan benar',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Positioned.fill(
              top: 90,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel('Nama Pelanggan / Toko', true),
                      TextField(
                        controller: _nameCtrl,
                        decoration: _buildInputDecoration('Contoh: Toko Berkah', Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildInputLabel('Nomor Telepon / WA', false),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration('Contoh: 08123456789', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildInputLabel('Alamat Lengkap', false),
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 4,
                        decoration: _buildInputDecoration('Masukkan alamat lengkap...', Icons.location_on_outlined).copyWith(
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 60),
                            child: Icon(Icons.location_on_outlined, color: AppColors.primary),
                          ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _simpanCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(isEditMode ? 'Simpan Perubahan' : 'Simpan Customer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
          if (isRequired)
            const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
}
