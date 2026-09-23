import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/shared/widgets/success_screen.dart';

class ReturTukarScreen extends StatefulWidget {
  const ReturTukarScreen({super.key});

  @override
  State<ReturTukarScreen> createState() => _ReturTukarScreenState();
}

class _ReturTukarScreenState extends State<ReturTukarScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerCode;
  String? _selectedProductSku;
  double _qtyRetur = 0;
  String _alasanRetur = '';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedProductSku == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk yang diretur'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_qtyRetur <= 0) return;

    setState(() => _isLoading = true);
    
    final payload = {
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      if (_selectedCustomerCode != null) 'customer_code': _selectedCustomerCode,
      'details': [
        {
          'sku_product': _selectedProductSku,
          'qty_retur': _qtyRetur,
          'alasan_retur': _alasanRetur.isEmpty ? 'Pecah dari toko' : _alasanRetur,
        }
      ]
    };

    final sales = context.read<SalesProvider>();
    final result = await sales.submitReturTukar(payload);
    
    setState(() => _isLoading = false);

    if (result && mounted) {
      Navigator.pop(context); // Close bottom sheet
      showDialog(
        context: context,
        builder: (context) => SuccessDialog(
          title: 'Retur Tukar Berhasil',
          subtitle: 'Retur tukar berhasil dicatat sebagai Hutang Barang.',
          time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
          primaryButtonText: 'Selesai',
          onPrimaryPressed: () {
            Navigator.pop(context);
          },
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sales.error), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Retur Tukar (Hutang Barang)',
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
              height: 140, // fixed height
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
              ),
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
                      Icons.sync_problem_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catat Retur Tukar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Catat hutang barang / tukar guling telur',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // Customer
                const Text('Customer (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Pilih Kustomer',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  ),
                  initialValue: _selectedCustomerCode,
                  items: sales.customers.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['code'],
                      child: Text(c['name'], style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCustomerCode = val),
                ),
                const SizedBox(height: 16),

                // Produk
                const Text('Produk Rusak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Pilih Produk Telur Rusak',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.egg_rounded, color: AppColors.primary),
                  ),
                  initialValue: _selectedProductSku,
                  items: sales.products.map((p) {
                    return DropdownMenuItem<String>(
                      value: p['sku'],
                      child: Text(p['name'], style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedProductSku = val),
                  validator: (value) => value == null ? 'Pilih produk' : null,
                ),
                const SizedBox(height: 16),

                // Qty
                const Text('Kuantitas (Kg)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 1.5',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.primary),
                    suffixText: 'Kg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Kuantitas harus diisi';
                    final qty = double.tryParse(value);
                    if (qty == null || qty <= 0) return 'Kuantitas tidak valid';
                    return null;
                  },
                  onSaved: (value) => _qtyRetur = double.tryParse(value ?? '0') ?? 0,
                ),
                const SizedBox(height: 16),

                // Alasan
                const Text('Alasan Retur', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Contoh: Pecah dari toko',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primary),
                  ),
                  onSaved: (value) => _alasanRetur = value ?? '',
                ),
                      ],
                    ),
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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Simpan Retur Tukar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
