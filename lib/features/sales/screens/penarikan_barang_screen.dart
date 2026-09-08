import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PenarikanBarangScreen extends StatefulWidget {
  const PenarikanBarangScreen({super.key});

  @override
  State<PenarikanBarangScreen> createState() => _PenarikanBarangScreenState();
}

class _PenarikanBarangScreenState extends State<PenarikanBarangScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _gudang = ['GDG-001 - Gudang Pusat'];
  final List<Map<String, dynamic>> _products = [
    {'sku': 'TLR-001', 'name': 'Telur Utuh', 'stok': 500},
    {'sku': 'TLR-002', 'name': 'Telur Bentes', 'stok': 150},
  ];

  String? _selectedGudang;
  String? _selectedProduct;
  double _qty = 0;
  bool _isLoading = false;

  void _submit() async {
    if (_selectedGudang == null || _selectedProduct == null || _qty <= 0) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Tarik telur ke mobil berhasil! (Dummy)'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Ambil Telur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SizedBox.expand(
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
                      child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Form Tarik Barang',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pindahkan telur dari gudang ke mobil',
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
                        _buildInputLabel('Gudang Asal', true),
                        DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration('Pilih Gudang', Icons.warehouse_rounded),
                          value: _selectedGudang,
                          items: _gudang.map((g) => DropdownMenuItem<String>(value: g, child: Text(g, style: const TextStyle(fontSize: 14)))).toList(),
                          onChanged: (v) => setState(() => _selectedGudang = v),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildInputLabel('Jenis Telur', true),
                        DropdownButtonFormField<String>(
                          decoration: _buildInputDecoration('Pilih Telur', Icons.egg_alt_rounded),
                          value: _selectedProduct,
                          items: _products.map((p) => DropdownMenuItem<String>(
                            value: p['sku'], 
                            child: Text('${p['name']} (Sisa: ${p['stok']} Kg)', style: const TextStyle(fontSize: 14)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedProduct = v),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildInputLabel('Jumlah ditarik (Kg)', true),
                        TextFormField(
                          decoration: _buildInputDecoration('0.00', Icons.monitor_weight_rounded),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          onChanged: (v) => setState(() => _qty = double.tryParse(v) ?? 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              onPressed: _selectedGudang != null && _selectedProduct != null && _qty > 0 && !_isLoading 
                ? _submit 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Simpan Penarikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
