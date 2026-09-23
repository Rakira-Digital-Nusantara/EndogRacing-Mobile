import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/features/auth/providers/auth_provider.dart';
import 'package:endog_racing/shared/widgets/success_screen.dart';

class PenarikanBarangScreen extends StatefulWidget {
  const PenarikanBarangScreen({super.key});

  @override
  State<PenarikanBarangScreen> createState() => _PenarikanBarangScreenState();
}

class _PenarikanBarangScreenState extends State<PenarikanBarangScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedGudangAsal;
  String? _selectedProduct;
  double _qty = 0;
  int _qtyKas = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchTarikBarangForm();
    });
  }

  void _submit() async {
    final sales = context.read<SalesProvider>();
    if (_selectedGudangAsal == null || _selectedProduct == null) return;
    
    final productMap = sales.tarikProdukList.firstWhere(
      (p) => p['sku_product'] == _selectedProduct,
      orElse: () => <String, dynamic>{},
    );
    final isTelur = productMap['sku_category']?.toString().toLowerCase().contains('telur') ?? false;

    double finalQty = 0;
    double stokTersedia = 0;

    if (isTelur) {
      finalQty = _qtyKas.toDouble();
      stokTersedia = double.tryParse(productMap['stok_tersedia_kas']?.toString() ?? '0') ?? 0;
    } else {
      finalQty = _qty;
      stokTersedia = double.tryParse(productMap['stok_tersedia_kg']?.toString() ?? productMap['stok_tersedia']?.toString() ?? '0') ?? 0;
    }

    if (finalQty <= 0) return;
    
    if (finalQty > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah melebihi stok yang tersedia'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final empCode = auth.user?.empCode ?? 'EMP-001';
    
    final payload = {
      'emp_code': empCode,
      'gudang_code': _selectedGudangAsal,
      'tanggal': DateTime.now().toIso8601String().split('T')[0],
      'details': [
        {
          'sku_product': _selectedProduct,
          'qty': finalQty,
        }
      ]
    };

    final result = await sales.submitPenarikanBarang(payload);
    
    setState(() => _isLoading = false);

    if (result != null && mounted) {
      String subtitleText = 'Tarik barang ke mobil berhasil dicatat.';
      if (result['konversi_info'] != null) {
        try {
          final konversiInfo = result['konversi_info'] as List<dynamic>;
          if (konversiInfo.isNotEmpty) {
            List<String> labels = [];
            for (var info in konversiInfo) {
              if (info['input_konversi'] != null && info['input_konversi']['label'] != null) {
                labels.add(info['input_konversi']['label'].toString());
              }
              if (info['stock_sekarang_konversi'] != null && info['stock_sekarang_konversi']['label'] != null) {
                labels.add(info['stock_sekarang_konversi']['label'].toString());
              }
            }
            if (labels.isNotEmpty) {
              subtitleText = 'Tarik barang ke mobil berhasil dicatat.\n\n' + labels.join('\n');
            }
          }
        } catch (e) {
          // Abaikan
        }
      }

      showDialog(
        context: context,
        builder: (context) => SuccessDialog(
          title: 'Penarikan Berhasil',
          subtitle: subtitleText,
          time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
          primaryButtonText: 'Selesai',
          onPrimaryPressed: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context); // go back
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
        actions: [
        ],
        title: const Text('Ambil Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: sales.isLoading && sales.tarikGudangAsalList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : sales.tarikGudangTujuan == null 
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Gudang Mobil Belum Diatur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Akun Sales Anda belum di-assign ke Gudang Mobil manapun. Silakan hubungi Admin Web untuk melengkapi data sebelum mengambil barang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
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
                      child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Form Tarik Barang',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sales.tarikGudangTujuan != null 
                                ? 'Menuju: ${sales.tarikGudangTujuan!['gudang_nama']}'
                                : 'Pindahkan produk dari gudang ke mobil',
                            style: const TextStyle(fontSize: 13, color: Colors.white70),
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
                        
                        _buildInputLabel('Gudang Asal', true),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _buildInputDecoration('Pilih Gudang Asal', Icons.warehouse_rounded),
                          initialValue: _selectedGudangAsal,
                          items: sales.tarikGudangAsalList.map((g) => DropdownMenuItem<String>(
                            value: g['gudang_code']?.toString(), 
                            child: Text(g['gudang_nama']?.toString() ?? '-', style: const TextStyle(fontSize: 14)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedGudangAsal = v),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        

                        
                        _buildInputLabel('Jenis Produk', true),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _buildInputDecoration('Pilih Produk', Icons.inventory_2_rounded),
                          initialValue: _selectedProduct,
                          items: sales.tarikProdukList.map((p) {
                            final name = p['sku_name']?.toString() ?? '-';
                            final isTelurItem = p['sku_category']?.toString().toLowerCase().contains('telur') ?? false;
                            
                            String stokText = '';
                            if (isTelurItem) {
                              final stokKas = p['stok_tersedia_kas']?.toString() ?? '0';
                              final konversiLabel = p['konversi_label']?.toString() ?? '';
                              stokText = 'Sisa: $stokKas Kas';
                              if (konversiLabel.isNotEmpty) stokText += ' ($konversiLabel)';
                            } else {
                              final stokKg = p['stok_tersedia_kg']?.toString() ?? p['stok_tersedia']?.toString() ?? '0';
                              final uom = p['sku_uom']?.toString() ?? 'Kg';
                              stokText = 'Sisa: $stokKg $uom';
                            }
                            
                            return DropdownMenuItem<String>(
                              value: p['sku_product']?.toString(), 
                              child: Text('$name ($stokText)', style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedProduct = v),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildInputLabel('Jumlah ditarik', true),
                        if (_selectedProduct != null && (sales.tarikProdukList.firstWhere((p) => p['sku_product'] == _selectedProduct, orElse: () => {})['sku_category']?.toString().toLowerCase().contains('telur') ?? false))
                          TextFormField(
                            decoration: _buildInputDecoration('0', Icons.inventory_2_rounded).copyWith(labelText: 'KAS'),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            onChanged: (v) => setState(() => _qtyKas = int.tryParse(v) ?? 0),
                          )
                        else
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
              onPressed: _selectedGudangAsal != null && _selectedProduct != null && !_isLoading 
                ? _submit 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
