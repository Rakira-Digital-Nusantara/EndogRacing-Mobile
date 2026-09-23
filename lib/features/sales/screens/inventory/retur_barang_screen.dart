import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';

class ReturBarangScreen extends StatefulWidget {
  const ReturBarangScreen({super.key});

  @override
  State<ReturBarangScreen> createState() => _ReturBarangScreenState();
}

class _ReturBarangScreenState extends State<ReturBarangScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedProduct;
  String? _selectedAlasan;
  double _qtyKas = 0;
  double _qtyKg = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchReturForm();
    });
  }

  void _submit() async {
    final sales = context.read<SalesProvider>();
    if (_selectedProduct == null || _selectedAlasan == null || (_qtyKas <= 0 && _qtyKg <= 0)) return;
    
    setState(() => _isLoading = true);

    final gudangTujuan = sales.returGudangTujuan?['gudang_code']?.toString() ?? 
                         sales.returGudangTujuan?['kode_gudang']?.toString() ?? 
                         'GDG0001';

    final payload = {
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'gudang_tujuan': gudangTujuan,
      'details': [
        {
          'sku_product': _selectedProduct,
          'qty_kas': _qtyKas % 1 == 0 ? _qtyKas.toInt() : _qtyKas,
          'qty_kg': _qtyKg % 1 == 0 ? _qtyKg.toInt() : _qtyKg,
          'alasan': _selectedAlasan,
        }
      ]
    };

    final success = await sales.submitRetur(payload);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Retur barang berhasil!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sales.error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        actions: [
        ],
        title: const Text('Refund / Retur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: sales.isLoading && sales.returProdukList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Header Background Gradient
              Container(
                width: double.infinity,
                height: 140,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
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
                      child: const Icon(Icons.assignment_return_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Form Retur Produk',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kembalikan barang sisa/pecah ke gudang',
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
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Gudang Tujuan', false),
                        TextFormField(
                          initialValue: sales.returGudangTujuan?['gudang_nama']?.toString() ?? 'Gudang Pusat',
                          readOnly: true,
                          decoration: _buildInputDecoration('', Icons.warehouse_rounded).copyWith(
                            fillColor: Colors.grey.shade100,
                          ),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 24),

                        _buildInputLabel('Jenis Produk', true),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _buildInputDecoration('Pilih Produk', Icons.inventory_2_rounded),
                          initialValue: _selectedProduct,
                          items: sales.returProdukList.map((p) {
                            final name = p['sku_name']?.toString() ?? '-';
                            final stok = p['stok_di_mobil']?.toString() ?? '0';
                            final uom = p['sku_uom']?.toString() ?? 'Kg';
                            return DropdownMenuItem<String>(
                              value: p['sku_product']?.toString(), 
                              child: Text('$name (Sisa Mobil: $stok $uom)', style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedProduct = v),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.red.shade500),
                        ),
                        const SizedBox(height: 24),

                        _buildInputLabel('Alasan Retur', true),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _buildInputDecoration('Pilih Alasan', Icons.feedback_rounded),
                          initialValue: _selectedAlasan,
                          items: sales.returAlasanList.map((a) => DropdownMenuItem<String>(
                            value: a, 
                            child: Text(a, style: const TextStyle(fontSize: 14))
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedAlasan = v),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.red.shade500),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Jumlah (KAS/Peti)', false),
                                  TextFormField(
                                    decoration: _buildInputDecoration('0', Icons.inventory_2_rounded),
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    onChanged: (v) => setState(() => _qtyKas = double.tryParse(v) ?? 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Jumlah (KG)', false),
                                  TextFormField(
                                    decoration: _buildInputDecoration('0.00', Icons.scale_rounded),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    onChanged: (v) => setState(() => _qtyKg = double.tryParse(v) ?? 0),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
              color: Colors.black.withValues(alpha: 0.05),
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
              onPressed: _selectedProduct != null && _selectedAlasan != null && (_qtyKas > 0 || _qtyKg > 0) && !_isLoading 
                ? _submit 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.red.withValues(alpha: 0.4),
                disabledBackgroundColor: Colors.red.shade200,
              ),
              child: _isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Kirim Retur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      prefixIcon: Icon(icon, color: Colors.red.shade500),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade500, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
