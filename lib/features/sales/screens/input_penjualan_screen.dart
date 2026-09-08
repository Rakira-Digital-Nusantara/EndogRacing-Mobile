import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/sales_provider.dart';

class InputPenjualanScreen extends StatefulWidget {
  const InputPenjualanScreen({super.key});

  @override
  State<InputPenjualanScreen> createState() => _InputPenjualanScreenState();
}

class _InputPenjualanScreenState extends State<InputPenjualanScreen> {
  String? _selectedCustomerCode;
  String? _selectedProductSku;
  Map<String, dynamic>? _selectedProductMap;
  
  double _qty = 0;
  double _hargaJual = 0;
  
  String _paymentMethod = 'Tunai';
  final List<String> _paymentMethods = ['Tunai', 'Potong Deposit'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchPenjualanForm();
    });
  }

  void _onProductChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedProductSku = val;
      final provider = context.read<SalesProvider>();
      try {
        _selectedProductMap = provider.products.firstWhere((p) => p['sku'] == val);
        _hargaJual = (_selectedProductMap!['harga_jual_final'] as num?)?.toDouble() ?? (_selectedProductMap!['hpp'] as num).toDouble();
      } catch (_) {
        _selectedProductMap = null;
      }
    });
  }

  double get _subtotal => _qty * _hargaJual;
  bool get _isHargaTooLow => _selectedProductMap != null && _hargaJual > 0 && _hargaJual < (_selectedProductMap!['hpp'] as num).toDouble();
  
  bool get _canSubmit {
    if (_selectedCustomerCode == null || _selectedProductSku == null || _selectedProductMap == null) return false;
    if (_qty <= 0 || _hargaJual <= 0) return false;
    if (_isHargaTooLow) return false;
    return true;
  }

  Future<void> _submitForm() async {
    if (!_canSubmit) return;
    
    final payload = {
       'customer_code': _selectedCustomerCode,
       'gudang_code': 'GDG-002', // Menggunakan kode Gudang Mobil Sales
       'tanggal': DateTime.now().toString().split(' ')[0],
       'metode_bayar': _paymentMethod,
       'details_jual': [
           {
               'sku_product': _selectedProductSku,
               'qty': _qty,
               'harga_jual': _hargaJual,
           }
       ],
       'details_retur': [], 
    };
    
    final success = await context.read<SalesProvider>().submitPenjualan(payload);
    if (success && mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: const [
               Icon(Icons.check_circle_rounded, color: Colors.white),
               SizedBox(width: 8),
               Text('Penjualan berhasil dicatat!'),
             ],
           ),
           backgroundColor: Colors.green,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
         )
       );
       Navigator.pop(context);
    } else if (mounted) {
       final err = context.read<SalesProvider>().error;
       final cleanErr = err.replaceAll(RegExp(r'[\{\}\[\]]'), ''); 
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Row(
             children: [
               const Icon(Icons.error_outline_rounded, color: Colors.white),
               const SizedBox(width: 8),
               Expanded(child: Text(cleanErr)),
             ],
           ),
           backgroundColor: Colors.red,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: const Text('Tambah Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: sales.isLoading && sales.customers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SizedBox.expand(
              child: Stack(
                children: [
                  // Header Background Gradient
                Container(
                  width: double.infinity,
                  height: 140, // Added fixed height
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
                        child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catat Penjualan',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Catat transaksi penjualan harian Anda',
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
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Kustomer
                            _buildInputLabel('Kustomer Tujuan', true),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('Pilih Kustomer', Icons.person_outline_rounded),
                              value: _selectedCustomerCode,
                              items: sales.customers.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['code'],
                                  child: Text(c['name'], style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCustomerCode = val;
                                });
                              },
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),

                            // 2. Produk
                            _buildInputLabel('Produk (Jenis Telur)', true),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('Pilih Produk', Icons.egg_alt_rounded),
                              value: _selectedProductSku,
                              items: sales.products.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p['sku'],
                                  child: Text(p['name'], style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                              onChanged: _onProductChanged,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(height: 24),

                            // 3. Jumlah (Qty)
                            _buildInputLabel('Jumlah Terjual (Kg)', true),
                            TextFormField(
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              decoration: _buildInputDecoration('0.00', Icons.monitor_weight_rounded),
                              onChanged: (val) {
                                setState(() {
                                  _qty = double.tryParse(val) ?? 0;
                                });
                              },
                            ),
                            const SizedBox(height: 32),

                            // 4. Harga & Total (Highlighted Section)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Harga per Kg', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      Text(
                                        _hargaJual > 0 ? CurrencyFormatter.format(_hargaJual) : 'Rp 0',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                  if (_isHargaTooLow)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                          SizedBox(width: 4),
                                          Text('Di bawah HPP!', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Tagihan', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(
                                        CurrencyFormatter.format(_subtotal), 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 5. Metode Pembayaran
                            _buildInputLabel('Metode Pembayaran', true),
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('Pilih Pembayaran', Icons.payment_rounded),
                              value: _paymentMethod,
                              items: _paymentMethods.map((m) {
                                return DropdownMenuItem<String>(value: m, child: Text(m, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (val) {
                                 if (val != null) setState(() => _paymentMethod = val);
                              },
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pembayaran dicatat sebagai Tunai atau potong saldo deposit pelanggan.',
                                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                                    ),
                                  ),
                                ],
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
              onPressed: _canSubmit && !sales.isLoading ? _submitForm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: sales.isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Simpan Penjualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
